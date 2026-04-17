import SwiftUI
import CoreImage.CIFilterBuiltins
import VisionKit
import AdaptAiKit

struct InviteCodeView: View {
    @Bindable var vm: FamilyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                if vm.isCaregiver {
                    caregiverAcceptView
                } else {
                    userGenerateView
                }

                Spacer()

                if let error = vm.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.nnCallout)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle(vm.isCaregiver ? "Aceptar invitación" : "Invitar cuidador")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - User: Generate code + QR

    private var userGenerateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Genera un código para que tu cuidador o familiar se vincule contigo")
                .font(.nnBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let code = vm.generatedCode {
                VStack(spacing: 16) {
                    // QR Code image
                    if let qrImage = generateQRCode(from: code) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("Tu código:")
                        .font(.nnSubheadline)
                        .foregroundStyle(.secondary)

                    Text(code)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .tracking(4)
                        .foregroundStyle(.blue)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.blue.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text("Muestra el QR o comparte el código con tu cuidador")
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        UIPasteboard.general.string = code
                    } label: {
                        Label("Copiar código", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button {
                    Task { await vm.generateInvite() }
                } label: {
                    if vm.isGenerating {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Generar código")
                            .font(.nnHeadline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(vm.isGenerating)
            }
        }
    }

    // MARK: - Caregiver: Accept code (manual + QR scan)

    @State private var showScanner = false

    private var caregiverAcceptView: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.2.badge.gearshape.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Ingresa el código o escanea el QR")
                .font(.nnBody)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // QR Scanner button
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                Button {
                    showScanner = true
                } label: {
                    Label("Escanear QR", systemImage: "qrcode.viewfinder")
                        .font(.nnHeadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .sheet(isPresented: $showScanner) {
                    QRScannerView { scannedCode in
                        vm.acceptCode = scannedCode
                        showScanner = false
                        Task {
                            await vm.acceptInvite()
                            if vm.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                }
            }

            // Divider
            HStack {
                Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
                Text("o escribe el código")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
                Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1)
            }

            TextField("Código de invitación", text: $vm.acceptCode)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                Task {
                    await vm.acceptInvite()
                    if vm.errorMessage == nil {
                        dismiss()
                    }
                }
            } label: {
                if vm.isAccepting {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Aceptar invitación")
                        .font(.nnHeadline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(vm.acceptCode.trimmingCharacters(in: .whitespaces).isEmpty || vm.isAccepting)
        }
    }

    // MARK: - QR Generation

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = 10.0
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - QR Scanner (VisionKit DataScanner)

struct QRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onCodeScanned: (String) -> Void
        private var hasScanned = false

        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            guard !hasScanned else { return }
            if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                hasScanned = true
                onCodeScanned(value)
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let value = barcode.payloadStringValue {
                    hasScanned = true
                    onCodeScanned(value)
                    return
                }
            }
        }
    }
}
