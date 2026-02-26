import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    @Published var state: State = .idle
    @Published var usage: UsageResponse?
    @Published var lastUpdated: Date?

    @AppStorage("refreshInterval") var refreshInterval: Double = 120

    private var timer: Timer?

    var isTokenExpired: Bool {
        if case .error(let msg) = state { return msg.contains("token") || msg.contains("登录") }
        return false
    }

    func startPolling() {
        fetch()
        scheduleTimer()
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func scheduleTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fetch()
            }
        }
    }

    func fetch() {
        Task {
            // 不清空 usage，保留缓存
            state = .loading
            do {
                let response = try await UsageService.fetch()
                usage = response
                state = .loaded
                lastUpdated = Date()
            } catch {
                // 有缓存时保持显示，无缓存才显示错误
                if usage == nil {
                    state = .error(error.localizedDescription)
                } else {
                    state = .loaded
                }
            }
        }
    }
}
