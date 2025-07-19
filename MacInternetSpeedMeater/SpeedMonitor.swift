import Foundation
import Combine

class SpeedMonitor: ObservableObject {
    @Published var downloadSpeed: Double = 0.0
    @Published var uploadSpeed: Double = 0.0
    @Published var ping: Int = -1

    private var timer: Timer?
    private var previousData: (received: UInt64, sent: UInt64)?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
            self?.pingHost()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateSpeed() {
        let stats = getNetworkBytes()

        guard let previous = previousData else {
            previousData = stats
            return
        }

        let downloadDiff = Double(stats.received - previous.received) / 1024.0
        let uploadDiff = Double(stats.sent - previous.sent) / 1024.0

        DispatchQueue.main.async {
            self.downloadSpeed = max(downloadDiff, 0)
            self.uploadSpeed = max(uploadDiff, 0)
        }

        previousData = stats
    }

    private func getNetworkBytes() -> (received: UInt64, sent: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var sent: UInt64 = 0
        var received: UInt64 = 0

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                if let interface = ptr?.pointee {
                    let name = String(cString: interface.ifa_name)
                    if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                        if let data = interface.ifa_data?.assumingMemoryBound(to: if_data.self).pointee {
                            sent += UInt64(data.ifi_obytes)
                            received += UInt64(data.ifi_ibytes)
                        }
                    }
                }
                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }

        return (received, sent)
    }

    private func pingHost(host: String = "8.8.8.8") {
        DispatchQueue.global(qos: .background).async {
            let process = Process()
            process.launchPath = "/sbin/ping"
            process.arguments = ["-c", "1", "-W", "1000", host]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            process.launch()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let pattern = #"time=(\d+\.?\d*) ms"#
                if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                    let range = NSRange(location: 0, length: output.utf16.count)
                    if let match = regex.firstMatch(in: output, options: [], range: range),
                       let timeRange = Range(match.range(at: 1), in: output) {
                        let timeStr = String(output[timeRange])
                        if let time = Double(timeStr) {
                            DispatchQueue.main.async {
                                self.ping = Int(time)
                            }
                            return
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                self.ping = -1
            }
        }
    }
}
