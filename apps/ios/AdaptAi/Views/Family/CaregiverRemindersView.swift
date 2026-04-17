import SwiftUI
import AdaptAiKit

struct CaregiverRemindersView: View {
    let patientId: String
    let patientName: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var reminders: [PatientReminder] = []
    @State private var showAddSheet = false
    @State private var isLoading = true

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Cargando recordatorios...")
            } else if reminders.isEmpty {
                ContentUnavailableView {
                    Label("Sin recordatorios", systemImage: "bell.badge")
                } description: {
                    Text("Crea recordatorios para \(patientName)")
                }
            } else {
                List {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder)
                    }
                    .onDelete { indices in
                        Task {
                            for index in indices {
                                await deleteReminder(reminders[index])
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Recordatorios")
        .navigationBarTitleDisplayMode(.large)
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
            AddReminderSheet(patientId: patientId, patientName: patientName) { newReminder in
                reminders.insert(newReminder, at: 0)
            }
        }
        .task {
            await loadReminders()
        }
    }

    private func reminderRow(_ reminder: PatientReminder) -> some View {
        HStack(spacing: 14) {
            Image(systemName: iconForType(reminder.type))
                .font(.title2)
                .foregroundStyle(colorForType(reminder.type))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.nnHeadline)
                    .foregroundStyle(isDark ? .white : .nnDarkText)

                if !reminder.message.isEmpty {
                    Text(reminder.message)
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                        .lineLimit(2)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(reminder.formattedTime)
                        .font(.nnCaption2)

                    if reminder.isRecurring {
                        Text("·")
                        Image(systemName: "repeat")
                            .font(.system(size: 10))
                        Text(reminder.recurrenceLabel)
                            .font(.nnCaption2)
                    }
                }
                .foregroundStyle(.nnMidGray)
            }

            Spacer()

            if reminder.isActive {
                Circle()
                    .fill(Color.nnSuccess)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }

    private func loadReminders() async {
        // Load from UserDefaults (local storage for caregiver-created reminders)
        if let data = UserDefaults.standard.data(forKey: "caregiver_reminders_\(patientId)"),
           let decoded = try? JSONDecoder().decode([PatientReminder].self, from: data) {
            reminders = decoded
        }
        isLoading = false
    }

    private func deleteReminder(_ reminder: PatientReminder) async {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()

        // Cancel local notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id])
    }

    private func saveReminders() {
        if let data = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(data, forKey: "caregiver_reminders_\(patientId)")
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "medication": return "pills.fill"
        case "routine": return "list.clipboard.fill"
        case "appointment": return "stethoscope"
        case "hydration": return "drop.fill"
        case "exercise": return "figure.walk"
        default: return "bell.fill"
        }
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "medication": return .nnSuccess
        case "routine": return .nnPrimary
        case "appointment": return .purple
        case "hydration": return .cyan
        case "exercise": return .orange
        default: return .nnWarning
        }
    }
}

// MARK: - Reminder Model

struct PatientReminder: Codable, Identifiable {
    let id: String
    let patientId: String
    let title: String
    let message: String
    let type: String // medication, routine, appointment, hydration, exercise, general
    let hour: Int
    let minute: Int
    let isRecurring: Bool
    let recurringDays: [Int] // 1=Sun, 2=Mon, ... 7=Sat
    let isActive: Bool
    let createdAt: Date

    var formattedTime: String {
        String(format: "%d:%02d %@", hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour), minute, hour >= 12 ? "PM" : "AM")
    }

    var recurrenceLabel: String {
        if recurringDays.count == 7 { return "Todos los días" }
        if recurringDays == [2, 3, 4, 5, 6] { return "Lun-Vie" }
        let dayNames = ["", "Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
        return recurringDays.map { dayNames[$0] }.joined(separator: ", ")
    }
}

// MARK: - Add Reminder Sheet

struct AddReminderSheet: View {
    let patientId: String
    let patientName: String
    let onSave: (PatientReminder) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var message = ""
    @State private var type = "general"
    @State private var time = Date()
    @State private var isRecurring = true
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // Mon-Fri
    @State private var isSaving = false

    private let types = [
        ("general", "General", "bell.fill"),
        ("medication", "Medicamento", "pills.fill"),
        ("routine", "Rutina", "list.clipboard.fill"),
        ("appointment", "Cita médica", "stethoscope"),
        ("hydration", "Hidratación", "drop.fill"),
        ("exercise", "Ejercicio", "figure.walk"),
    ]

    private let dayLabels = [
        (1, "D"), (2, "L"), (3, "M"), (4, "Mi"), (5, "J"), (6, "V"), (7, "S")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Recordatorio para \(patientName)") {
                    TextField("Título", text: $title)
                    TextField("Mensaje (opcional)", text: $message, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Tipo") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(types, id: \.0) { typeId, label, icon in
                            Button {
                                type = typeId
                                if title.isEmpty { title = label }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: icon)
                                        .font(.system(size: 18))
                                    Text(label)
                                        .font(.nnCaption2)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(type == typeId ? Color.nnPrimary.opacity(0.12) : Color(.systemGray6))
                                .foregroundStyle(type == typeId ? .nnPrimary : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(type == typeId ? Color.nnPrimary : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Horario") {
                    DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)

                    Toggle("Repetir", isOn: $isRecurring)

                    if isRecurring {
                        HStack(spacing: 6) {
                            ForEach(dayLabels, id: \.0) { day, label in
                                Button {
                                    if selectedDays.contains(day) {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                } label: {
                                    Text(label)
                                        .font(.nnCaption)
                                        .fontWeight(.bold)
                                        .frame(width: 36, height: 36)
                                        .background(selectedDays.contains(day) ? Color.nnPrimary : Color(.systemGray5))
                                        .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nuevo recordatorio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Guardar") }
                    }
                    .disabled(title.isEmpty || isSaving)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func save() async {
        isSaving = true

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let reminder = PatientReminder(
            id: UUID().uuidString,
            patientId: patientId,
            title: title,
            message: message,
            type: type,
            hour: components.hour ?? 8,
            minute: components.minute ?? 0,
            isRecurring: isRecurring,
            recurringDays: isRecurring ? Array(selectedDays).sorted() : [],
            isActive: true,
            createdAt: Date()
        )

        // Schedule local notification
        await scheduleNotification(for: reminder)

        // Save to storage
        var existing: [PatientReminder] = []
        if let data = UserDefaults.standard.data(forKey: "caregiver_reminders_\(patientId)"),
           let decoded = try? JSONDecoder().decode([PatientReminder].self, from: data) {
            existing = decoded
        }
        existing.insert(reminder, at: 0)
        if let encoded = try? JSONEncoder().encode(existing) {
            UserDefaults.standard.set(encoded, forKey: "caregiver_reminders_\(patientId)")
        }

        onSave(reminder)
        isSaving = false
        dismiss()
    }

    private func scheduleNotification(for reminder: PatientReminder) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized else { return }

        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.message.isEmpty ? "Es hora de tu \(reminder.title.lowercased())" : reminder.message
        content.sound = .default
        content.categoryIdentifier = "CAREGIVER_REMINDER"

        if reminder.isRecurring {
            // Schedule for each selected day
            for day in reminder.recurringDays {
                var dateComponents = DateComponents()
                dateComponents.weekday = day
                dateComponents.hour = reminder.hour
                dateComponents.minute = reminder.minute

                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(
                    identifier: "\(reminder.id)_day\(day)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        } else {
            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: reminder.id,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}

import UserNotifications
