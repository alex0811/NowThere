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

            Button(localized(.commandQuit)) {
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

            detailRow(label: localized(.detailsTimeZone), value: details.identifier)
            detailRow(label: localized(.detailsDate), value: details.fullDate)
            detailRow(label: localized(.detailsWeekday), value: details.fullWeekday)
            detailRow(label: localized(.detailsTime), value: details.time)
            detailRow(label: localized(.detailsUTCOffset), value: details.utcOffset)
        }
    }

    private var timeZoneSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localized(.searchTitle))
                .font(.headline)

            TextField(localized(.searchPlaceholder), text: $searchText)
                .textFieldStyle(.roundedBorder)

            let results: [TimeZoneSearchResult] = viewModel.searchResults(matching: searchText)

            if results.isEmpty {
                Text(localized(.searchEmpty))
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
            Text(localized(.settingsMenuBarFields))
                .font(.headline)

            HStack {
                Text(localized(.settingsCustomLabel))
                Spacer()
                TextField(
                    localized(.settingsCustomLabelPlaceholder),
                    text: Binding(
                        get: { viewModel.customLabel },
                        set: { viewModel.setCustomLabel($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .frame(width: 190)
            }

            Picker(localized(.settingsLanguage), selection: Binding(
                get: { viewModel.interfaceLanguage },
                set: { viewModel.setInterfaceLanguage($0) }
            )) {
                ForEach(InterfaceLanguage.allCases) { language in
                    Text(AppMenuLabels.interfaceLanguageName(language, language: viewModel.interfaceLanguage))
                        .tag(language)
                }
            }
            .pickerStyle(.menu)

            Picker(localized(.settingsTitleStyle), selection: Binding(
                get: { viewModel.titleStyle },
                set: { viewModel.setTitleStyle($0) }
            )) {
                ForEach(TitleStyle.allCases) { titleStyle in
                    Text(AppMenuLabels.titleStyleName(titleStyle, language: viewModel.interfaceLanguage))
                        .tag(titleStyle)
                }
            }
            .pickerStyle(.menu)

            Picker(localized(.settingsTimeFormat), selection: Binding(
                get: { viewModel.timeFormat },
                set: { viewModel.setTimeFormat($0) }
            )) {
                ForEach(TimeFormat.allCases) { timeFormat in
                    Text(AppMenuLabels.timeFormatName(timeFormat, language: viewModel.interfaceLanguage))
                        .tag(timeFormat)
                }
            }
            .pickerStyle(.menu)

            Toggle(AppMenuLabels.clockFieldName(.city, language: viewModel.interfaceLanguage), isOn: fieldBinding(.city))
            Toggle(AppMenuLabels.clockFieldName(.date, language: viewModel.interfaceLanguage), isOn: fieldBinding(.date))
            Toggle(AppMenuLabels.clockFieldName(.weekday, language: viewModel.interfaceLanguage), isOn: fieldBinding(.weekday))
            Toggle(AppMenuLabels.clockFieldName(.time, language: viewModel.interfaceLanguage), isOn: fieldBinding(.time))

            Divider()

            Toggle(localized(.settingsLaunchAtLogin), isOn: Binding(
                get: { viewModel.isLaunchAtLoginEnabled },
                set: { viewModel.setLaunchAtLogin($0) }
            ))

            if let error = viewModel.launchAtLoginError {
                Text(AppMenuLabels.launchAtLoginErrorMessage(error, language: viewModel.interfaceLanguage))
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

    private func localized(_ key: AppLocalizationKey) -> String {
        AppLocalization.string(key, language: viewModel.interfaceLanguage)
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
