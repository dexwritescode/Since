#!/usr/bin/swift
// Renders candidate app icons (SF Symbol glyph on solid/gradient color) as 1024x1024 PNGs,
// plus a labeled contact sheet for side-by-side comparison. Deterministic: same specs in,
// same PNGs out. Edit `palette` / `symbols` / `styles` below and rerun to iterate.
//
// Usage: swift Scripts/generate-app-icon.swift
// Output: Scripts/output/*.png (gitignored)

import AppKit
import SwiftUI

// MARK: - Candidate space

let palette: [(name: String, hex: String)] = [
    ("blue", "4F8EF7"),
    ("purple", "8B5CF6"),
]

let symbols = [
    "hourglass", "clock.fill", "timer",
    "calendar", "flame.fill", "chart.line.uptrend.xyaxis", "flag.checkered",
]

enum Style: String, CaseIterable {
    case solid
    case gradientDark = "gradient-dark"
    case gradientLight = "gradient-light"
}

struct IconSpec {
    let colorName: String
    let hex: String
    let symbol: String
    let style: Style

    var slug: String {
        "\(colorName)-\(symbol.replacingOccurrences(of: ".", with: "-"))-\(style.rawValue)"
    }
}

let specs: [IconSpec] = palette.flatMap { color in
    symbols.flatMap { symbol in
        Style.allCases.map { style in
            IconSpec(colorName: color.name, hex: color.hex, symbol: symbol, style: style)
        }
    }
}

// MARK: - Color helpers

func color(hex: String) -> Color {
    var value: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&value)
    let r = Double((value & 0xFF0000) >> 16) / 255
    let g = Double((value & 0x00FF00) >> 8) / 255
    let b = Double(value & 0x0000FF) / 255
    return Color(red: r, green: g, blue: b)
}

// Darkens a hex color by a fixed fraction (mixes toward black), for a gradient stop.
func darkened(hex: String, by fraction: Double) -> Color {
    var value: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&value)
    let r = Double((value & 0xFF0000) >> 16) / 255 * (1 - fraction)
    let g = Double((value & 0x00FF00) >> 8) / 255 * (1 - fraction)
    let b = Double(value & 0x0000FF) / 255 * (1 - fraction)
    return Color(red: r, green: g, blue: b)
}

// Lightens a hex color by a fixed fraction (mixes toward white), for a gradient stop.
func lightened(hex: String, by fraction: Double) -> Color {
    var value: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&value)
    let r = Double((value & 0xFF0000) >> 16) / 255 * (1 - fraction) + fraction
    let g = Double((value & 0x00FF00) >> 8) / 255 * (1 - fraction) + fraction
    let b = Double(value & 0x0000FF) / 255 * (1 - fraction) + fraction
    return Color(red: r, green: g, blue: b)
}

// MARK: - Icon view

struct IconView: View {
    let spec: IconSpec

    var body: some View {
        ZStack {
            background
            Image(systemName: spec.symbol)
                .font(.system(size: 520, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 1024, height: 1024)
    }

    @ViewBuilder
    private var background: some View {
        switch spec.style {
        case .solid:
            color(hex: spec.hex)
        case .gradientDark:
            LinearGradient(
                colors: [color(hex: spec.hex), darkened(hex: spec.hex, by: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .gradientLight:
            LinearGradient(
                colors: [color(hex: spec.hex), lightened(hex: spec.hex, by: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Rendering

@MainActor
func renderPNG<V: View>(_ view: V, size: CGFloat) -> NSImage {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(width: size, height: size)
    guard let image = renderer.nsImage else {
        fatalError("Failed to render view")
    }
    return image
}

func pngData(for image: NSImage) -> Data {
    guard
        let tiff = image.tiffRepresentation,
        let rep = NSBitmapImageRep(data: tiff),
        let png = rep.representation(using: .png, properties: [:])
    else {
        fatalError("Failed to encode PNG")
    }
    return png
}

// MARK: - Contact sheet

func buildContactSheet(specs: [IconSpec], thumbnails: [NSImage]) -> NSImage {
    let columns = 6
    let rows = Int(ceil(Double(specs.count) / Double(columns)))
    let cellSize: CGFloat = 200
    let labelHeight: CGFloat = 36
    let cellHeight = cellSize + labelHeight
    let sheetSize = NSSize(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellHeight)

    let sheet = NSImage(size: sheetSize)
    sheet.lockFocus()
    NSColor.white.setFill()
    NSRect(origin: .zero, size: sheetSize).fill()

    let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 8),
        .foregroundColor: NSColor.black,
    ]

    for (index, spec) in specs.enumerated() {
        let col = index % columns
        let row = index / columns
        let x = CGFloat(col) * cellSize
        let yFromTop = CGFloat(row) * cellHeight
        let y = sheetSize.height - yFromTop - cellSize

        thumbnails[index].draw(in: NSRect(x: x, y: y, width: cellSize, height: cellSize))

        let label = spec.slug as NSString
        let labelSize = label.size(withAttributes: labelAttributes)
        let labelRect = NSRect(
            x: x + (cellSize - labelSize.width) / 2,
            y: y - labelHeight + (labelHeight - labelSize.height) / 2,
            width: labelSize.width,
            height: labelSize.height
        )
        label.draw(in: labelRect, withAttributes: labelAttributes)
    }

    sheet.unlockFocus()
    return sheet
}

// MARK: - Main

@MainActor
func generateIcons() {
    let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
    let outputDir = scriptDir.appendingPathComponent("output")
    try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

    var thumbnails: [NSImage] = []

    for spec in specs {
        let fullImage = renderPNG(IconView(spec: spec), size: 1024)
        let fileURL = outputDir.appendingPathComponent("\(spec.slug).png")
        try? pngData(for: fullImage).write(to: fileURL)

        let thumb = renderPNG(IconView(spec: spec), size: 200)
        thumbnails.append(thumb)

        print("Rendered \(spec.slug).png")
    }

    let contactSheet = buildContactSheet(specs: specs, thumbnails: thumbnails)
    let contactSheetURL = outputDir.appendingPathComponent("contact-sheet.png")
    try? pngData(for: contactSheet).write(to: contactSheetURL)
    print("Rendered contact-sheet.png")
    print("\nOutput: \(outputDir.path)")
}

MainActor.assumeIsolated {
    generateIcons()
}
