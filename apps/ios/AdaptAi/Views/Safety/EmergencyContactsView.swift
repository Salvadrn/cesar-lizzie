import SwiftUI
import AdaptAiKit

struct EmergencyContactsView: View {
    @State private var contacts: [EmergencyContactResponse] = []
    @State private var isLoading = false
    @State private var showAddSheet = false
    @State private var errorMessage: String?

    private let api = APIClient.shared

    var body: some View {
        List {
            if contacts.isEmpty && !isLoading {
                ContentUnavailableView(
                    "Sin contactos",
                    systemImage: "person.crop.circle.badge.plus",
                    description: Text("Agrega contactos de emergencia para que puedan ayudarte")
                )
            }

            ForEach(contacts) { contact in
                HStack(spacing: 14) {
                    Image(systemName: contact.isPrimary ? "star.circle.fill" : "person.circle.fill")
                        .font(.title2)
                        .foregroundStyle(contact.isPrimary ? .yellow : .blue)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(contact.name)
                                .font(.nnBody)
                            if contact.isPrimary {
                                Text("Principal")
                                    .font(.nnCaption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.yellow.opacity(0.2))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                        Text(contact.relationship)
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)
                        Text(contact.phone)
                            .font(.nnCaption)
                            .foregroundStyle(.blue)
                    }

                    Spacer()

                    if let url = URL(string: "tel://\(contact.phone)") {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                                .font(.title3)
                                .foregroundStyle(.green)
                                .padding(10)
                                .background(.green.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await deleteContact(id: contact.id) }
                    } label: {
                        Label("Eliminar", systemImage: "trash")
                    }

                    if !contact.isPrimary {
                        Button {
                            Task { await setPrimary(id: contact.id) }
                        } label: {
                            Label("Principal", systemImage: "star.fill")
                        }
                        .tint(.yellow)
                    }
                }
            }
        }
        .navigationTitle("Contactos de emergencia")
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
            AddContactSheet { name, phone, relationship in
                Task {
                    await addContact(name: name, phone: phone, relationship: relationship)
                    showAddSheet = false
                }
            }
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            contacts = try await api.fetchEmergencyContacts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func addContact(name: String, phone: String, relationship: String) async {
        do {
            try await api.addEmergencyContact(name: name, phone: phone, relationship: relationship, isPrimary: contacts.isEmpty)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteContact(id: String) async {
        do {
            try await api.deleteEmergencyContact(id: id)
            contacts.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setPrimary(id: String) async {
        do {
            try await api.setEmergencyContactPrimary(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AddContactSheet: View {
    let onSave: (String, String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = "Familiar"

    let relationships = ["Familiar", "Padre/Madre", "Hijo/a", "Hermano/a", "Esposo/a", "Amigo/a", "Cuidador", "Médico", "Otro"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Datos del contacto") {
                    TextField("Nombre", text: $name)
                    TextField("Teléfono", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Relación") {
                    Picker("Relación", selection: $relationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }
            }
            .navigationTitle("Nuevo contacto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        onSave(name, phone, relationship)
                    }
                    .disabled(name.isEmpty || phone.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
