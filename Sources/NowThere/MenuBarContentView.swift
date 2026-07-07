import AppKit
import NowThereCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var viewModel: ClockViewModel
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            detailsSection

            Divider()

            timeZoneSearchSection

            Divider()

            settingsSection

            Divider()

            Button("Quit NowThere") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(14)
        .frame(width: 340)
    }

    private var detailsSection: some View {
        let details = viewModel.details

        return VStack(alignment: .leading, spacing: 6) {
            Text(details.label)
                .font(.headline)

            detailRow(label: "Time Zone", value: details.identifier)
            detailRow(label: "Date", value: details.fullDate)
            detailRow(label: "Weekday", value: details.fullWeekday)
            detailRow(label: "Time", value: details.time)
            detailRow(label: "UTC Offset", value: details.utcOffset)
        }
    }

    private var timeZoneSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Zone")
                .font(.headline)

            TextField("Search city or time zone", text: $searchText)
                .textFieldStyle(.roundedBorder)

            let results: [TimeZoneSearchResult] = viewModel.searchResults(matching: searchText)

            if results.isEmpty {
                Text("No matching time zones")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(results, id: \TimeZoneSearchResult.identifier) { (result: TimeZoneSearchResult) in
                            Button {
                                viewModel.selectTimeZone(identifier: result.identifier)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.label)
                                            .font(.body)
                                        Text(result.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if result.identifier == viewModel.selectedTimeZone.identifier {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
        }
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Menu Bar Fields")
                .font(.headline)

            Toggle("City/Label", isOn: fieldBinding(.city))
            Toggle("Date", isOn: fieldBinding(.date))
            Toggle("Weekday", isOn: fieldBinding(.weekday))
            Toggle("Time", isOn: fieldBinding(.time))

            Divider()

            Toggle("Launch at Login", isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))

            if let message = viewModel.launchAtLoginErrorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func fieldBinding(_ field: ClockField) -> Binding<Bool> {
        Binding(
            get: {
                switch field {
                case .city:
                    viewModel.visibility.showsCity
                case .date:
                    viewModel.visibility.showsDate
                case .weekday:
                    viewModel.visibility.showsWeekday
                case .time:
                    viewModel.visibility.showsTime
                }
            },
            set: { isVisible in
                viewModel.setField(field, isVisible: isVisible)
            }
        )
    }
}
