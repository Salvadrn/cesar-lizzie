import SwiftUI
import NeuroNavKit

struct PatientDetailView: View {
    let link: CaregiverLinkRow
    @Bindable var vm: FamilyViewModel

    var body: some View {
        Group {
            if vm.isLoadingPatient {
                ProgressView("Cargando datos...")
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        profileCard

                        // Quick action buttons
                        actionButtons

                        if link.permViewActivity {
                            recentActivitySection
                            alertsSection

                            // Trend analysis
                            NavigationLink {
                                TrendReportView(
                                    patientName: vm.patientProfile?.displayName ?? "Paciente",
                                    executions: vm.patientExecutions
                                )
                            } label: {
                                Label("Tendencias e Insights", systemImage: "chart.line.uptrend.xyaxis")
                                    .font(.nnHeadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.nnPrimary.opacity(0.1))
                                    .foregroundStyle(.nnPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        if link.permViewMedications {
                            NavigationLink {
                                PatientMedicationsView(
                                    patientId: link.userId,
                                    patientName: vm.patientProfile?.displayName ?? "Paciente"
                                )
                            } label: {
                                Label("Ver medicamentos", systemImage: "pills.fill")
                                    .font(.nnHeadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.nnSuccess.opacity(0.1))
                                    .foregroundStyle(.nnSuccess)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        if link.permViewLocation {
                            safetyZonesSection
                        }

                        // Caregiver notification preferences
                        NavigationLink {
                            CaregiverNotificationPreferencesView()
                        } label: {
                            Label("Notificaciones en tiempo real", systemImage: "bell.badge.waveform.fill")
                                .font(.nnHeadline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        permissionsSection

                        revokeSection
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(vm.patientProfile?.displayName ?? "Paciente")
        .navigationBarTitleDisplayMode(.large)
        .task {
            vm.clearPatientDetail()
            await vm.loadPatientDetail(link: link)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.blue)

            if let profile = vm.patientProfile {
                Text(profile.displayName.isEmpty ? "Sin nombre" : profile.displayName)
                    .font(.title2.bold())

                HStack(spacing: 20) {
                    statItem(
                        icon: "brain",
                        value: "\(profile.currentComplexity)",
                        label: "Nivel"
                    )
                    statItem(
                        icon: "eye",
                        value: profile.sensoryMode == "default" ? "Normal" : profile.sensoryMode == "lowStimulation" ? "Bajo" : "Alto",
                        label: "Modo"
                    )
                    statItem(
                        icon: "chart.line.uptrend.xyaxis",
                        value: "\(profile.totalSessions)",
                        label: "Sesiones"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if link.permViewActivity {
                NavigationLink {
                    CaregiverStatsView(link: link, vm: vm)
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                            .foregroundStyle(.nnPrimary)
                        Text("Estadísticas")
                            .font(.nnCaption)
                            .foregroundStyle(.nnDarkText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.nnPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                CaregiverRemindersView(
                    patientId: link.userId,
                    patientName: vm.patientProfile?.displayName ?? "Paciente"
                )
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "bell.badge.fill")
                        .font(.title2)
                        .foregroundStyle(.nnWarning)
                    Text("Recordatorios")
                        .font(.nnCaption)
                        .foregroundStyle(.nnDarkText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.nnWarning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Actividad reciente", systemImage: "chart.bar.fill")
                .font(.headline)

            if vm.patientExecutions.isEmpty {
                Text("Sin actividad registrada")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(vm.patientExecutions.prefix(5)) { exec in
                    HStack {
                        Image(systemName: exec.status == "completed" ? "checkmark.circle.fill" : exec.status == "abandoned" ? "xmark.circle.fill" : "clock.fill")
                            .foregroundStyle(exec.status == "completed" ? .green : exec.status == "abandoned" ? .red : .orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rutina")
                                .font(.subheadline.weight(.medium))
                            Text("\(exec.completedSteps)/\(exec.totalSteps) pasos · \(exec.errorCount) errores")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(formatDate(exec.startedAt))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alertas", systemImage: "bell.fill")
                .font(.headline)

            if vm.patientAlerts.isEmpty {
                Text("Sin alertas recientes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(vm.patientAlerts.prefix(5)) { alert in
                    HStack {
                        Image(systemName: alert.severity == "critical" ? "exclamationmark.triangle.fill" : alert.severity == "warning" ? "exclamationmark.circle.fill" : "info.circle.fill")
                            .foregroundStyle(alert.severity == "critical" ? .red : alert.severity == "warning" ? .orange : .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title)
                                .font(.subheadline.weight(.medium))
                            if let msg = alert.message {
                                Text(msg)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()

                        Text(formatDate(alert.createdAt))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Safety Zones

    private var safetyZonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Zonas seguras", systemImage: "mappin.and.ellipse")
                .font(.headline)

            if vm.patientZones.isEmpty {
                Text("Sin zonas configuradas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(vm.patientZones) { zone in
                    HStack {
                        Image(systemName: zoneIcon(zone.zoneType))
                            .foregroundStyle(.orange)
                            .frame(width: 30)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.subheadline.weight(.medium))
                            Text("\(Int(zone.radiusMeters))m · \(zone.zoneType.capitalized)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if zone.alertOnExit {
                            Image(systemName: "arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        if zone.alertOnEnter {
                            Image(systemName: "arrow.left.circle")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Permissions Info

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tus permisos", systemImage: "lock.shield")
                .font(.headline)

            permRow(icon: "chart.bar.fill", label: "Ver actividad", enabled: link.permViewActivity)
            permRow(icon: "pencil", label: "Editar rutinas", enabled: link.permEditRoutines)
            permRow(icon: "location.fill", label: "Ver ubicación", enabled: link.permViewLocation)
            permRow(icon: "pills.fill", label: "Ver medicamentos", enabled: link.permViewMedications)
            permRow(icon: "sos.circle.fill", label: "Ver emergencias", enabled: link.permViewEmergency)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func permRow(icon: String, label: String, enabled: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(enabled ? .green : .gray)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundStyle(enabled ? .green : .gray)
        }
    }

    // MARK: - Revoke

    private var revokeSection: some View {
        Button("Desvincular paciente", role: .destructive) {
            Task {
                await vm.revokeLink(link.id)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Helpers

    private func formatDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else {
            // Try without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            guard let date = formatter.date(from: dateStr) else { return dateStr }
            return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
        }
        return RelativeDateTimeFormatter().localizedString(for: date, relativeTo: Date())
    }

    private func zoneIcon(_ type: String) -> String {
        switch type {
        case "home": return "house.fill"
        case "school": return "building.columns.fill"
        case "work": return "briefcase.fill"
        case "medical": return "cross.case.fill"
        default: return "mappin"
        }
    }
}
