import AppKit
import NowThereCore
import SwiftUI

@MainActor
@main
struct NowThereApp: App {
    @NSApplicationDelegateAdaptor(NowThereAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class NowThereAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: NowThereStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let viewModel = ClockViewModel(loginItemManager: SystemLoginItemManager())
        statusBarController = NowThereStatusBarController(viewModel: viewModel)
    }
}

@MainActor
protocol MenuBarTitleDisplaying: AnyObject {
    var title: String { get set }
    var font: NSFont? { get set }
}

extension NSStatusBarButton: MenuBarTitleDisplaying {}

enum NowThereMenuBarLabel {
    @MainActor
    static func title(for viewModel: ClockViewModel) -> String {
        viewModel.menuTitle
    }

    @MainActor
    static func configure(_ display: MenuBarTitleDisplaying?, title: String) {
        guard let display else {
            return
        }

        display.title = title
        display.font = NSFont.menuBarFont(ofSize: 0)
    }
}
