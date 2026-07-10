//
//  HeroCardView.swift
//  Since
//

import SwiftUI

struct HeroCardView: View {
    let tracker: Tracker

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
    }

    private func content(now: Date) -> some View {
        let tint = Color(hex: tracker.colorHex)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: tracker.icon)
                    .font(.headline)
                    .foregroundStyle(tint)
                Text(tracker.name)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Spacer()
            }

            if let elapsed = tracker.elapsedTimeString(asOf: now) {
                Text(elapsed)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
            }

            if let start = tracker.currentStreakStartDate {
                Text("Started \(start.formatted(date: .abbreviated, time: .omitted))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let milestone = tracker.nextMilestone(asOf: now),
               let remaining = milestone.remainingTimeString(from: tracker, asOf: now) {
                Text("Next: \(milestone.label) — \(remaining) left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#Preview {
    let tracker = Tracker(name: "Smoking", icon: "flame.fill", colorHex: "#FF6B35")
    tracker.streakPeriods.append(StreakPeriod(startDate: .now.addingTimeInterval(-86400 * 3)))
    tracker.milestones.append(Milestone(label: "One Week", triggerDuration: 7 * 86400))

    return HeroCardView(tracker: tracker)
        .padding()
}
