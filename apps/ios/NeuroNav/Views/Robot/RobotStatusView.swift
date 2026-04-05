import SwiftUI

struct RobotStatusView: View {
    @State private var vm = RobotViewModel.shared

    var body: some View {
        ScrollView {
            if !vm.hasRobot {
                noRobotView
            } else {
                VStack(spacing: 20) {
                    statusHeader
                    jarvisChatButton
                    telemetryGrid
                    controlButtons
                    configSection
                }
                .padding()
            }
        }
        .navigationTitle("Robot")
        .task {
            await vm.fetchRobot()
        }
        .refreshable {
            await vm.fetchRobot()
        }
    }

    // MARK: - No Robot

    private var noRobotView: some View {
        VStack(spacing: 24) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            Text("Sin robot conectado")
                .font(.title2.bold())
            Text("Escanea el codigo QR de tu robot Adapt AI para vincularlo.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            NavigationLink {
                RobotPairingView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.title2)
                    Text("Escanear QR del Robot")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.white)
                .background(Color(red: 0.25, green: 0.47, blue: 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 40)
        }
        .padding(.top, 60)
    }

    // MARK: - Status Header

    private var statusHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.robotName)
                    .font(.title2.bold())
                Text(vm.state.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(vm.stateColor)
                    .clipShape(Capsule())
            }
            Spacer()
            Image(systemName: vm.stateEmoji)
                .font(.system(size: 44))
                .foregroundStyle(vm.stateColor)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - JARVIS Chat

    private var jarvisChatButton: some View {
        NavigationLink {
            RobotChatView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "mic.circle.fill")
                    .font(.title)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text("Hablar con JARVIS")
                        .font(.headline)
                    Text("Pregunta sobre tus medicamentos y rutinas")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Telemetry

    private var telemetryGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            statCard(title: "Bateria", value: "\(Int(vm.batteryPercent))%",
                     icon: "battery.100", alert: vm.batteryPercent < 20)
            statCard(title: "Distancia", value: vm.bleDistance.map { String(format: "%.1f m", $0) } ?? "--",
                     icon: "figure.walk", alert: false)
            statCard(title: "Target", value: vm.bleTargetFound ? "Encontrado" : "Perdido",
                     icon: "antenna.radiowaves.left.and.right", alert: !vm.bleTargetFound)
            statCard(title: "Obstaculo", value: vm.lidarNearest.map { String(format: "%.1f m", $0 / 1000) } ?? "--",
                     icon: "sensor.fill", alert: false)
            statCard(title: "Velocidad", value: String(format: "%.2f", vm.motorSpeed),
                     icon: "speedometer", alert: false)
            statCard(title: "CPU", value: String(format: "%.0f C", vm.cpuTemp),
                     icon: "thermometer.medium", alert: vm.cpuTemp > 75)
        }
    }

    private func statCard(title: String, value: String, icon: String, alert: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(alert ? .red : .secondary)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(alert ? .red : .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(alert ? Color.red.opacity(0.08) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Controls

    private var controlButtons: some View {
        VStack(spacing: 12) {
            Text("CONTROLES")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                controlButton("Iniciar", icon: "play.fill", color: .green) {
                    Task { await vm.sendCommand("start") }
                }
                controlButton("Pausar", icon: "pause.fill", color: .yellow) {
                    Task { await vm.sendCommand("pause") }
                }
                controlButton("Reanudar", icon: "arrow.clockwise", color: .blue) {
                    Task { await vm.sendCommand("resume") }
                }
            }

            HStack(spacing: 12) {
                controlButton("Detener", icon: "stop.fill", color: .gray) {
                    Task { await vm.sendCommand("stop") }
                }
                controlButton("EMERGENCIA", icon: "exclamationmark.octagon.fill", color: .red) {
                    Task { await vm.sendCommand("emergency_stop") }
                }
            }
        }
    }

    private func controlButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Config

    private var configSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONFIGURACION")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            HStack {
                Text("Distancia de seguimiento")
                Spacer()
                Text("\(vm.followDistance, specifier: "%.1f") m")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Velocidad maxima")
                Spacer()
                Text("\(vm.maxSpeed, specifier: "%.1f")")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Parada de emergencia")
                Spacer()
                Text("\(vm.emergencyStopCm) cm")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("LiDAR")
                Spacer()
                Text(vm.lidarEnabled ? "Activo" : "Inactivo")
                    .foregroundStyle(vm.lidarEnabled ? .green : .secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
