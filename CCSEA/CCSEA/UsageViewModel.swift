import Foundation
import SwiftUI

@MainActor
final class UsageViewModel: ObservableObject {

    enum State: Equatable {
        case idle
        case loading
        case loaded(UsageResponse)
        case error(String)

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading): return true
            case (.loaded(let a), .loaded(let b)):
                return a.fiveHour.utilization == b.fiveHour.utilization
                    && a.sevenDay.utilization == b.sevenDay.utilization
            case (.error(let a), .error(let b)): return a == b
            default: return false
            }
        }
    }

    @Published var state: State = .idle
    @Published var lastUpdated: Date?

    @AppStorage("refreshInterval") var refreshInterval: Double = 120

    private var timer: Timer?

    var usage: UsageResponse? {
        if case .loaded(let u) = state { return u }
        return nil
    }

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
            state = .loading
            do {
                let response = try await UsageService.fetch()
                state = .loaded(response)
                lastUpdated = Date()
            } catch {
                if usage == nil {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }
}
