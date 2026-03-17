import SwiftUI
import NeuroNavKit

struct AppointmentView: View {
    @Environment(AuthService.self) private var authService
    @State private var vm = AppointmentViewModel()
    @State private var showAddSheet = false

    var body: some View {
        List {
            if vm.isLoading {
                ProgressView("Cargando citas...")
            }

            if !vm.upcoming.isEmpty {
                Section("Próximas citas") {
                    ForEach(vm.upcoming) { appt in
                        appointmentRow(appt)
                    }
                }
            }

            if !vm.past.isEmpty {
                Section("Anteriores") {
                    ForEach(vm.past.prefix(10)) { appt in
                        appointmentRow(appt)
                            .opacity(0.6)
                    }
                }
            }

            if vm.appointments.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Sin citas médicas",
                    systemImage: "stethoscope",
                    description: Text("Agrega tus citas al doctor para recibir recordatorios")
                )
            }
        }
        .navigationTitle("Citas Médicas")
        .toolbar {
            if !authService.isGuestMode {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAppointmentSheet(vm: vm)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func appointmentRow(_ appt: AppointmentRow) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 4) {
                if let date = appt.date {
                    Text(date, format: .dateTime.day())
                        .font(.nnTitle2)
                    Text(date, format: .dateTime.month(.abbreviated))
                        .font(.nnCaption2)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "calendar")
                        .font(.title2)
                }
            }
            .frame(width: 50, height: 50)
            .background(appt.isPast ? Color(.systemGray5) : .blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(appt.doctorName)
                    .font(.nnBody)

                HStack(spacing: 6) {
                    if let specialty = appt.specialty, !specialty.isEmpty {
                        Text(specialty)
                            .font(.nnCaption)
                            .foregroundStyle(.blue)
                    }
                    if appt.isRecurring {
                        Label("Cada \(appt.recurringMonths ?? 1) meses", systemImage: "repeat")
                            .font(.nnCaption2)
                            .foregroundStyle(.purple)
                    }
                }

                if let location = appt.location, !location.isEmpty {
                    Label(location, systemImage: "mappin")
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let date = appt.date, !appt.isPast {
                Text(date, format: .dateTime.hour().minute())
                    .font(.nnCallout)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .swipeActions(edge: .trailing) {
            if !authService.isGuestMode {
                Button(role: .destructive) {
                    Task { await vm.deleteAppointment(id: appt.id) }
                } label: {
                    Label("Cancelar", systemImage: "xmark")
                }
            }
        }
        .swipeActions(edge: .leading) {
            if !appt.isPast && !authService.isGuestMode {
                Button {
                    Task { await vm.completeAppointment(appt) }
                } label: {
                    Label("Completada", systemImage: "checkmark")
                }
                .tint(.green)
            }
        }
    }
}

// MARK: - Add Appointment Sheet

struct AddAppointmentSheet: View {
    let vm: AppointmentViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var doctorName = ""
    @State private var specialty = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var isRecurring = false
    @State private var recurringMonths = 3
    @State private var isSaving = false

    private let recurringOptions = [1, 2, 3, 6, 12]

    var body: some View {
        NavigationStack {
            Form {
                Section("Doctor") {
                    TextField("Nombre del doctor", text: $doctorName)
                    TextField("Especialidad (ej: Cardiólogo)", text: $specialty)
                }

                Section("Detalles") {
                    DatePicker("Fecha y hora", selection: $date, in: Date()...,
                              displayedComponents: [.date, .hourAndMinute])
                    TextField("Ubicación (opcional)", text: $location)
                    TextField("Notas (opcional)", text: $notes)
                }

                Section {
                    Toggle("Cita periódica", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Repetir cada", selection: $recurringMonths) {
                            ForEach(recurringOptions, id: \.self) { months in
                                Text(months == 1 ? "1 mes" : "\(months) meses").tag(months)
                            }
                        }
                        Text("Se programará automáticamente la siguiente cita cuando marques esta como completada")
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Frecuencia")
                }
            }
            .navigationTitle("Nueva Cita")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        isSaving = true
                        Task {
                            await vm.addAppointment(
                                doctorName: doctorName,
                                specialty: specialty.isEmpty ? nil : specialty,
                                location: location.isEmpty ? nil : location,
                                notes: notes.isEmpty ? nil : notes,
                                date: date,
                                isRecurring: isRecurring,
                                recurringMonths: isRecurring ? recurringMonths : nil
                            )
                            isSaving = false
                            dismiss()
                        }
                    }
                    .disabled(doctorName.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
