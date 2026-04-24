import SwiftUI
import AdaptAiKit

/// Emergency view with Soulspring-inspired aesthetics (cards, eyebrows,
/// circular icon badges) but keeping the AdaptAi brand palette.
struct EmergencyView: View {
    @Environment(AuthService.self) private var authService
    @State private var vm = EmergencyViewModel()
    @State private var showConfirmation = false
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            AdaptBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AdaptTheme.Spacing.md) {
                    if authService.isGuestMode {
                        GuestModeBanner()
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }

                    if vm.isEmergencyActive {
                        triggeredCard
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                    } else {
                        sosHero
                            .padding(.top, 12)
                    }

                    contactsSection
                        .padding(.horizontal, 20)

                    quickLinksGrid
                        .padding(.horizontal, 20)

                    crashDetectionCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Emergencia")
        .task { await vm.load() }
        .alert("Confirmar Emergencia", isPresented: $showConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("PEDIR AYUDA", role: .destructive) {
                Task { await vm.triggerEmergency() }
            }
        } message: {
            Text("Se llamará a tu contacto de emergencia y se notificará a tus cuidadores.")
        }
    }

    // MARK: - SOS Hero

    private var sosHero: some View {
        Button {
            if !authService.isGuestMode { showConfirmation = true }
        } label: {
            VStack(spacing: 18) {
                ZStack {
                    // Pulse ring
                    Circle()
                        .fill(AdaptTheme.Palette.error.opacity(0.18))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPulsing ? 1.18 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.7)

                    // Main circle
                    Circle()
                        .fill(AdaptTheme.Gradient.heart)
                        .frame(width: 140, height: 140)
                        .shadow(color: AdaptTheme.Palette.error.opacity(0.4), radius: 24, y: 10)

                    Image(systemName: "sos")
                        .font(.system(size: 46, weight: .heavy))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    AdaptEyebrow("Toca el botón")
                    Text("Emergencia")
                        .font(AdaptTheme.Font.title)
                        .foregroundStyle(AdaptTheme.Palette.error)
                    Text(authService.isGuestMode
                         ? "Crea una cuenta para usar esta función"
                         : "Llamaremos a tu contacto principal")
                        .font(AdaptTheme.Font.body(14))
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(authService.isGuestMode)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }

    // MARK: - Triggered card

    private var triggeredCard: some View {
        AdaptCard(padding: 28) {
            VStack(spacing: 16) {
                ZStack {
                    Circle().fill(AdaptTheme.Palette.success.opacity(0.18)).frame(width: 100, height: 100)
                    Image(systemName: "phone.connection.fill")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(AdaptTheme.Palette.success)
                        .symbolEffect(.pulse)
                }

                VStack(spacing: 6) {
                    AdaptEyebrow("Activa")
                    Text("Ayuda en camino")
                        .font(AdaptTheme.Font.title)
                        .foregroundStyle(AdaptTheme.Color.textPrimary)
                    if let contact = vm.contacts.first(where: { $0.isPrimary }) {
                        Text("Llamando a \(contact.name)...")
                            .font(AdaptTheme.Font.bodyText)
                            .foregroundStyle(AdaptTheme.Color.textSecondary)
                    }
                    Text("Se notificó a tus cuidadores")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textTertiary)
                }

                Button {
                    vm.isEmergencyActive = false
                } label: {
                    Text("Cancelar emergencia")
                }
                .buttonStyle(AdaptSecondaryButtonStyle())
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Contacts section

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AdaptEyebrow("Contactos")
                Spacer()
                NavigationLink {
                    EmergencyContactsView()
                } label: {
                    Text(vm.contacts.isEmpty ? "Agregar" : "Editar")
                        .font(AdaptTheme.Font.body(13, weight: .semibold))
                        .foregroundStyle(AdaptTheme.Palette.primary)
                }
            }

            if vm.contacts.isEmpty {
                NavigationLink {
                    EmergencyContactsView()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(AdaptTheme.Palette.primary.opacity(0.18)).frame(width: 44, height: 44)
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(AdaptTheme.Palette.primary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Agregar contactos")
                                .font(AdaptTheme.Font.card)
                                .foregroundStyle(AdaptTheme.Color.textPrimary)
                            Text("Para pedir ayuda en emergencias")
                                .font(AdaptTheme.Font.caption)
                                .foregroundStyle(AdaptTheme.Color.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .foregroundStyle(AdaptTheme.Color.textTertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                            .fill(AdaptTheme.Color.surface)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    ForEach(vm.contacts) { contact in
                        contactRow(contact)
                    }
                }
            }
        }
    }

    private func contactRow(_ contact: EmergencyContactResponse) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(AdaptTheme.Palette.primary.opacity(0.18)).frame(width: 44, height: 44)
                Text(initials(contact.name))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AdaptTheme.Palette.primary)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(contact.name)
                        .font(AdaptTheme.Font.card)
                        .foregroundStyle(AdaptTheme.Color.textPrimary)
                    if contact.isPrimary {
                        AdaptChip("Principal", tint: AdaptTheme.Palette.gold)
                    }
                }
                if !contact.relationship.isEmpty {
                    Text(contact.relationship)
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                }
            }

            Spacer()

            if let url = URL(string: "tel://\(contact.phone)") {
                Link(destination: url) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(
                            Circle().fill(AdaptTheme.Palette.success)
                        )
                        .shadow(color: AdaptTheme.Palette.success.opacity(0.3), radius: 6, y: 3)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined()
    }

    // MARK: - Quick links grid (2x1)

    private var quickLinksGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AdaptEyebrow("Más opciones")
            HStack(spacing: 12) {
                NavigationLink {
                    MedicalIDCardView()
                } label: {
                    AdaptQuickActionTile(
                        eyebrow: "Médica",
                        title: "Credencial",
                        subtitle: "Datos de salud",
                        icon: "cross.case.fill",
                        tint: AdaptTheme.Palette.primary
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    LostModeView()
                } label: {
                    AdaptQuickActionTile(
                        eyebrow: "Perdido",
                        title: "Modo SOS",
                        subtitle: "Pantalla visible",
                        icon: "mappin.and.ellipse",
                        tint: AdaptTheme.Palette.warning
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Crash detection card

    private var crashDetectionCard: some View {
        let monitoring = CrashDetectionService.shared.isMonitoring
        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((monitoring ? AdaptTheme.Palette.success : AdaptTheme.Color.textTertiary).opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: monitoring ? "checkmark.shield.fill" : "shield.slash")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(monitoring ? AdaptTheme.Palette.success : AdaptTheme.Color.textTertiary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Detección de caídas")
                    .font(AdaptTheme.Font.card)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
                Text(monitoring
                     ? "Activa — llamaremos si detectamos un impacto"
                     : "Inactiva")
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }
}
