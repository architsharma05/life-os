# LifeOS TODO

## Phase 1: MVP Polish

- Add more unit tests for edge cases in `DailyPlannerEngine`.
- Add editable calendar mock data for demos.
- Improve empty states after users remove all job applications.
- Add preview data for SwiftUI previews.
- Add lightweight visual polish after running on a simulator.

## Phase 2: Production UI

- Add onboarding with local-first privacy explanation.
- Add permission primer screens for Health, Calendar, Focus, and Notifications.
- Add polished empty states for Dashboard, Jobs, and Settings.
- Add better dark mode tuning.
- Add simple animation to the energy ring and schedule timeline.
- Add accessibility labels for score cards and schedule blocks.

## Phase 3: Apple Integrations

- Replace `MockHealthDataManager` with HealthKit behind a permission screen.
- Replace `MockCalendarManager` with EventKit.
- Add DeviceActivity or Screen Time support for focus risk.
- Add notification reminders for schedule blocks and job deadlines.

## Phase 4: Better Planning

- Add weekly trends for sleep, workouts, and focus.
- Add a user-configurable priority system.
- Add interview prep templates.
- Add calendar conflict detection.
- Add a daily review flow.

## Phase 5: Optional AI

- Add an AI planning service only after consent.
- Keep rule-based logic as a fallback.
- Show users what context is sent to the AI provider.
- Require approval before saving sensitive memory.

## Phase 6: Sync

- Evaluate whether sync is needed after local-first usage feels solid.
- Prefer CloudKit for private Apple-native sync.
- Use Supabase only if web, cross-platform, or server workflows become necessary.
- Keep offline/local-first behavior working.

## Phase 7: App Store Readiness

- Write privacy policy.
- Fill App Store privacy labels accurately.
- Add TestFlight metadata and screenshots.
- Add lightweight crash reporting.
- Run accessibility, localization, and device-size QA.
