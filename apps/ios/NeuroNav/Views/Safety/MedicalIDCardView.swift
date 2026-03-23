import SwiftUI
import CoreImage.CIFilterBuiltins
import NeuroNavKit

struct MedicalIDCardView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.colorScheme) private var colorScheme
    @State private var emergencyContacts: [EmergencyContactResponse] = []
    @State private var isLoading = true
    @State private var showShareSheet = false
    @State private var cardImage: UIImage?

    // Patient profile data (from AppStorage, same as PatientProfileView)
    @AppStorage("patient_age") private var age: String = ""
    @AppStorage("patient_blood_type") private var bloodType: String = ""
    @AppStorage("patient_allergies") private var allergies: String = ""
    @AppStorage("patient_conditions") private var conditions: String = ""
    @AppStorage("patient_emergency_notes") private var emergencyNotes: String = ""
    @AppStorage("patient_doctor_name") private var doctorName: String = ""
    @AppStorage("patient_doctor_phone") private var doctorPhone: String = ""

    private var isDark: Bool { colorScheme == .dark }
    private var displayName: String {
        authService.currentProfile?.displayName ?? "Paciente"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // The card
                cardView
                    .shadow(color: .black.opacity(0.15), radius: 16, y: 8)

                // Actions
                HStack(spacing: 12) {
                    Button {
                        renderAndShare()
                    } label: {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                            .font(.nnHeadline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.nnPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        renderAndSaveToPhotos()
                    } label: {
                        Label("Guardar", systemImage: "photo.badge.arrow.down")
                            .font(.nnHeadline)
                            .foregroundStyle(.nnPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(Color.nnPrimary.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                Text("Esta tarjeta contiene información médica importante.\nCompártela con tus cuidadores o imprímela para tu cartera.")
                    .font(.nnCaption)
                    .foregroundStyle(.nnMidGray)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
        .navigationTitle("Tarjeta Médica")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadContacts()
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = cardImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Card View

    private var cardView: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "cross.case.fill")
                            .font(.system(size: 14))
                        Text("TARJETA MÉDICA")
                            .font(.nnCaption)
                            .fontWeight(.bold)
                            .tracking(1.5)
                    }
                    .foregroundStyle(.white.opacity(0.8))

                    Text(displayName)
                        .font(.nnTitle)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                // QR code with patient ID
                if let userId = authService.userId,
                   let qr = generateQRCode(from: "adaptai://medical-id/\(userId.uuidString)") {
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.nnPrimary, Color.nnPrimary.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Body
            VStack(spacing: 14) {
                // Basic info row
                HStack(spacing: 16) {
                    if !age.isEmpty {
                        infoChip(icon: "calendar", label: "Edad", value: "\(age) años")
                    }
                    if !bloodType.isEmpty {
                        infoChip(icon: "drop.fill", label: "Sangre", value: bloodType)
                    }
                    Spacer()
                }

                Divider()

                // Allergies
                if !allergies.isEmpty {
                    cardField(icon: "exclamationmark.triangle.fill", label: "ALERGIAS", value: allergies, color: .nnError)
                }

                // Conditions
                if !conditions.isEmpty {
                    cardField(icon: "heart.text.clipboard", label: "CONDICIONES", value: conditions, color: .nnWarning)
                }

                // Emergency notes
                if !emergencyNotes.isEmpty {
                    cardField(icon: "doc.text.fill", label: "NOTAS DE EMERGENCIA", value: emergencyNotes, color: .nnPrimary)
                }

                Divider()

                // Emergency contact
                if let contact = emergencyContacts.first {
                    HStack(spacing: 10) {
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.nnSuccess)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("CONTACTO DE EMERGENCIA")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(.nnMidGray)
                            Text(contact.name)
                                .font(.nnSubheadline)
                                .fontWeight(.semibold)
                            Text(contact.phone)
                                .font(.nnCaption)
                                .foregroundStyle(.nnMidGray)
                        }

                        Spacer()

                        if !contact.relationship.isEmpty {
                            Text(contact.relationship)
                                .font(.nnCaption2)
                                .foregroundStyle(.nnPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.nnPrimary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                // Doctor
                if !doctorName.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "stethoscope.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("MÉDICO DE CABECERA")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(.nnMidGray)
                            Text(doctorName)
                                .font(.nnSubheadline)
                                .fontWeight(.semibold)
                            if !doctorPhone.isEmpty {
                                Text(doctorPhone)
                                    .font(.nnCaption)
                                    .foregroundStyle(.nnMidGray)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(.white)

            // Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "location.north.circle.fill")
                        .font(.system(size: 12))
                    Text("Adapt")
                        .fontWeight(.bold)
                    + Text("Ai")
                        .fontWeight(.bold)
                        .foregroundColor(.nnGold)
                }
                .font(.nnCaption2)
                .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("adaptai.app")
                    .font(.nnCaption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.nnDarkText)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Card Components

    private func infoChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.nnPrimary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.nnMidGray)
                Text(value)
                    .font(.nnSubheadline)
                    .fontWeight(.semibold)
            }
        }
    }

    private func cardField(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(.nnMidGray)
                Text(value)
                    .font(.nnCaption)
                    .foregroundStyle(.nnDarkText)
            }

            Spacer()
        }
    }

    // MARK: - QR Code

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - Share / Save

    @MainActor
    private func renderCardImage() -> UIImage? {
        let renderer = ImageRenderer(content:
            cardView
                .frame(width: 380)
                .padding(4)
                .environment(authService)
        )
        renderer.scale = 3.0
        return renderer.uiImage
    }

    private func renderAndShare() {
        guard let image = renderCardImage() else { return }
        cardImage = image
        showShareSheet = true
    }

    private func renderAndSaveToPhotos() {
        guard let image = renderCardImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    // MARK: - Data

    private func loadContacts() async {
        if authService.isGuestMode {
            isLoading = false
            return
        }

        do {
            emergencyContacts = try await APIClient.shared.fetchEmergencyContacts()
        } catch {
            print("Failed to load emergency contacts: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
