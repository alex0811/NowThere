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

            Button(AppLocalization.string(.commandQuit)) {
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

            detailRow(label: AppLocalization.string(.detailsTimeZone), value: details.identifier)
            detailRow(label: AppLocalization.string(.detailsDate), value: details.fullDate)
            detailRow(label: AppLocalization.string(.detailsWeekday), value: details.fullWeekday)
            detailRow(label: AppLocalization.string(.detailsTime), value: details.time)
            detailRow(label: AppLocalization.string(.detailsUTCOffset), value: details.utcOffset)
        }
    }

    private var timeZoneSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLocalization.string(.searchTitle))
                .font(.headline)

            TextField(AppLocalization.string(.searchPlaceholder), text: $searchText)
                .textFieldStyle(.roundedBorder)

            let results: [TimeZoneSearchResult] = viewModel.searchResults(matching: searchText)

            if results.isEmpty {
                Text(AppLocalization.string(.searchEmpty))
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
            Text(AppLocalization.string(.settingsMenuBarFields))
                .font(.headline)

            HStack {
                Text(AppLocalization.string(.settingsCustomLabel))
                Spacer()
                TextField(
                    AppLocalization.string(.settingsCustomLabelPlaceholder),
                    text: Binding(
                        get: { viewModel.customLabel },
                        set: { viewModel.setCustomLabel($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 190)
            }

            Picker(AppLocalization.string(.settingsTitleStyle), selection: Binding(
                get: { viewModel.titleStyle },
                set: { viewModel.setTitleStyle($0) }
            )) {
                ForEach(TitleStyle.allCases) { titleStyle in
                    Text(AppMenuLabels.titleStyleName(titleStyle))
                        .tag(titleStyle)
                }
            }
            .pickerStyle(.menu)

            Picker(AppLocalization.string(.settingsTimeFormat), selection: Binding(
                get: { viewModel.timeFormat },
                set: { viewModel.setTimeFormat($0) }
            )) {
                ForEach(TimeFormat.allCases) { timeFormat in
                    Text(AppMenuLabels.timeFormatName(timeFormat))
                        .tag(timeFormat)
                }
            }
            .pickerStyle(.menu)

            Toggle(AppMenuLabels.clockFieldName(.city), isOn: fieldBinding(.city))
            Toggle(AppMenuLabels.clockFieldName(.date), isOn: fieldBinding(.date))
            Toggle(AppMenuLabels.clockFieldName(.weekday), isOn: fieldBinding(.weekday))
            Toggle(AppMenuLabels.clockFieldName(.time), isOn: fieldBinding(.time))

            Divider()

            Toggle(AppLocalization.string(.settingsLaunchAtLogin), isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))

            if let error = viewModel.launchAtLoginError {
                Text(AppMenuLabels.launchAtLoginErrorMessage(error))
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
