# LifeOS

LifeOS is a privacy-first personal AI daily operating system MVP for iOS. It combines mocked health, focus, calendar, device, and job-search signals into a simple daily command center that helps a user decide what to do today.

The first version is intentionally local-first and rule-based. It does not require HealthKit, EventKit, DeviceActivity, a backend, or paid AI APIs.

## MVP Features

- Daily dashboard with today's date, energy score, focus risk, top priorities, suggested schedule blocks, warnings, and recommendations.
- Mock health data module with sleep, steps, workout completion, and resting heart rate.
- Mock focus data module with screen time, distracting app usage, and late-night usage.
- Mock calendar module with realistic events for interview prep, Java OOP review, deadlines, and workout reminders.
- SwiftData-backed local job-search CRM with company, role, status, deadline, and next action.
- Add, edit, and delete job applications locally.
- Rule-based daily planner that generates priorities, schedule suggestions, warnings, and recommendations.
- SwiftUI tabs for Dashboard, Focus Coach, Energy Insights, Job Search, and Settings.
- Command-center dashboard with energy ring, focus badge, Now/Next section, and daily timeline.
- Editable mock health and focus inputs for demoing different day scenarios.
- Privacy settings explaining local-first storage and future integration boundaries.
- XCTest coverage for core planner rules.

## Seed Data

The app includes starter data for:

- Capgemini Java Developer interview prep
- Truist Java Software Engineer application
- EIMS Tech Sales application
- Garmin Software Engineer application
- Java OOP review task
- Walk/workout reminder

## How To Run

1. Open `LifeOS.xcodeproj` in Xcode.
2. Select an iPhone simulator.
3. Build and run.
4. Use Product > Test to run `DailyPlannerEngineTests`.

Recommended target: iOS 17 or later.

## Architecture

The project uses a small MVVM layout:

- `Models/`: Codable data structs, simple enums, and SwiftData records.
- `Managers/`: Mock data providers and local job application storage.
- `Services/`: `DailyPlannerEngine`, the rule-based planning logic.
- `ViewModels/`: Dashboard state and refresh logic.
- `Views/`: SwiftUI screens and tab navigation.
- `LifeOSTests/`: Unit tests for the planner engine.

## Demo Controls

Use Settings > Edit today's mock inputs to try different scenarios:

- Low sleep and low steps
- High screen time
- Late-night usage
- Workout completed
- Healthy recovery day

Saving mock inputs recalculates the dashboard immediately.

## Planning Logic

`DailyPlannerEngine` combines health data, focus data, calendar events, and job applications. Current rules include:

- Sleep below 6 hours triggers lighter deep-work guidance.
- Interview events become top priorities.
- Job deadlines within 2 days are promoted into priorities.
- Late-night usage increases focus risk and creates a warning.
- Steps below 4,000 generate a walk recommendation.
- Missing workout data generates a simple movement suggestion.

## Privacy-First Design

LifeOS is designed to keep the MVP useful without centralizing personal data:

- Job applications are stored locally with SwiftData.
- Health, focus, and calendar inputs are mocked until the user connects real sources.
- Future integrations should ask for permission before reading HealthKit, EventKit, or DeviceActivity data.
- Sensitive memory should require explicit approval before saving.
- AI APIs should be optional and explain what leaves the device.

## Future Integrations

- HealthKit for sleep, steps, workouts, and heart-rate trends.
- EventKit for real calendar events.
- DeviceActivity and Screen Time APIs for focus signals.
- UserNotifications for focus blocks, walks, interviews, and deadlines.
- CloudKit for optional Apple-native sync.
- Supabase or another backend only if sync becomes necessary.
- OpenAI or Claude APIs for richer planning, with clear user consent.
