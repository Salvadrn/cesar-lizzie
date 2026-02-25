import SwiftUI
import NeuroNavKit

struct MedicationView: View {
    @Environment(AuthService.self) private var authService
    @State private var vm = MedicationViewModel()
    @State private var showAddSheet = false

    var body: some View {
        List {
            if authService.isGuestMode {
                Section {
                    GuestModeBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if vm.medications.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Sin medicamentos",
                    systemImage: "pills.fill",
                    description: Text("Agrega tus medicamentos para recibir recordatorios")
                )
            }

            let pending = vm.medications.filter { !$0.takenToday }.sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
            let taken = vm.medications.filter { $0.takenToday }

            if !pending.isEmpty {
                Section("Pendientes") {
                    ForEach(pending) { med in
                        medicationRow(med)
                    }
                }
            }

            if !taken.isEmpty {
                Section("Tomados hoy") {
                    ForEach(taken) { med in
                        medicationRow(med)
                    }
                }
            }

            Section {
                NavigationLink {
                    AppointmentView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Citas Médicas")
                                .font(.body.weight(.medium))
                            Text("Citas al doctor y recordatorios")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Medicamentos")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if authService.isGuestMode {
                        return
                    }
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(authService.isGuestMode)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddMedicationSheet(vm: vm)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func medicationRow(_ med: MedicationViewModel.MedicationItem) -> some View {
        HStack(spacing: 14) {
            Button {
                if !med.takenToday && !authService.isGuestMode {
                    Task { await vm.markAsTaken(id: med.id) }
                }
            } label: {
                Image(systemName: med.takenToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(med.takenToday ? .green : .blue)
            }
            .buttonStyle(.plain)
            .disabled(authService.isGuestMode)

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(.body.weight(.medium))
                    .strikethrough(med.takenToday)
                HStack(spacing: 4) {
                    Text(med.dosage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let offLabel = med.offsetsLabel {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Image(systemName: "bell.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                        Text(offLabel)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Text(med.scheduledTime)
                .font(.callout.monospacedDigit())
                .foregroundStyle(timeColor(for: med))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(timeColor(for: med).opacity(0.1))
                .clipShape(Capsule())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !authService.isGuestMode {
                Button(role: .destructive) {
                    Task { await vm.deleteMedication(id: med.id) }
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        }
    }

    private func timeColor(for med: MedicationViewModel.MedicationItem) -> Color {
        if med.takenToday { return .green }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let medMinutes = med.hour * 60 + med.minute
        if medMinutes < nowMinutes { return .red }
        if medMinutes - nowMinutes < 60 { return .orange }
        return .blue
    }
}

struct AddMedicationSheet: View {
    let vm: MedicationViewModel
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
                                offsetChip(offset)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("Recibirás una notificación antes de la hora programada")
                }
            }
            .navigationTitle("Nuevo medicamento")
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
                            await vm.addMedication(
                                name: name,
                                dosage: dosage,
                                hour: components.hour ?? 8,
                                minute: components.minute ?? 0,
                                offsets: Array(selectedOffsets).sorted()
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func offsetChip(_ offset: Int) -> some View {
        let isSelected = selectedOffsets.contains(offset)
        return Button {
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
