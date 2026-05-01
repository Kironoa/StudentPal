import WidgetKit
import SwiftUI

struct WidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let subtitle: String
    let deadlineTimestamp: TimeInterval
    let type: String
    let emptyMessage: String
}

struct WidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            title: "Math 101",
            subtitle: "Next Class",
            deadlineTimestamp: Date().addingTimeInterval(9000).timeIntervalSince1970,
            type: "next_class",
            emptyMessage: ""
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.example.mobile_app")
        let entry = buildEntry(from: defaults, date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.example.mobile_app")
        var entries: [WidgetEntry] = []
        let now = Date()

        let title = defaults?.string(forKey: "widget_title") ?? ""
        let subtitle = defaults?.string(forKey: "widget_subtitle") ?? ""
        let deadlineTimestamp = defaults?.double(forKey: "widget_deadline_timestamp") ?? 0
        let type = defaults?.string(forKey: "widget_type") ?? "empty"
        let emptyMessage = defaults?.string(forKey: "widget_empty_message") ?? "Stay Productive!"

        if type == "empty" || title.isEmpty {
            let entry = WidgetEntry(
                date: now,
                title: "",
                subtitle: "",
                deadlineTimestamp: 0,
                type: "empty",
                emptyMessage: emptyMessage.isEmpty ? "Stay Productive!" : emptyMessage
            )
            let nextReload = Calendar.current.date(byAdding: .minute, value: 5, to: now) ?? now
            entries.append(entry)
            let timeline = Timeline(entries: entries, policy: .after(nextReload))
            completion(timeline)
            return
        }

        for i in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: i, to: now) ?? now
            let entry = WidgetEntry(
                date: entryDate,
                title: title,
                subtitle: subtitle,
                deadlineTimestamp: deadlineTimestamp,
                type: type,
                emptyMessage: ""
            )
            entries.append(entry)
        }

        let lastDate = entries.last?.date ?? now
        let nextReload = Calendar.current.date(byAdding: .minute, value: 5, to: lastDate) ?? lastDate
        let timeline = Timeline(entries: entries, policy: .after(nextReload))
        completion(timeline)
    }

    private func buildEntry(from defaults: UserDefaults?, date: Date) -> WidgetEntry {
        let title = defaults?.string(forKey: "widget_title") ?? ""
        let subtitle = defaults?.string(forKey: "widget_subtitle") ?? ""
        let deadlineTimestamp = defaults?.double(forKey: "widget_deadline_timestamp") ?? 0
        let type = defaults?.string(forKey: "widget_type") ?? "empty"
        let emptyMessage = defaults?.string(forKey: "widget_empty_message") ?? "Stay Productive!"

        return WidgetEntry(
            date: date,
            title: title,
            subtitle: subtitle,
            deadlineTimestamp: deadlineTimestamp,
            type: type,
            emptyMessage: emptyMessage.isEmpty ? "Stay Productive!" : emptyMessage
        )
    }
}

struct StudentPalWidgetEntryView: View {
    var entry: WidgetProvider.Entry

    private var computedCountdown: String {
        if entry.deadlineTimestamp == 0 {
            return "00:00"
        }
        let deadline = Date(timeIntervalSince1970: entry.deadlineTimestamp)
        let remaining = max(0, deadline.timeIntervalSince(entry.date))
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1A1A"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )

            if entry.type == "empty" || entry.title.isEmpty {
                VStack(spacing: 0) {
                    Text(entry.emptyMessage.isEmpty ? "Stay Productive!" : entry.emptyMessage)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                VStack(spacing: 6) {
                    Text(entry.subtitle.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "00FF7F"))
                        .tracking(1)

                    Text(entry.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    Text(computedCountdown)
                        .font(.system(size: 32, weight: .bold, design: .default))
                        .foregroundColor(Color(hex: "00FF7F"))
                }
                .padding()
            }
        }
    }
}

struct StudentPalWidget: Widget {
    let kind: String = "StudentPalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WidgetProvider()) { entry in
            StudentPalWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Student Pal")
        .description("View your next class or assignment at a glance.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
