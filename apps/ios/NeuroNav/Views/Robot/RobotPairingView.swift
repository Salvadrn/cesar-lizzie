import SwiftUI
import AVFoundation
import NeuroNavKit

struct RobotPairingView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var isPairing = false
    @State private var pairResult: PairResult?
    @State private var showScanner = true

    enum PairResult {
        case success(name: String)
        case error(String)
    }

    var body: some View {
        VStack(spacing: 24) {
            if let result = pairResult {
                resultView(result)
            } else if showScanner {
                scannerView
            }
        }
        .navigationTitle("Vincular Robot")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Scanner

    private var scannerView: some View {
        VStack(spacing: 20) {
            Text("Escanea el codigo QR del robot")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Text("Busca el codigo QR en tu robot Adapt AI y apunta la camara hacia el.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            RobotQRScannerView { code in
                handleQRCode(code)
            }
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "#4078DA"), lineWidth: 3)
            )
            .padding(.horizontal)

            if isPairing {
                ProgressView("Vinculando...")
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Result

    private func resultView(_ result: PairResult) -> some View {
        VStack(spacing: 20) {
            switch result {
            case .success(let name):
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.green)
                Text("Robot vinculado")
                    .font(.title2.bold())
                Text("Tu robot \"\(name)\" esta conectado y listo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Continuar") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#4078DA"))

            case .error(let msg):
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                Text("Error al vincular")
                    .font(.title2.bold())
                Text(msg)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Intentar de nuevo") {
                    pairResult = nil
                    showScanner = true
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#4078DA"))
            }
        }
        .padding()
    }

    // MARK: - Handle QR

    private func handleQRCode(_ code: String) {
        guard !isPairing else { return }

        // Parse: adaptai://pair?sn=SERIAL&code=CODE
        guard code.hasPrefix("adaptai://pair"),
              let url = URL(string: code),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sn = components.queryItems?.first(where: { $0.name == "sn" })?.value,
              let pairingCode = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            pairResult = .error("Codigo QR no valido. Asegurate de escanear el QR de un robot Adapt AI.")
            showScanner = false
            return
        }

        showScanner = false
        isPairing = true

        Task {
            do {
                let robot = try await APIClient.shared.pairRobot(serialNumber: sn, pairingCode: pairingCode)
                pairResult = .success(name: robot.name)
                await RobotViewModel.shared.fetchRobot()
            } catch {
                pairResult = .error("No se pudo vincular. Verifica que el QR sea correcto e intenta de nuevo.")
            }
            isPairing = false
        }
    }
}

// MARK: - QR Scanner Camera View

struct RobotQRScannerView: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> RobotRobotQRScannerVC {
        let vc = RobotRobotQRScannerVC()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: RobotRobotQRScannerVC, context: Context) {}
}

class RobotRobotQRScannerVC: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var hasScanned = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    private func setupCamera() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showPlaceholder()
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        captureSession = session

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func showPlaceholder() {
        let label = UILabel()
        label.text = "Camara no disponible\n(Simulador)"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.frame = view.bounds
        view.addSubview(label)
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !hasScanned,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let code = object.stringValue else { return }

        hasScanned = true
        captureSession?.stopRunning()

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        onCodeScanned?(code)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}

// MARK: - Color hex extension

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
