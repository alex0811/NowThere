# Custom Label Design

## Goal

Add an optional custom label that appears before the city in the NowThere menu bar title. The label helps users distinguish the purpose of the selected time zone, such as `Work Tokyo Jul 08 Wed 12:34`.

## Requirements

- Users can enter a free-form custom label from the menu bar settings panel.
- The custom label is persisted between app launches.
- Empty or whitespace-only labels are hidden.
- When present, the label is rendered before the city.
- Clearing the text field removes the label from the menu bar title.
- Existing city, date, weekday, and time visibility toggles continue to work.
- If all existing fields are hidden but the custom label is present, the menu bar title shows the label.
- If all fields are hidden and the custom label is empty, the menu bar title remains `NowThere`.

## User Interface

Add a `Custom Label` text field to the existing settings section. It should use a short placeholder such as `Work, Home, Client`.

The label has no separate visibility toggle. A non-empty value is shown; an empty value is hidden.

## Architecture

- `TimeZoneStore` gains a persisted `customLabel` string backed by `UserDefaults`.
- `ClockViewModel` owns the current label, exposes it as published state, and provides a setter that persists and refreshes the title.
- `ClockFormatter.title` accepts the label as input, trims whitespace, and inserts the non-empty label before the city part.
- `FieldVisibility` remains focused on the existing four clock fields and does not gain a label flag.

## Data Flow

1. On launch, `ClockViewModel` loads the selected time zone, field visibility, and custom label from `TimeZoneStore`.
2. The menu title is generated from the current date, selected time zone, visibility settings, and custom label.
3. When the user edits the text field, `ClockViewModel` saves the label and refreshes the menu title.
4. On the next launch, the saved label is loaded and included in the title if non-empty.

## Error Handling

The label is local app preference data. Invalid input is handled by trimming whitespace for display. No error message is needed for normal text entry.

## Testing

- Formatter shows custom label before city.
- Formatter hides empty and whitespace-only labels.
- Formatter shows only the custom label when other fields are hidden.
- Formatter falls back to `NowThere` when label is empty and all fields are hidden.
- Store saves and loads the custom label.
- View model loads the label, updates it, persists it, and refreshes the title.
- App-level menu bar label continues to read from the view model title.
