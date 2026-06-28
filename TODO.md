# LifeOS TODO

## Phase 1: MVP Polish

- Add more unit tests for edge cases in `DailyPlannerEngine`.
- Add editable calendar mock data for demos.
- Improve empty states after users remove all job applications.
- Add preview data for SwiftUI previews.
- Add lightweight visual polish after running on a simulator.

## Phase 2: Production UI

- Refine onboarding copy after TestFlight feedback.
- Add permission-specific denied and empty states to the main feature screens.
- Add polished empty states for Dashboard, Jobs, and Settings.
- Add better dark mode tuning.
- Add simple animation to the energy ring and schedule timeline.
- Add accessibility labels for score cards and schedule blocks.

## Phase 3: Apple Integrations

- Add longer HealthKit trend windows and trend-based planner recommendations.
- Add editable calendar focus blocks after creation.
- Add DeviceActivity monitoring and ManagedSettings shielding after Apple approves the Family Controls entitlement.
- Add per-reminder toggles and weekday schedules.
- Keep mock/manual data as a fallback for every Apple integration.
- Add integration tests using injectable HealthKit and EventKit query abstractions.

## Phase 4: Better Planning (Core Complete)

- Add weekly focus trends alongside the existing sleep, steps, and workout trends.
- Expand the new daily priority system with reusable interview-prep templates.
- Extend the existing calendar conflict detection to support editing created blocks.
- Add weekly summaries based on the new morning and evening review flow.

## Phase 5: Focus Integration (Foundation Complete)

- Persist selected apps and categories securely.
- Add DeviceActivity monitoring and report extensions.
- Add optional ManagedSettings shields during active focus sessions.
- Feed approved Screen Time summaries into focus-risk calculations.
- Keep the local focus timer fully useful without Screen Time permission.

## Phase 6: Optional AI

- Add an AI planning service only after consent.
- Keep rule-based logic as a fallback.
- Show users what context is sent to the AI provider.
- Require approval before saving sensitive memory.

## Phase 7: Sync

- Evaluate whether sync is needed after local-first usage feels solid.
- Prefer CloudKit for private Apple-native sync.
- Use Supabase only if web, cross-platform, or server workflows become necessary.
- Keep offline/local-first behavior working.

## Phase 8: App Store Readiness

- Write privacy policy.
- Fill App Store privacy labels accurately.
- Add TestFlight metadata and screenshots.
- Add lightweight crash reporting.
- Run accessibility, localization, and device-size QA.
