import SwiftUI
import NeuroNavKit

struct EmergencyView: View {
    @Environment(AuthService.self) private var authService
    @State private var vm = EmergencyViewModel()
    @State private var showConfirmation = false
    @State private var isPulsing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if authService.isGuestMode {
                    GuestModeBanner()
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                }

                if vm.isEmergencyActive {
                    triggeredView
                } else {
                    // Big SOS button with pulse animation
                    Button {
                        if !authService.isGuestMode {
                            showConfirmation = true
                        }
                    } label: {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(.red.opacity(0.15))
                                    .frame(width: 160, height: 160)
                                    .scaleEffect(isPulsing ? 1.15 : 1.0)
                                    .opacity(isPulsing ? 0.0 : 0.6)

                                Image(systemName: "sos.circle.fill")
                                    .font(.system(size: 120))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(.white, .red)
                            }

                            Text("EMERGENCIA")
                                .font(.title.bold())
                                .foregroundStyle(.red)

                            Text(authService.isGuestMode ? "Crea una cuenta para usar esta función" : "Toca para pedir ayuda")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(authService.isGuestMode)
                    .padding(.top, 32)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                            isPulsing = true
                        }
                    }
                }

                // Emergency contacts section
                if !vm.contacts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Contactos de emergencia")
                                .font(.headline)
                            Spacer()
                            NavigationLink {
                                EmergencyContactsView()
                            } label: {
                                Text("Editar")
                                    .font(.subheadline)
                                    .foregroundStyle(.blue)
                            }
                        }

                        ForEach(vm.contacts) { contact in
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(contact.name)
                                            .font(.body.weight(.medium))
                                        if contact.isPrimary {
                                            Text("Principal")
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.blue.opacity(0.15))
                                                .foregroundStyle(.blue)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(contact.relationship)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
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
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    NavigationLink {
                        EmergencyContactsView()
                    } label: {
                        Label("Agregar contactos de emergencia", systemImage: "person.crop.circle.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                }

                // Medical ID card
                NavigationLink {
                    MedicalIDCardView()
                } label: {
                    Label("Tarjeta Médica", systemImage: "cross.case.fill")
                        .font(.nnHeadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.nnPrimary.opacity(0.1))
                        .foregroundStyle(.nnPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                // Lost mode link
                NavigationLink {
                    LostModeView()
                } label: {
                    Label("Modo Perdido", systemImage: "mappin.and.ellipse")
                        .font(.nnHeadline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)

                // Crash detection status
                HStack(spacing: 12) {
                    Image(systemName: CrashDetectionService.shared.isMonitoring ? "checkmark.shield.fill" : "shield.slash")
                        .foregroundStyle(CrashDetectionService.shared.isMonitoring ? .green : .gray)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Detección de caídas")
                            .font(.subheadline.weight(.medium))
                        Text(CrashDetectionService.shared.isMonitoring ? "Activa — se llamará a tu contacto si detecta un impacto" : "Inactiva")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Emergencia")
        .task { await vm.load() }
        .alert("Confirmar Emergencia", isPresented: $showConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("PEDIR AYUDA", role: .destructive) {
                Task { await vm.triggerEmergency() }
            }
        } message: {
            Text("Se llamará a tu contacto de emergencia y se notificará a tus cuidadores.")
        }
    }

    private var triggeredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "phone.connection.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolEffect(.pulse)

            Text("Ayuda en camino")
                .font(.title.bold())

            if let contact = vm.contacts.first(where: { $0.isPrimary }) {
                Text("Llamando a \(contact.name)...")
                    .foregroundStyle(.secondary)
            }

            Text("Se notificó a tus cuidadores")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                vm.isEmergencyActive = false
            } label: {
                Text("Cancelar emergencia")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.gray.opacity(0.2))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }
}
