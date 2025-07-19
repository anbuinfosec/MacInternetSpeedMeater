import SwiftUI

struct ContentView: View {
    @ObservedObject var monitor: SpeedMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                StatRow(label: "Upload ⬆︎", value: formatSpeed(speedInKBps: monitor.uploadSpeed))
                StatRow(label: "Download ⬇︎", value: formatSpeed(speedInKBps: monitor.downloadSpeed))
                StatRow(label: "Ping 🏓", value: monitor.ping >= 0 ? "\(monitor.ping) ms" : "-- ms")
            }
            .padding(.bottom, 10)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Developer")
                    .font(.headline)
                Text("Name: Mohammad Alamin")
                Text("GitHub: anbinfosec")

                Divider()

                Text("Tool Details")
                    .font(.headline)
                Text("Version: 1.0")
                Text("Language: Swift, SwiftUI")
                Text("Uses: NWPathMonitor, getifaddrs, ping")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.top, 6)
        }
        .padding()
        .frame(width: 300)
    }

    func formatSpeed(speedInKBps: Double) -> String {
        if speedInKBps < 1024 {
            return String(format: "%.0f KB/s", speedInKBps)
        } else {
            return String(format: "%.2f MB/s", speedInKBps / 1024)
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundColor(.secondary)
        }
    }
}
