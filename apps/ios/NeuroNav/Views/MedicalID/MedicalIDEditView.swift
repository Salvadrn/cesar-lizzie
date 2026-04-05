import SwiftUI
import NeuroNavKit

struct MedicalIDEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var medicalID: MedicalIDRow?

    @State private var fullName = ""
    @State private var dateOfBirth = ""
    @State private var bloodType = ""
    @State private var weight = ""
    @State private var height = ""
    @State private var allergiesText = ""
    @State private var conditionsText = ""
    @State private var medicationsText = ""
    @State private var doctorName = ""
    @State private var doctorPhone = ""
    @State private var insuranceProvider = ""
    @State private var insuranceNumber = ""
    @State private var organDonor = false
    @State private var notes = ""
    @State private var isSaving = false

    let bloodTypes = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    var body: some View {
        Form {
            Section("Informacion Personal") {
                TextField("Nombre completo", text: $fullName)
                TextField("Fecha de nacimiento (DD/MM/AAAA)", text: $dateOfBirth)
                Picker("Tipo de sangre", selection: $bloodType) {
                    ForEach(bloodTypes, id: \.self) { type in
                        Text(type.isEmpty ? "No especificado" : type).tag(type)
                    }
                }
            }

            Section("Datos Fisicos") {
                TextField("Peso (kg)", text: $weight)
                    .keyboardType(.decimalPad)
                TextField("Estatura (cm)", text: $height)
                    .keyboardType(.decimalPad)
                Toggle("Donador de organos", isOn: $organDonor)
            }

            Section(header: Text("Alergias"), footer: Text("Separa con comas: Penicilina, Mariscos, Polen")) {
                TextField("Alergias", text: $allergiesText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section(header: Text("Condiciones Medicas"), footer: Text("Separa con comas: Diabetes, Hipertension")) {
                TextField("Condiciones", text: $conditionsText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section(header: Text("Medicamentos Actuales"), footer: Text("Separa con comas: Metformina 500mg, Losartan 50mg")) {
                TextField("Medicamentos", text: $medicationsText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Doctor") {
                TextField("Nombre del doctor", text: $doctorName)
                TextField("Telefono del doctor", text: $doctorPhone)
                    .keyboardType(.phonePad)
            }

            Section("Seguro Medico") {
                TextField("Aseguradora", text: $insuranceProvider)
                TextField("Numero de poliza", text: $insuranceNumber)
            }

            Section("Notas Adicionales") {
                TextField("Notas para emergencias...", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(medicalID != nil ? "Editar Credencial" : "Nueva Credencial")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") {
                    Task { await save() }
                }
                .bold()
                .disabled(fullName.isEmpty || isSaving)
            }
        }
        .onAppear { loadExisting() }
    }

    private func loadExisting() {
        guard let id = medicalID else { return }
        fullName = id.fullName
        dateOfBirth = id.dateOfBirth ?? ""
        bloodType = id.bloodType ?? ""
        weight = id.weight.map { "\(Int($0))" } ?? ""
        height = id.height.map { "\(Int($0))" } ?? ""
        allergiesText = id.allergies.joined(separator: ", ")
        conditionsText = id.conditions.joined(separator: ", ")
        medicationsText = id.currentMedications.joined(separator: ", ")
        doctorName = id.doctorName ?? ""
        doctorPhone = id.doctorPhone ?? ""
        insuranceProvider = id.insuranceProvider ?? ""
        insuranceNumber = id.insuranceNumber ?? ""
        organDonor = id.organDonor
        notes = id.notes ?? ""
    }

    private func parseList(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private func save() async {
        isSaving = true
        do {
            let userId = try await APIClient.shared.currentUserId()
            let row = MedicalIDRow(
                id: medicalID?.id ?? UUID().uuidString,
                userId: userId,
                fullName: fullName,
                dateOfBirth: dateOfBirth.isEmpty ? nil : dateOfBirth,
                bloodType: bloodType.isEmpty ? nil : bloodType,
                weight: Double(weight),
                height: Double(height),
                allergies: parseList(allergiesText),
                conditions: parseList(conditionsText),
                currentMedications: parseList(medicationsText),
                doctorName: doctorName.isEmpty ? nil : doctorName,
                doctorPhone: doctorPhone.isEmpty ? nil : doctorPhone,
                insuranceProvider: insuranceProvider.isEmpty ? nil : insuranceProvider,
                insuranceNumber: insuranceNumber.isEmpty ? nil : insuranceNumber,
                organDonor: organDonor,
                notes: notes.isEmpty ? nil : notes,
                photoUrl: medicalID?.photoUrl,
                updatedAt: nil
            )
            try await APIClient.shared.upsertMedicalID(row)
            medicalID = row
            dismiss()
        } catch {
            print("Error saving medical ID: \(error)")
        }
        isSaving = false
    }
}
