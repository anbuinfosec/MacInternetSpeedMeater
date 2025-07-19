import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: 15) {
            Button("Open Login Items Preferences") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                    NSWorkspace.shared.open(url)
                }
            }
            Text("Add this app to your login items manually to launch at startup.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(width: 350, height: 100)
        .padding()
    }
}
