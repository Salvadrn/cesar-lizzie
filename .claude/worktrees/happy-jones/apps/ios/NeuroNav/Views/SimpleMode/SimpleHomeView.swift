import SwiftUI
import NeuroNavKit

// Estilo Apple Assistive Access:
// - Botones verticales enormes (ancho completo)
// - Iconos de 60pt+, texto title.bold()
// - cornerRadius 28, spacing generoso
// - Sin tab bar, sin elementos pequenos
// - Emergencia siempre visible al fondo

struct SimpleHomeView: View {
    @Environment(AuthService.self) private var authService
    @State private var showEmergencyConfirm = false
    @State private var emergencyVM = EmergencyViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Greeting
                if let name = authService.currentProfile?.displayName, !name.isEmpty {
                    Text("Hola, \(name)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                // Main action buttons
                SimpleNavButton(
                    title: "Mis Rutinas",
                    icon: "list.bullet.clipboard.fill",
                    color: .blue
                ) {
                    RoutineListView()
                }

                SimpleNavButton(
                    title: "Medicamentos",
                    icon: "pills.fill",
                    color: .green
                ) {
                    MedicationView()
                }

                SimpleNavButton(
                    title: "Ajustes",
                    icon: "gearshape.fill",
                    color: .gray
                ) {
                    SimpleSettingsView()
                }

                Spacer().frame(height: 8)

                // Emergency — always visible, always at bottom
                Button {
                    showEmergencyConfirm = true
                } label: {
                    HStack(spacing: 20) {
                        Image(systemName: "sos.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pedir Ayuda")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                            Text("Emergencia")
                                .font(.title3)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Inicio")
        .alert("Confirmar Emergencia", isPresented: $showEmergencyConfirm) {
            Button("Cancelar", role: .cancel) {}
            Button("PEDIR AYUDA", role: .destructive) {
                Task {
                    await emergencyVM.load()
                    await emergencyVM.triggerEmergency()
                }
            }
        } message: {
            Text("Se llamara a tu contacto de emergencia y se notificara a tus cuidadores.")
        }
    }
}

// MARK: - Assistive Access Navigation Button

struct SimpleNavButton<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(color)
                    .frame(width: 70)

                Text(title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.title2.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 28))
        }
        .buttonStyle(.plain)
    }
}
