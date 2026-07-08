import NowThereCore
import AppKit
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
            NowThereMenuBarLabel.view(for: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

enum NowThereMenuBarLabel {
    @MainActor
    static func title(for viewModel: ClockViewModel) -> String {
        viewModel.menuTitle
    }

    @MainActor
    static func view(for viewModel: ClockViewModel) -> some View {
        Text(title(for: viewModel))
            .font(.system(size: NSFont.systemFontSize(for: .regular), weight: .regular))
            .foregroundStyle(.primary)
    }
}
