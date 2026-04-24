import Foundation
import CoreLocation
import UIKit
import AdaptAiKit

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var monitoredZones: [NNSafetyZone] = []

    /// When true, publishes throttled location pings to Supabase so caregivers
    /// can see the patient's location in real time. User can disable in Settings.
    var publishLiveLocation = true

    // Throttling — upload at most once every 30s OR when user moves >20m
    private var lastPublishedAt: Date = .distantPast
    private var lastPublishedLocation: CLLocation?
    private let publishMinIntervalSec: TimeInterval = 30
    private let publishMinDistanceMeters: CLLocationDistance = 20

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorization() {
        manager.requestAlwaysAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Geofencing

    func startMonitoring(zones: [NNSafetyZone]) {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredZones = zones

        for zone in zones where zone.isActive {
            let region = CLCircularRegion(
                center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
                radius: zone.radiusMeters,
                identifier: zone.id
            )
            region.notifyOnExit = zone.alertOnExit
            region.notifyOnEntry = zone.alertOnEnter
            manager.startMonitoring(for: region)
        }
    }

    func loadAndMonitorZones() async {
        do {
            let zoneResponses = try await APIClient.shared.fetchSafetyZones()
            let zones = zoneResponses.map { resp in
                NNSafetyZone(
                    id: resp.id,
                    userId: resp.userId,
                    name: resp.name,
                    latitude: resp.latitude,
                    longitude: resp.longitude,
                    radiusMeters: resp.radiusMeters,
                    zoneType: resp.zoneType,
                    alertOnExit: resp.alertOnExit,
                    alertOnEnter: resp.alertOnEnter,
                    isActive: resp.isActive
                )
            }
            startMonitoring(zones: zones)
        } catch {
            print("LocationService: failed to load zones: \(error)")
        }
    }

    func stopMonitoringAll() {
        for region in manager.monitoredRegions {
            manager.stopMonitoring(for: region)
        }
        monitoredZones = []
    }

    // MARK: - Distance

    func distance(from location: CLLocation, to zone: NNSafetyZone) -> Double {
        let zoneLocation = CLLocation(latitude: zone.latitude, longitude: zone.longitude)
        return location.distance(from: zoneLocation)
    }

    func isInsideZone(_ zone: NNSafetyZone) -> Bool {
        guard let location = currentLocation else { return false }
        return distance(from: location, to: zone) <= zone.radiusMeters
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        maybePublishLocation(location)
    }

    /// Throttled upload of current location to Supabase for caregiver tracking.
    private func maybePublishLocation(_ location: CLLocation) {
        guard publishLiveLocation else { return }
        let now = Date()

        let intervalOK = now.timeIntervalSince(lastPublishedAt) >= publishMinIntervalSec
        let movedEnough = lastPublishedLocation.map {
            $0.distance(from: location) >= publishMinDistanceMeters
        } ?? true

        guard intervalOK || movedEnough else { return }

        lastPublishedAt = now
        lastPublishedLocation = location

        let battery: Double? = {
            UIDevice.current.isBatteryMonitoringEnabled = true
            let level = UIDevice.current.batteryLevel
            return level >= 0 ? Double(level) * 100 : nil
        }()

        Task {
            try? await APIClient.shared.publishLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: location.horizontalAccuracy,
                batteryLevel: battery
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let zone = monitoredZones.first(where: { $0.id == region.identifier }) else { return }
        handleZoneEvent(event: "enter", zone: zone)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let zone = monitoredZones.first(where: { $0.id == region.identifier }) else { return }
        handleZoneEvent(event: "exit", zone: zone)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            startUpdatingLocation()
        }
    }

    // MARK: - Zone Event Handling

    private func handleZoneEvent(event: String, zone: NNSafetyZone) {
        NotificationService.shared.sendZoneAlert(zoneName: zone.name, event: event)

        Task {
            let alertType: AppConstants.AlertType = event == "exit" ? .zoneExit : .zoneEnter
            let severity: AppConstants.AlertSeverity = event == "exit" ? .high : .low
            try? await APIClient.shared.createAlert(
                type: alertType,
                severity: severity,
                title: event == "exit" ? "Salió de zona segura" : "Entró a zona",
                message: "Zona: \(zone.name)"
            )
        }
    }
}
