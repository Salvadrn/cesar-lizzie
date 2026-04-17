import SwiftUI
import AdaptAiKit

/// Lista de medicamentos estilo Assistive Access:
/// tarjetas grandes con hora y boton enorme para marcar como tomado.
struct SimpleMedicationView: View {
    @State private var vm = MedicationViewModel()

    private var pending: [MedicationViewModel.MedicationItem] {
        vm.medications.filter { !$0.takenToday }.sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    private var taken: [MedicationViewModel.MedicationItem] {
        vm.medications.filter { $0.takenToday }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if vm.isLoading {
                    ProgressView("Cargando...")
                        .font(.nnTitle2)
                        .padding(.top, 60)
                } else if vm.medications.isEmpty {
                    emptyView
                } else {
                    if !pending.isEmpty {
                        sectionHeader("Para tomar", color: .orange)
                        ForEach(pending) { med in
                            medicationCard(med, isTaken: false)
                        }
                    }

                    if !taken.isEmpty {
                        sectionHeader("Ya tomaste", color: .green)
                            .padding(.top, 20)
                        ForEach(taken) { med in
                            medicationCard(med, isTaken: true)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Medicamentos")
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 16, height: 16)
            Text(title)
                .font(.nnTitle2)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    private func medicationCard(_ med: MedicationViewModel.MedicationItem, isTaken: Bool) -> some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Icon or pill image
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(isTaken ? .green : .orange)
                    .frame(width: 80)

                VStack(alignment: .leading, spacing: 6) {
                    Text(med.name)
                        .font(.nnTitle)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text(med.dosage)
                        .font(.nnTitle3)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.nnTitle3)
                        Text(med.scheduledTime)
                            .font(.nnTitle2)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(isTaken ? .green : .orange)
                }

                Spacer()
            }

            if !isTaken {
                Button {
                    Task {
                        try? await APIClient.shared.markMedicationTaken(id: med.id)
                        await vm.load()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                        Text("Ya la tomé")
                            .font(.nnTitle2)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                    Text("Tomada hoy")
                        .font(.nnTitle3)
                }
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("Aún no tienes medicamentos")
                .font(.nnTitle2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
}
