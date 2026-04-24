import SwiftUI
import AdaptAiKit

/// Family / caregiver links view with Soulspring aesthetics:
/// warm background, elevated cards, circular avatar badges, eyebrows.
struct FamilyView: View {
    @State private var vm = FamilyViewModel()
    @State private var showInvite = false

    var body: some View {
        ZStack {
            AdaptBackground()

            Group {
                if vm.isLoading {
                    ProgressView("Cargando vínculos...")
                        .font(AdaptTheme.Font.bodyText)
                } else if vm.links.isEmpty {
                    emptyState
                } else {
                    content
                }
            }
        }
        .navigationTitle("Familia")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInvite = true
                } label: {
                    Image(systemName: vm.isCaregiver ? "person.badge.plus" : "qrcode")
                        .foregroundStyle(AdaptTheme.Palette.primary)
                }
            }
        }
        .sheet(isPresented: $showInvite) {
            InviteCodeView(vm: vm)
        }
        .task { await vm.fetchLinks() }
        .refreshable { await vm.fetchLinks() }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AdaptTheme.Palette.family.opacity(0.18))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(AdaptTheme.Palette.family)
            }

            VStack(spacing: 6) {
                Text("Sin vínculos")
                    .font(AdaptTheme.Font.title)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
                Text(vm.isCaregiver
                     ? "Pide a la persona que cuidas un\ncódigo de invitación para vincularte."
                     : "Genera un código para que tu cuidador\no familiar pueda ver tu progreso.")
                    .font(AdaptTheme.Font.bodyText)
                    .foregroundStyle(AdaptTheme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showInvite = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: vm.isCaregiver ? "person.badge.plus" : "qrcode")
                    Text(vm.isCaregiver ? "Aceptar invitación" : "Generar código")
                }
            }
            .buttonStyle(AdaptPrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Content

    private var content: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: AdaptTheme.Spacing.md) {
                if vm.isCaregiver {
                    patientsSection
                } else {
                    myCaregiversSection
                    pendingInvitesSection
                }

                if let error = vm.errorMessage {
                    errorBanner(error)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Caregiver viewing patients

    private var patientsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdaptEyebrow("Personas que cuido")
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                let patients = vm.links.filter { $0.caregiverId != $0.userId }
                ForEach(patients) { link in
                    NavigationLink {
                        PatientDetailView(link: link, vm: vm)
                    } label: {
                        linkCard(link: link, showPatientName: true)
                    }
                    .buttonStyle(.plain)
                }

                if patients.isEmpty {
                    Text("Aún no tienes pacientes vinculados")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var myCaregiversSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            AdaptEyebrow("Mis cuidadores")
                .padding(.horizontal, 20)

            VStack(spacing: 10) {
                let active = vm.links.filter { $0.status == AppConstants.LinkStatus.active.rawValue }
                ForEach(active) { link in
                    linkCard(link: link, showPatientName: false)
                }

                if active.isEmpty {
                    Text("Aún no has vinculado ningún cuidador")
                        .font(AdaptTheme.Font.caption)
                        .foregroundStyle(AdaptTheme.Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var pendingInvitesSection: some View {
        let pending = vm.links.filter { $0.status == AppConstants.LinkStatus.pending.rawValue }
        return Group {
            if !pending.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    AdaptEyebrow("Invitaciones pendientes", color: AdaptTheme.Palette.warning)
                        .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        ForEach(pending) { link in
                            pendingInviteCard(link)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func pendingInviteCard(_ link: CaregiverLinkRow) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AdaptTheme.Palette.warning.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: "qrcode")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AdaptTheme.Palette.warning)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Código: \(link.inviteCode ?? "—")")
                    .font(AdaptTheme.Font.card)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)
                Text("Pendiente de aceptar")
                    .font(AdaptTheme.Font.caption)
                    .foregroundStyle(AdaptTheme.Palette.warning)
            }

            Spacer()

            Button {
                Task { await vm.revokeLink(link.id) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AdaptTheme.Palette.error)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle().fill(AdaptTheme.Palette.error.opacity(0.12))
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.md, style: .continuous)
                .fill(AdaptTheme.Color.surface)
        )
    }

    // MARK: - Link card

    private func linkCard(link: CaregiverLinkRow, showPatientName: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AdaptTheme.Gradient.primary)
                    .frame(width: 52, height: 52)
                Text(initials(link.profiles?.displayName ?? "?"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(link.profiles?.displayName ?? "Sin nombre")
                    .font(AdaptTheme.Font.card)
                    .foregroundStyle(AdaptTheme.Color.textPrimary)

                HStack(spacing: 6) {
                    if let rel = link.relationship, !rel.isEmpty {
                        AdaptChip(rel.capitalized, tint: AdaptTheme.Palette.primary)
                    }
                    statusChip(link.status)
                }

                permissionIcons(link)
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

    private func permissionIcons(_ link: CaregiverLinkRow) -> some View {
        HStack(spacing: 6) {
            if link.permViewActivity {
                permIcon("chart.bar.fill", tint: AdaptTheme.Palette.success)
            }
            if link.permViewLocation {
                permIcon("location.fill", tint: AdaptTheme.Palette.warning)
            }
            if link.permEditRoutines {
                permIcon("pencil", tint: AdaptTheme.Palette.family)
            }
            if link.permViewMedications {
                permIcon("pills.fill", tint: AdaptTheme.Palette.primary)
            }
            if link.permViewEmergency {
                permIcon("sos", tint: AdaptTheme.Palette.error)
            }
        }
    }

    private func permIcon(_ systemName: String, tint: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 18, height: 18)
            .background(Circle().fill(tint.opacity(0.12)))
    }

    private func statusChip(_ status: String) -> some View {
        let linkStatus = AppConstants.LinkStatus(rawValue: status)
        let label: String = switch linkStatus {
        case .active: "Activo"
        case .pending: "Pendiente"
        case .revoked, .none: "Revocado"
        }
        let color: Color = switch linkStatus {
        case .active: AdaptTheme.Palette.success
        case .pending: AdaptTheme.Palette.warning
        case .revoked, .none: AdaptTheme.Palette.error
        }
        return AdaptChip(label, tint: color)
    }

    private func initials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let result = parts.compactMap { $0.first.map(String.init) }.joined()
        return result.isEmpty ? "?" : result.uppercased()
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AdaptTheme.Palette.error)
            Text(message)
                .font(AdaptTheme.Font.caption)
                .foregroundStyle(AdaptTheme.Color.textSecondary)
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AdaptTheme.Radius.sm, style: .continuous)
                .fill(AdaptTheme.Palette.error.opacity(0.12))
        )
    }
}
