import NowThereCore
import SwiftUI

@MainActor
@main
struct NowThereApp: App {
    @StateObject private var viewModel: ClockViewModel

    init() {
        _viewModel = StateObject(
            wrappedValue: ClockViewModel(loginItemManager: SystemLoginItemManager())
        )
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContentView(viewModel: viewModel)
        } label: {
            Label {
                Text(viewModel.menuTitle)
            } icon: {
                Image(systemName: "clock")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
