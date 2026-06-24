import SwiftUI

struct JobSearchView: View {
    @EnvironmentObject private var store: JobApplicationStore
    @State private var showingAddApplication = false
    @State private var editingApplication: JobApplication?

    var body: some View {
        NavigationStack {
            List {
                Section("Applications") {
                    ForEach(store.applications) { application in
                        Button {
                            editingApplication = application
                        } label: {
                            JobApplicationRow(application: application)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: store.delete)
                }
            }
            .navigationTitle("Job Search")
            .toolbar {
                Button {
                    showingAddApplication = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingAddApplication) {
                AddJobApplicationView()
                    .environmentObject(store)
            }
            .sheet(item: $editingApplication) { application in
                EditJobApplicationView(application: application)
                    .environmentObject(store)
            }
        }
    }
}

private struct JobApplicationRow: View {
    let application: JobApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.company)
                        .font(.headline)
                    Text(application.role)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(application.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Text(application.nextAction)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label(application.deadline.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

private struct AddJobApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: JobApplicationStore

    @State private var company = ""
    @State private var role = ""
    @State private var status: JobStatus = .interested
    @State private var deadline = Date()
    @State private var nextAction = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    TextField("Company", text: $company)
                    TextField("Role", text: $role)
                    Picker("Status", selection: $status) {
                        ForEach(JobStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }

                Section("Next Action") {
                    TextField("Example: send follow-up email", text: $nextAction, axis: .vertical)
                }
            }
            .navigationTitle("New Application")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.add(
                            JobApplication(
                                company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                                role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                                status: status,
                                deadline: deadline,
                                nextAction: nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        dismiss()
                    }
                    .disabled(company.isEmpty || role.isEmpty)
                }
            }
        }
    }
}

private struct EditJobApplicationView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: JobApplicationStore

    let application: JobApplication

    @State private var company: String
    @State private var role: String
    @State private var status: JobStatus
    @State private var deadline: Date
    @State private var nextAction: String

    init(application: JobApplication) {
        self.application = application
        _company = State(initialValue: application.company)
        _role = State(initialValue: application.role)
        _status = State(initialValue: application.status)
        _deadline = State(initialValue: application.deadline)
        _nextAction = State(initialValue: application.nextAction)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Role") {
                    TextField("Company", text: $company)
                    TextField("Role", text: $role)
                    Picker("Status", selection: $status) {
                        ForEach(JobStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }

                Section("Next Action") {
                    TextField("Next action", text: $nextAction, axis: .vertical)
                }
            }
            .navigationTitle("Edit Application")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.update(
                            JobApplication(
                                id: application.id,
                                company: company.trimmingCharacters(in: .whitespacesAndNewlines),
                                role: role.trimmingCharacters(in: .whitespacesAndNewlines),
                                status: status,
                                deadline: deadline,
                                nextAction: nextAction.trimmingCharacters(in: .whitespacesAndNewlines)
                            )
                        )
                        dismiss()
                    }
                    .disabled(company.isEmpty || role.isEmpty)
                }
            }
        }
    }
}
