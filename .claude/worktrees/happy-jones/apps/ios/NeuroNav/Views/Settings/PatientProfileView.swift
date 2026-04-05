import SwiftUI
import NeuroNavKit

struct PatientProfileView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var health = HealthKitService.shared

    // Profile fields (stored locally in UserDefaults, optional)
    @AppStorage("patient_age") private var age: String = ""
    @AppStorage("patient_weight") private var weightStr: String = ""
    @AppStorage("patient_height") private var heightStr: String = ""
    @AppStorage("patient_blood_type") private var bloodType: String = ""
    @AppStorage("patient_allergies") private var allergies: String = ""
    @AppStorage("patient_conditions") private var conditions: String = ""
    @AppStorage("patient_emergency_notes") private var emergencyNotes: String = ""
    @AppStorage("patient_doctor_name") private var doctorName: String = ""
    @AppStorage("patient_doctor_phone") private var doctorPhone: String = ""

    private var isDark: Bool { colorScheme == .dark }

    private let bloodTypes = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"]

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.nnPrimary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentProfile?.displayName ?? "Paciente")
                            .font(.nnTitle3)
                        Text(authService.currentProfile?.email ?? "")
                            .font(.nnCaption)
                            .foregroundStyle(.nnMidGray)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                HStack {
                    Label("Edad", systemImage: "calendar")
                    Spacer()
                    TextField("Ej: 45", text: $age)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }

                HStack {
                    Label("Peso (kg)", systemImage: "scalemass.fill")
                    Spacer()
                    if let w = health.weight {
                        HStack(spacing: 4) {
                            Text(String(format: "%.1f", w))
                                .foregroundStyle(.nnPrimary)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                        }
                    } else {
                        TextField("Ej: 70", text: $weightStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                HStack {
                    Label("Altura (cm)", systemImage: "ruler.fill")
                    Spacer()
                    if let h = health.height {
                        HStack(spacing: 4) {
                            Text(String(format: "%.0f", h))
                                .foregroundStyle(.nnPrimary)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                        }
                    } else {
                        TextField("Ej: 170", text: $heightStr)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Picker("Tipo de sangre", selection: $bloodType) {
                    ForEach(bloodTypes, id: \.self) { type in
                        Text(type.isEmpty ? "No especificado" : type).tag(type)
                    }
                }
            } header: {
                Text("Datos básicos")
            } footer: {
                if health.weight != nil || health.height != nil {
                    Label("Los datos con ♥ vienen de HealthKit", systemImage: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(.red.opacity(0.7))
                }
            }

            Section("Información médica") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Alergias")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                    TextField("Ej: Penicilina, maní, látex", text: $allergies, axis: .vertical)
                        .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Condiciones médicas")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                    TextField("Ej: Diabetes tipo 2, hipertensión", text: $conditions, axis: .vertical)
                        .lineLimit(2...4)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notas de emergencia")
                        .font(.nnCaption)
                        .foregroundStyle(.nnMidGray)
                    TextField("Información importante para emergencias", text: $emergencyNotes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }

            Section("Médico de cabecera") {
                HStack {
                    Label("Nombre", systemImage: "stethoscope")
                    Spacer()
                    TextField("Dr. García", text: $doctorName)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Label("Teléfono", systemImage: "phone.fill")
                    Spacer()
                    TextField("+52 55 1234 5678", text: $doctorPhone)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                }
            }

            if health.isAuthorized {
                Section {
                    NavigationLink {
                        HealthView()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.text.clipboard")
                                .foregroundStyle(.red)
                            Text("Ver datos de salud completos")
                            Spacer()
                            if let hr = health.heartRate {
                                Text("\(Int(hr)) BPM")
                                    .font(.nnCaption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text("HealthKit")
                } footer: {
                    Text("Datos sincronizados desde Apple Watch y el iPhone")
                }
            }

            Section {
                Text("Toda esta información es opcional y se guarda solo en tu dispositivo. Tu cuidador puede acceder a estos datos si los necesita.")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
            }
        }
        .navigationTitle("Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if health.isAuthorized {
                await health.fetchAll()
            }
        }
    }
}
