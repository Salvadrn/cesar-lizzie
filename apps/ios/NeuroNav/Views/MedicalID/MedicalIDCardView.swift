import SwiftUI
import NeuroNavKit

struct MedicalIDCardView: View {
    @State private var medicalID: MedicalIDRow?
    @State private var isLoading = true
    @State private var showEditor = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView("Cargando...")
                    .padding(.top, 60)
            } else if let id = medicalID {
                cardView(id)
            } else {
                emptyView
            }
        }
        .navigationTitle("Credencial Medica")
        .toolbar {
            if medicalID != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Editar") { showEditor = true }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                MedicalIDEditView(medicalID: $medicalID)
            }
        }
        .task { await loadMedicalID() }
    }

    // MARK: - Card

    private func cardView(_ id: MedicalIDRow) -> some View {
        VStack(spacing: 0) {
            // Header - looks like a wallet card
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "cross.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Text("CREDENCIAL MEDICA")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.9))
                        .tracking(2)
                    Spacer()
                    Text("Adapt Ai")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(id.fullName)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        if let dob = id.dateOfBirth {
                            Text("Nacimiento: \(dob)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    if let bt = id.bloodType, !bt.isEmpty {
                        VStack(spacing: 2) {
                            Text("SANGRE")
                                .font(.system(size: 8).bold())
                                .foregroundStyle(.white.opacity(0.6))
                            Text(bt)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.25, green: 0.47, blue: 0.85), Color(red: 0.18, green: 0.35, blue: 0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Body
            VStack(spacing: 16) {
                // Physical info
                if id.weight != nil || id.height != nil {
                    HStack(spacing: 20) {
                        if let w = id.weight {
                            infoChip(label: "Peso", value: "\(Int(w)) kg")
                        }
                        if let h = id.height {
                            infoChip(label: "Estatura", value: "\(Int(h)) cm")
                        }
                        if id.organDonor {
                            infoChip(label: "Donador", value: "Si", color: .green)
                        }
                    }
                    .padding(.top, 4)
                }

                // Allergies
                if !id.allergies.isEmpty {
                    sectionView(title: "Alergias", icon: "exclamationmark.triangle.fill", color: .red) {
                        FlowLayout(spacing: 6) {
                            ForEach(id.allergies, id: \.self) { allergy in
                                tag(allergy, color: .red)
                            }
                        }
                    }
                }

                // Conditions
                if !id.conditions.isEmpty {
                    sectionView(title: "Condiciones", icon: "heart.text.clipboard", color: .orange) {
                        FlowLayout(spacing: 6) {
                            ForEach(id.conditions, id: \.self) { condition in
                                tag(condition, color: .orange)
                            }
                        }
                    }
                }

                // Current Medications
                if !id.currentMedications.isEmpty {
                    sectionView(title: "Medicamentos Actuales", icon: "pills.fill", color: .blue) {
                        FlowLayout(spacing: 6) {
                            ForEach(id.currentMedications, id: \.self) { med in
                                tag(med, color: .blue)
                            }
                        }
                    }
                }

                // Doctor
                if let doc = id.doctorName, !doc.isEmpty {
                    sectionView(title: "Doctor", icon: "stethoscope", color: .green) {
                        HStack {
                            Text(doc)
                                .font(.nnBody)
                            Spacer()
                            if let phone = id.doctorPhone, !phone.isEmpty,
                               let url = URL(string: "tel://\(phone)") {
                                Link(destination: url) {
                                    Image(systemName: "phone.fill")
                                        .foregroundStyle(.green)
                                        .padding(8)
                                        .background(.green.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                    }
                }

                // Insurance
                if let ins = id.insuranceProvider, !ins.isEmpty {
                    sectionView(title: "Seguro Medico", icon: "shield.checkered", color: .purple) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ins).font(.nnBody)
                            if let num = id.insuranceNumber, !num.isEmpty {
                                Text("No. \(num)")
                                    .font(.nnCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Notes
                if let notes = id.notes, !notes.isEmpty {
                    sectionView(title: "Notas", icon: "note.text", color: .gray) {
                        Text(notes)
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cross.circle")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
            Text("Sin credencial medica")
                .font(.title3.bold())
            Text("Crea tu credencial con tu informacion medica importante para emergencias.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showEditor = true
            } label: {
                Label("Crear Credencial", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .foregroundStyle(.white)
                    .background(Color(red: 0.25, green: 0.47, blue: 0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }

    // MARK: - Helpers

    private func sectionView<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .tracking(1)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tag(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.nnCaption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func infoChip(label: String, value: String, color: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9).bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.nnHeadline)
                .foregroundStyle(color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func loadMedicalID() async {
        do {
            medicalID = try await APIClient.shared.fetchMedicalID()
        } catch {
            // No medical ID yet
        }
        isLoading = false
    }
}

// MARK: - FlowLayout (simple horizontal wrapping)

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
