import SwiftUI

struct MorningPlanningView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var checkInStore: DailyCheckInStore

    @State private var priorityOne = ""
    @State private var priorityTwo = ""
    @State private var priorityThree = ""
    @State private var intention = ""
    @State private var energy = 70

    var body: some View {
        NavigationStack {
            Form {
                Section("Morning Check-In") {
                    Stepper("Expected energy: \(energy)/100", value: $energy, in: 10...100, step: 5)
                    TextField("How do you want today to feel?", text: $intention, axis: .vertical)
                }

                Section {
                    TextField("Priority 1", text: $priorityOne)
                    TextField("Priority 2", text: $priorityTwo)
                    TextField("Priority 3", text: $priorityThree)
                } header: {
                    Text("Top Priorities")
                } footer: {
                    Text("Your priorities appear before calendar and job-search suggestions.")
                }
            }
            .navigationTitle("Plan Today")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        checkInStore.saveMorningPlan(
                            priorities: [priorityOne, priorityTwo, priorityThree],
                            intention: intention,
                            energy: energy
                        )
                        dismiss()
                    }
                    .disabled(priorityOne.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: loadSavedValues)
        }
    }

    private func loadSavedValues() {
        let priorities = checkInStore.today.priorities
        priorityOne = priorities.indices.contains(0) ? priorities[0] : ""
        priorityTwo = priorities.indices.contains(1) ? priorities[1] : ""
        priorityThree = priorities.indices.contains(2) ? priorities[2] : ""
        intention = checkInStore.today.intention
        energy = checkInStore.today.morningEnergy
    }
}

struct EveningReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var checkInStore: DailyCheckInStore

    @State private var completedPriorityCount = 0
    @State private var energy = 60
    @State private var reflection = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Close The Loop") {
                    Stepper(
                        "Priorities completed: \(completedPriorityCount)",
                        value: $completedPriorityCount,
                        in: 0...max(checkInStore.today.priorities.count, 3)
                    )
                    Stepper("End-of-day energy: \(energy)/100", value: $energy, in: 10...100, step: 5)
                }

                Section("Reflection") {
                    TextField(
                        "What worked, and what should change tomorrow?",
                        text: $reflection,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Evening Review")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        checkInStore.saveEveningReview(
                            completedPriorityCount: completedPriorityCount,
                            energy: energy,
                            reflection: reflection
                        )
                        dismiss()
                    }
                }
            }
            .onAppear {
                completedPriorityCount = checkInStore.today.completedPriorityCount
                energy = checkInStore.today.eveningEnergy
                reflection = checkInStore.today.reflection
            }
        }
    }
}
