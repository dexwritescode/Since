//
//  TrackerIconCatalog.swift
//  Since
//

import Foundation

struct SymbolCategory: Identifiable {
    let id: String
    let name: String
    let symbolNames: [String]
}

enum TrackerIconCatalog {
    /// The original curated pool from the SIN-5 picker POC, shown as the picker's first
    /// "Suggested" section. Intentionally unchanged so existing trackers' icons and the
    /// default icon for new trackers (`TrackerIcon.curated[0]`) keep behaving identically.
    static let suggested: [String] = TrackerIcon.curated

    static let categories: [SymbolCategory] = [
        SymbolCategory(id: "habits-recovery", name: "Habits & Recovery", symbolNames: [
            "flame.fill", "flame", "nosign", "checkmark.seal.fill", "checkmark.shield.fill",
            "shield.fill", "arrow.counterclockwise.circle.fill", "arrow.triangle.2.circlepath",
            "chart.line.uptrend.xyaxis", "trophy.fill", "medal.fill", "hand.raised.fill",
            "hand.thumbsup.fill", "heart.text.square.fill", "cross.case.fill", "bandage.fill",
            "pills.fill", "wineglass", "wineglass.fill", "cup.and.saucer.fill", "mug.fill",
            "exclamationmark.triangle.fill", "target", "calendar.badge.clock",
        ]),
        SymbolCategory(id: "health-body", name: "Health & Body", symbolNames: [
            "heart.fill", "heart.circle.fill", "cross.fill", "syringe.fill", "stethoscope",
            "thermometer", "thermometer.medium", "brain.head.profile", "waveform.path.ecg",
            "waveform.path.ecg.rectangle.fill", "ear.fill", "eye.fill",
            "figure.stand", "figure.arms.open", "drop.fill", "drop.circle.fill",
            "bed.double.fill", "allergens", "facemask.fill", "cross.vial.fill",
            "staroflife.fill", "heart.slash.fill", "lungs.fill",
        ]),
        SymbolCategory(id: "fitness-activity", name: "Fitness & Activity", symbolNames: [
            "figure.walk", "figure.run", "figure.hiking", "figure.yoga", "figure.cooldown",
            "figure.strengthtraining.traditional", "figure.strengthtraining.functional",
            "figure.pool.swim", "figure.outdoor.cycle", "figure.indoor.cycle", "figure.dance",
            "figure.mind.and.body", "figure.core.training", "figure.jumprope", "figure.stairs",
            "dumbbell.fill", "sportscourt.fill", "stopwatch.fill", "timer", "flame.circle.fill",
            "bicycle", "figure.climbing", "figure.boxing", "figure.walk.circle.fill",
        ]),
        SymbolCategory(id: "food-drink", name: "Food & Drink", symbolNames: [
            "fork.knife", "fork.knife.circle.fill", "cup.and.saucer.fill", "mug.fill",
            "wineglass.fill", "birthday.cake.fill", "carrot.fill", "leaf.fill",
            "takeoutbag.and.cup.and.straw.fill", "popcorn.fill", "frying.pan.fill",
            "refrigerator.fill", "waterbottle.fill", "cart.fill", "basket.fill", "fish.fill",
            "bag.fill", "storefront.fill", "oven.fill",
        ]),
        SymbolCategory(id: "nature-weather", name: "Nature & Weather", symbolNames: [
            "leaf.fill", "tree.fill", "moon.fill", "moon.stars.fill", "sun.max.fill",
            "sun.min.fill", "cloud.fill", "cloud.rain.fill", "cloud.bolt.fill",
            "cloud.snow.fill", "cloud.fog.fill", "wind", "snowflake", "drop.fill",
            "mountain.2.fill", "water.waves", "sparkles", "rainbow", "tornado", "hurricane",
            "thermometer.sun.fill", "sunrise.fill", "sunset.fill", "globe.americas.fill",
        ]),
        SymbolCategory(id: "time-calendar", name: "Time & Calendar", symbolNames: [
            "clock.fill", "clock", "alarm.fill", "calendar", "calendar.circle.fill",
            "calendar.badge.clock", "calendar.badge.plus", "hourglass", "stopwatch.fill",
            "timer", "deskclock.fill", "clock.arrow.circlepath", "clock.badge.checkmark.fill",
            "sunrise.fill", "sunset.fill", "bell.fill", "bell.badge.fill",
            "calendar.day.timeline.left",
        ]),
        SymbolCategory(id: "mind-learning", name: "Mind & Learning", symbolNames: [
            "book.fill", "book.closed.fill", "books.vertical.fill", "graduationcap.fill",
            "brain.head.profile", "brain.fill", "pencil", "pencil.circle.fill", "highlighter",
            "newspaper.fill", "doc.text.fill", "doc.richtext.fill", "lightbulb.fill",
            "lightbulb.circle.fill", "puzzlepiece.fill", "quote.bubble.fill", "bookmark.fill",
            "questionmark.circle.fill", "checkmark.circle.fill",
        ]),
        SymbolCategory(id: "home-objects", name: "Home & Objects", symbolNames: [
            "house.fill", "house.circle.fill", "bed.double.fill", "sofa.fill",
            "lamp.desk.fill", "key.fill", "washer.fill", "refrigerator.fill", "oven.fill",
            "shower.fill", "bathtub.fill", "toilet.fill", "trash.fill", "paintbrush.fill",
            "hammer.fill", "wrench.fill", "screwdriver.fill", "scissors", "paperclip",
            "folder.fill", "archivebox.fill", "tray.fill", "shippingbox.fill",
        ]),
        SymbolCategory(id: "money-work", name: "Money & Work", symbolNames: [
            "dollarsign.circle.fill", "dollarsign.square.fill", "banknote.fill",
            "creditcard.fill", "wallet.pass.fill", "briefcase.fill", "chart.bar.fill",
            "chart.pie.fill", "chart.line.uptrend.xyaxis", "building.2.fill",
            "building.columns.fill", "cart.fill", "bag.fill", "gift.fill", "tag.fill",
            "banknote", "percent", "scalemass.fill", "chart.xyaxis.line",
            "briefcase.circle.fill",
        ]),
        SymbolCategory(id: "communication-social", name: "Communication & Social", symbolNames: [
            "phone.fill", "phone.circle.fill", "message.fill", "bubble.left.fill",
            "bubble.left.and.bubble.right.fill", "envelope.fill", "paperplane.fill",
            "person.fill", "person.2.fill", "person.3.fill", "person.crop.circle.fill",
            "megaphone.fill", "mic.fill", "video.fill", "quote.bubble.fill", "hand.wave.fill",
            "person.wave.2.fill", "heart.circle.fill", "gift.fill",
        ]),
        SymbolCategory(id: "travel-places", name: "Travel & Places", symbolNames: [
            "airplane", "car.fill", "bus.fill", "tram.fill", "bicycle", "map.fill",
            "mappin.and.ellipse", "mappin.circle.fill", "globe", "globe.americas.fill",
            "suitcase.fill", "suitcase.rolling.fill", "ferry.fill", "sailboat.fill",
            "fuelpump.fill", "road.lanes", "signpost.right.fill", "tent.fill",
            "beach.umbrella.fill", "building.2.fill", "flag.checkered",
        ]),
        SymbolCategory(id: "tech-devices", name: "Tech & Devices", symbolNames: [
            "iphone", "ipad", "laptopcomputer", "desktopcomputer", "applewatch", "headphones",
            "airpodspro", "tv.fill", "gamecontroller.fill", "keyboard.fill", "printer.fill",
            "wifi", "antenna.radiowaves.left.and.right", "battery.100", "bolt.fill", "power",
            "camera.fill", "speaker.wave.2.fill", "network", "cpu",
        ]),
        SymbolCategory(id: "symbols-shapes", name: "Symbols & Shapes", symbolNames: [
            "star.fill", "star.circle.fill", "heart.fill", "checkmark.circle.fill",
            "checkmark.seal.fill", "xmark.circle.fill", "exclamationmark.circle.fill",
            "questionmark.circle.fill", "plus.circle.fill", "minus.circle.fill", "circle.fill",
            "square.fill", "triangle.fill", "diamond.fill", "hexagon.fill", "seal.fill",
            "shield.fill", "flag.fill", "bookmark.fill", "pin.fill", "target", "sparkles",
        ]),
        SymbolCategory(id: "gestures-emotions", name: "Gestures & Emotions", symbolNames: [
            "face.smiling.fill", "face.smiling", "face.dashed.fill", "hand.thumbsup.fill",
            "hand.thumbsdown.fill", "hand.raised.fill", "hands.clap.fill", "hand.wave.fill",
            "moon.zzz.fill", "person.fill.checkmark", "person.fill.questionmark",
            "hand.point.up.fill", "hand.point.right.fill", "hand.thumbsup.circle.fill",
        ]),
        SymbolCategory(id: "sports-games", name: "Sports & Games", symbolNames: [
            "gamecontroller.fill", "sportscourt.fill", "basketball.fill", "football.fill",
            "soccerball", "tennis.racket", "baseball.fill", "volleyball.fill", "figure.golf",
            "trophy.fill", "medal.fill", "flag.checkered", "dice.fill", "puzzlepiece.fill",
            "sportscourt", "hockey.puck.fill", "cricket.ball.fill", "skateboard.fill",
        ]),
        SymbolCategory(id: "misc", name: "Misc & Other", symbolNames: [
            "gearshape.fill", "gearshape.2.fill", "slider.horizontal.3", "list.bullet",
            "list.bullet.clipboard.fill", "checklist", "tray.full.fill", "link",
            "location.fill", "compass.drawing", "magnifyingglass",
        ]),
    ]

    /// Substring match against a symbol's own name or its category's display name,
    /// case-insensitive. Results preserve catalog order and are deduplicated (a symbol
    /// can only appear once even though the same name may exist in more than one category).
    static func search(_ query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return [] }

        var seen = Set<String>()
        var results: [String] = []

        for category in categories {
            let categoryMatches = category.name.lowercased().contains(trimmed)
            for name in category.symbolNames where categoryMatches || name.lowercased().contains(trimmed) {
                if seen.insert(name).inserted {
                    results.append(name)
                }
            }
        }

        return results
    }
}
