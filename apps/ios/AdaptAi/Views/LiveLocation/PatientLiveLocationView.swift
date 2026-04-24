import SwiftUI
import MapKit
import AdaptAiKit

/// Live location view for caregivers — shows patient's most recent location
/// on a map with a trail of past pings. Polls every 15 seconds.
struct PatientLiveLocationView: View {
    let patientId: String
    let patientName: String

    @Environment(\.colorScheme) private var colorScheme
    @State private var latestLocation: LocationUpdateRow?
    @State private var trail: [LocationUpdateRow] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var pollTimer: Timer?
    @State private var errorMessage: String?
    @State private var isLoading = true

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack(alignment: .top) {
            mapView
                .ignoresSafeArea(edges: .bottom)

            VStack(spacing: 0) {
                header
                Spacer()
                if let location = latestLocation {
                    infoCard(location)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                } else if let err = errorMessage {
                    errorCard(err)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                } else if isLoading {
                    ProgressView("Cargando ubicación...")
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Ubicación")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refresh()
            startPolling()
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    // MARK: - Map

    private var mapView: some View {
        Map(position: Binding(
            get: { MapCameraPosition.region(region) },
            set: { newPos in
                if let r = newPos.region { region = r }
            }
        )) {
            // Trail
            if trail.count > 1 {
                MapPolyline(coordinates: trail.reversed().map {
                    CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                })
                .stroke(Color.nnPrimary.opacity(0.6), lineWidth: 3)
            }

            // Latest position
            if let latest = latestLocation {
                Annotation(patientName, coordinate: CLLocationCoordinate2D(
                    latitude: latest.latitude,
                    longitude: latest.longitude
                )) {
                    patientPin
                }
            }
        }
    }

    private var patientPin: some View {
        ZStack {
            Circle()
                .fill(Color.nnPrimary.opacity(0.3))
                .frame(width: 48, height: 48)

            Circle()
                .fill(Color.nnPrimary)
                .frame(width: 26, height: 26)

            Image(systemName: "person.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            liveDot
            Text("EN VIVO")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(.nnPrimary)
            Spacer()
            Button {
                Task { await refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.top, 8)
    }

    private var liveDot: some View {
        Circle()
            .fill(Color.nnSuccess)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Color.nnSuccess.opacity(0.4), lineWidth: 4)
                    .scaleEffect(1.6)
            )
    }

    // MARK: - Info card

    private func infoCard(_ location: LocationUpdateRow) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Última actualización".uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(.secondary)
                    Text(relativeTime(location.createdAt))
                        .font(.nnHeadline.weight(.bold))
                }
                Spacer()
                if let battery = location.batteryLevel {
                    batteryIndicator(level: battery)
                }
            }

            Divider()

            HStack(spacing: 12) {
                infoStat(
                    icon: "location.fill",
                    label: "Precisión",
                    value: location.accuracy.map { "\(Int($0)) m" } ?? "—"
                )
                Divider().frame(height: 30)
                infoStat(
                    icon: "mappin",
                    label: "Coordenadas",
                    value: String(format: "%.4f, %.4f", location.latitude, location.longitude)
                )
            }

            HStack(spacing: 10) {
                Button {
                    openInMaps(lat: location.latitude, lng: location.longitude)
                } label: {
                    Label("Abrir en Maps", systemImage: "map.fill")
                        .font(.nnSubheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.nnPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task { await refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundStyle(.nnPrimary)
                        .padding(10)
                        .background(Color.nnPrimary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(isDark ? 0 : 0.1), radius: 8, y: 4)
    }

    private func infoStat(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(label.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
            }
            .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func batteryIndicator(level: Double) -> some View {
        let color: Color = level > 20 ? .nnSuccess : .nnError
        return HStack(spacing: 4) {
            Image(systemName: "battery.100")
                .font(.system(size: 11))
            Text("\(Int(level))%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func errorCard(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.nnWarning)
            Text(msg).font(.nnCaption)
            Spacer()
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Actions

    private func refresh() async {
        errorMessage = nil
        do {
            let rows = try await APIClient.shared.fetchLocationTrail(patientId: patientId, limit: 20)
            trail = rows
            latestLocation = rows.first

            if let latest = rows.first {
                withAnimation(.easeOut(duration: 0.6)) {
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latest.latitude, longitude: latest.longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
            } else {
                errorMessage = "Sin ubicación registrada todavía. El paciente necesita abrir la app para enviar su ubicación."
            }
        } catch {
            errorMessage = "No se pudo cargar: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task { await refresh() }
        }
    }

    private func openInMaps(lat: Double, lng: Double) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)))
        item.name = patientName
        item.openInMaps()
    }

    private func relativeTime(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: iso)
            ?? { let f2 = ISO8601DateFormatter(); return f2.date(from: iso) }()
            ?? Date()

        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "Hace \(seconds)s" }
        if seconds < 3600 { return "Hace \(seconds / 60) min" }
        if seconds < 86400 { return "Hace \(seconds / 3600) h" }
        return "Hace \(seconds / 86400) d"
    }
}
