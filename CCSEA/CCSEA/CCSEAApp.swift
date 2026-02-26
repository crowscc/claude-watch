import SwiftUI

@main
struct CCSEAApp: App {
    @StateObject private var viewModel = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(viewModel: viewModel)
        } label: {
            MenuBarLabel(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var viewModel: UsageViewModel

    var body: some View {
        HStack(spacing: 4) {
            if let usage = viewModel.usage {
                Image(nsImage: MenuBarIcon.render(utilization: usage.fiveHour.utilization))
                Text("\(Int(usage.fiveHour.utilization))%")
                    .monospacedDigit()
            } else {
                Image(systemName: "gauge.medium")
                Text("--")
            }
        }
        .onAppear {
            viewModel.startPolling()
        }
    }
}
