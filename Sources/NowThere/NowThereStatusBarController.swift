import AppKit
import Combine
import NowThereCore
import SwiftUI

@MainActor
final class NowThereStatusBarController: NSObject {
    private let viewModel: ClockViewModel
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var viewModelCancellable: AnyCancellable?

    init(
        viewModel: ClockViewModel,
        statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength),
        popover: NSPopover = NSPopover()
    ) {
        self.viewModel = viewModel
        self.statusItem = statusItem
        self.popover = popover
        super.init()

        configureStatusItem()
        configurePopover()
        observeViewModel()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else {
            return
        }

        NowThereMenuBarLabel.configure(button, title: viewModel.menuTitle)
        button.target = self
        button.action = #selector(togglePopover(_:))
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarContentView(viewModel: viewModel)
        )
    }

    private func observeViewModel() {
        viewModelCancellable = viewModel.objectWillChange.sink { [weak self, weak viewModel] _ in
            Task { @MainActor [weak self, weak viewModel] in
                guard let self, let viewModel else {
                    return
                }

                self.updateTitle(viewModel.menuTitle)
            }
        }
    }

    private func updateTitle(_ title: String) {
        NowThereMenuBarLabel.configure(statusItem.button, title: title)
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
            return
        }

        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
    }
}
