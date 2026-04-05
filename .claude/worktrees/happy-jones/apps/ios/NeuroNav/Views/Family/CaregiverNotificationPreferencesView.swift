import SwiftUI
import NeuroNavKit

struct CaregiverNotificationPreferencesView: View {
    private var service = CaregiverRealtimeService.shared

    var body: some View {
        @Bindable var svc = service
        Form {
            // MARK: - Header
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notificaciones en tiempo real")
                        .font(.nnHeadline)
                        .foregroundStyle(.nnPrimary)

                    Text("Elige qu\u{00e9} actividades de tu paciente quieres recibir como notificaci\u{00f3}n local en este dispositivo.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // MARK: - Categories
            Section("Categor\u{00ed}as") {
                // Emergencies - always on
                HStack {
                    Label {
                        Text("Emergencias")
                    } icon: {
                        Image(systemName: "sos")
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                        .disabled(true)
                }
                .opacity(0.85)

                Text("Las alertas de emergencia siempre est\u{00e1}n activas y no se pueden desactivar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Routines
                Toggle(isOn: $svc.notifyRoutines) {
                    Label {
                        Text("Rutinas")
                    } icon: {
                        Image(systemName: "list.bullet.clipboard")
                            .foregroundStyle(.nnPrimary)
                    }
                }
                .tint(.nnPrimary)

                // Medications
                Toggle(isOn: $svc.notifyMedications) {
                    Label {
                        Text("Medicamentos")
                    } icon: {
                        Image(systemName: "pills.fill")
                            .foregroundStyle(.purple)
                    }
                }
                .tint(.nnPrimary)

                // Zones
                Toggle(isOn: $svc.notifyZones) {
                    Label {
                        Text("Zonas seguras")
                    } icon: {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.orange)
                    }
                }
                .tint(.nnPrimary)
            }

            // MARK: - Info
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Informaci\u{00f3}n", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.nnPrimary)

                    Text("Estas notificaciones se env\u{00ed}an localmente cuando tu dispositivo recibe actualizaciones en tiempo real. Aseg\u{00fa}rate de tener la app abierta o en segundo plano para recibirlas.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            // MARK: - Connection Status
            Section {
                HStack {
                    Circle()
                        .fill(service.isConnected ? .green : .red)
                        .frame(width: 10, height: 10)

                    Text(service.isConnected ? "Conectado" : "Desconectado")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !service.patientName.isEmpty {
                        Text(service.patientName)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.nnPrimary)
                    }
                }
            }
        }
        .navigationTitle("Notificaciones")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CaregiverNotificationPreferencesView()
    }
}
