import SwiftUI
import NeuroNavKit

struct FamilyView: View {
    @State private var vm = FamilyViewModel()
    @State private var showInvite = false

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Cargando vínculos...")
            } else if vm.links.isEmpty {
                emptyState
            } else {
                linksList
            }
        }
        .navigationTitle("Familia")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showInvite = true
                } label: {
                    Image(systemName: vm.isCaregiver ? "person.badge.plus" : "qrcode")
                }
            }
        }
        .sheet(isPresented: $showInvite) {
            InviteCodeView(vm: vm)
        }
        .task { await vm.fetchLinks() }
        .refreshable { await vm.fetchLinks() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Sin vínculos familiares", systemImage: "person.2.slash")
        } description: {
            if vm.isCaregiver {
                Text("Pide a la persona que cuidas que genere un código de invitación y acéptalo aquí.")
            } else {
                Text("Genera un código de invitación para que tu cuidador o familiar pueda ver tu progreso.")
            }
        } actions: {
            Button {
                showInvite = true
            } label: {
                if vm.isCaregiver {
                    Label("Aceptar invitación", systemImage: "person.badge.plus")
                } else {
                    Label("Generar código", systemImage: "qrcode")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Links List

    private var linksList: some View {
        List {
            if vm.isCaregiver {
                Section("Personas que cuido") {
                    ForEach(vm.links.filter { $0.caregiverId != $0.userId }) { link in
                        NavigationLink {
                            PatientDetailView(link: link, vm: vm)
                        } label: {
                            linkRow(link: link, showPatientName: true)
                        }
                    }
                }
            }

            if !vm.isCaregiver {
                Section("Mis cuidadores") {
                    ForEach(vm.links.filter { $0.status == "active" }) { link in
                        linkRow(link: link, showPatientName: false)
                    }
                }

                if vm.links.contains(where: { $0.status == "pending" }) {
                    Section("Invitaciones pendientes") {
                        ForEach(vm.links.filter { $0.status == "pending" }) { link in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Código: \(link.inviteCode ?? "—")")
                                        .font(.headline.monospaced())
                                    Text("Pendiente de aceptar")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                }
                                Spacer()
                                Button("Cancelar", role: .destructive) {
                                    Task { await vm.revokeLink(link.id) }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }

            if let error = vm.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.callout)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func linkRow(link: CaregiverLinkRow, showPatientName: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.title)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(link.profiles?.displayName ?? "Sin nombre")
                    .font(.headline)

                HStack(spacing: 8) {
                    if let rel = link.relationship, !rel.isEmpty {
                        Text(rel.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    statusBadge(link.status)
                }
            }

            Spacer()

            // Permission icons
            HStack(spacing: 4) {
                if link.permViewActivity {
                    Image(systemName: "chart.bar.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                if link.permViewLocation {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                if link.permEditRoutines {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
                if link.permViewMedications {
                    Image(systemName: "pills.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
                if link.permViewEmergency {
                    Image(systemName: "sos.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status == "active" ? "Activo" : status == "pending" ? "Pendiente" : "Revocado")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(status == "active" ? .green.opacity(0.15) : status == "pending" ? .orange.opacity(0.15) : .red.opacity(0.15))
            .foregroundStyle(status == "active" ? .green : status == "pending" ? .orange : .red)
            .clipShape(Capsule())
    }
}
