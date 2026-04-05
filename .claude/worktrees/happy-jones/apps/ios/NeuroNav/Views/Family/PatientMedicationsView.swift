import SwiftUI
import NeuroNavKit

struct PatientMedicationsView: View {
    let patientId: String
    let patientName: String
    @State private var medications: [MedicationRow] = []
    @State private var isLoading = true
    @State private var showAddSheet = false

    var body: some View {
        List {
            if medications.isEmpty && !isLoading {
                ContentUnavailableView(
                    "Sin medicamentos",
                    systemImage: "pills.fill",
                    description: Text("\(patientName) no tiene medicamentos registrados")
                )
            }

            let pending = medications.filter { !$0.takenToday }.sorted { $0.hour * 60 + $0.minute < $1.hour * 60 + $1.minute }
            let taken = medications.filter { $0.takenToday }

            if !pending.isEmpty {
                Section("Pendientes") {
                    ForEach(pending) { med in
                        medRow(med)
                    }
                }
            }

            if !taken.isEmpty {
                Section("Tomados hoy") {
                    ForEach(taken) { med in
                        medRow(med)
                    }
                }
            }
        }
        .navigationTitle("Medicamentos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddPatientMedicationSheet(patientId: patientId) {
                Task { await loadMedications() }
            }
        }
        .task { await loadMedications() }
        .refreshable { await loadMedications() }
    }

    private func loadMedications() async {
        isLoading = true
        do {
            medications = try await APIClient.shared.fetchPatientMedications(patientId: patientId)
        } catch {
            print("Error loading patient medications: \(error)")
        }
        isLoading = false
    }

    private func medRow(_ med: MedicationRow) -> some View {
        HStack(spacing: 14) {
            Image(systemName: med.takenToday ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(med.takenToday ? .green : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(.body.weight(.medium))
                    .strikethrough(med.takenToday)
                HStack(spacing: 4) {
                    Text(med.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let offsets = med.reminderOffsets, !offsets.filter({ $0 > 0 }).isEmpty {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text(offsets.filter { $0 > 0 }.sorted().map { "\($0) min" }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Text(String(format: "%02d:%02d", med.hour, med.minute))
                .font(.callout.monospacedDigit())
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    try? await APIClient.shared.deleteMedication(id: med.id)
                    await loadMedications()
                }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }
}

struct AddPatientMedicationSheet: View {
    let patientId: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = Date()
    @State private var selectedOffsets: Set<Int> = [5]
    @State private var isSaving = false

    private let availableOffsets = [5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medicamento") {
                    TextField("Nombre", text: $name)
                    TextField("Dosis (ej: 1 pastilla, 5ml)", text: $dosage)
                }

                Section("Horario") {
                    DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recordatorios previos")
                            .font(.subheadline)
                        HStack(spacing: 8) {
                            ForEach(availableOffsets, id: \.self) { offset in
                                let isSelected = selectedOffsets.contains(offset)
                                Button {
                                    if isSelected {
                                        selectedOffsets.remove(offset)
                                    } else {
                                        selectedOffsets.insert(offset)
                                    }
                                } label: {
                                    Text("\(offset) min")
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? .blue : Color(.systemGray5))
                                        .foregroundStyle(isSelected ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Agregar medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        isSaving = true
                        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
                        Task {
                            do {
                                try await APIClient.shared.addPatientMedication(
                                    patientId: patientId,
                                    name: name,
                                    dosage: dosage,
                                    hour: components.hour ?? 8,
                                    minute: components.minute ?? 0,
                                    reminderOffsets: Array(selectedOffsets).sorted()
                                )
                                onSave()
                                dismiss()
                            } catch {
                                print("Error adding patient medication: \(error)")
                            }
                            isSaving = false
                        }
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
