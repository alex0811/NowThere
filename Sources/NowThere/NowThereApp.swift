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
            Text(NowThereMenuBarLabel.title(for: viewModel))
        }
        .menuBarExtraStyle(.window)
    }
}

enum NowThereMenuBarLabel {
    @MainActor
    static func title(for viewModel: ClockViewModel) -> String {
        viewModel.menuTitle
    }
}
