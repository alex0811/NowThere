import AppKit
import XCTest
@testable import NowThere
@testable import NowThereCore

@MainActor
final class MenuBarTitleTests: XCTestCase {
    func testMenuBarLabelUsesVisibleClockTitleText() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Tokyo Jul 08 Wed 12:34")
    }

    func testMenuBarLabelIncludesCustomLabelFromViewModel() throws {
        let defaults = makeDefaults()
        let store = TimeZoneStore(defaults: defaults)
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        store.saveTimeZone(tokyo)
        store.saveCustomLabel("Work")

        let date = try Self.utcDate(year: 2026, month: 7, day: 8, hour: 3, minute: 34)
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { date },
            startsTimer: false
        )

        XCTAssertEqual(NowThereMenuBarLabel.title(for: viewModel), "Work Tokyo Jul 08 Wed 12:34")
    }

    func testMenuBarLabelConfiguresNativeStatusButtonAppearance() throws {
        let display = FakeMenuBarTitleDisplay()

        NowThereMenuBarLabel.configure(display, title: "Tokyo Jul 08 Wed 12:34")

        let expectedFont = NSFont.menuBarFont(ofSize: 0)
        let attributedTitle = display.attributedTitle
        let font = try XCTUnwrap(
            attributedTitle.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        )
        let color = try XCTUnwrap(
            attributedTitle.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor
        )
        let resolvedColor = try XCTUnwrap(color.usingColorSpace(.sRGB))

        XCTAssertEqual(attributedTitle.string, "Tokyo Jul 08 Wed 12:34")
        XCTAssertEqual(font.fontName, expectedFont.fontName)
        XCTAssertEqual(font.pointSize, expectedFont.pointSize)
        XCTAssertEqual(resolvedColor.redComponent, 1.0)
        XCTAssertEqual(resolvedColor.greenComponent, 1.0)
        XCTAssertEqual(resolvedColor.blueComponent, 1.0)
        XCTAssertEqual(resolvedColor.alphaComponent, 1.0)
    }

    func testStatusBarControllerActivatesAppWhenShowingPopover() throws {
        let defaults = makeDefaults()
        let tokyo = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let store = TimeZoneStore(defaults: defaults, fallbackTimeZone: { tokyo })
        let viewModel = ClockViewModel(
            store: store,
            loginItemManager: FakeLoginItemManager(isEnabled: false),
            nowProvider: { Date(timeIntervalSince1970: 0) },
            startsTimer: false
        )
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        defer {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        let popover = FakePopover()
        var activationCount = 0
        let controller = NowThereStatusBarController(
            viewModel: viewModel,
            statusItem: statusItem,
            popover: popover,
            activateApp: {
                activationCount += 1
            }
        )

        try XCTUnwrap(statusItem.button).performClick(nil)

        XCTAssertEqual(popover.showCount, 1)
        XCTAssertEqual(activationCount, 1)
        _ = controller
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "NowThereAppTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private static func utcDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let components = DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        )
        return try XCTUnwrap(calendar.date(from: components))
    }
}

private final class FakeLoginItemManager: LoginItemManaging {
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        isEnabled = enabled
    }
}

private final class FakeMenuBarTitleDisplay: MenuBarTitleDisplaying {
    var title = ""
    var font: NSFont?
    var attributedTitle = NSAttributedString()
}

private final class FakePopover: NSPopover {
    var showCount = 0

    override func show(
        relativeTo positioningRect: NSRect,
        of positioningView: NSView,
        preferredEdge: NSRectEdge
    ) {
        showCount += 1
    }
}
