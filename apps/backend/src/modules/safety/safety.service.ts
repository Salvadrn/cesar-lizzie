import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SafetyZone } from './entities/safety-zone.entity';
import { EmergencyContact } from './entities/emergency-contact.entity';
import { AlertsService } from '../alerts/alerts.service';

@Injectable()
export class SafetyService {
  constructor(
    @InjectRepository(SafetyZone)
    private zoneRepo: Repository<SafetyZone>,
    @InjectRepository(EmergencyContact)
    private contactRepo: Repository<EmergencyContact>,
    private alertsService: AlertsService,
  ) {}

  // Safety Zones
  async getZones(userId: string) {
    return this.zoneRepo.find({ where: { userId, isActive: true } });
  }

  async createZone(userId: string, data: Partial<SafetyZone>) {
    const zone = this.zoneRepo.create({ ...data, userId });
    return this.zoneRepo.save(zone);
  }

  async updateZone(id: string, data: Partial<SafetyZone>) {
    const zone = await this.zoneRepo.findOne({ where: { id } });
    if (!zone) throw new NotFoundException('Safety zone not found');
    Object.assign(zone, data);
    return this.zoneRepo.save(zone);
  }

  async deleteZone(id: string) {
    await this.zoneRepo.delete(id);
  }

  // Geofence check
  async checkLocation(userId: string, lat: number, lng: number) {
    const zones = await this.getZones(userId);
    const alerts: string[] = [];

    for (const zone of zones) {
      const distance = this.haversineDistance(lat, lng, zone.latitude, zone.longitude);
      const isInside = distance <= zone.radiusMeters;

      if (zone.alertOnExit && !isInside) {
        // Don't write the patient's exact coordinates into the alert
        // metadata — only the zone reference + distance from the boundary.
        // Caregivers querying alerts get enough context without leaking
        // precise location to anyone with read access to alerts.
        await this.alertsService.create({
          userId,
          alertType: 'geofence_exit',
          severity: 'critical',
          title: `Left safe zone: ${zone.name}`,
          metadata: { zoneId: zone.id, distanceMeters: Math.round(distance) },
        });
        alerts.push(`exited:${zone.name}`);
      }

      if (zone.alertOnEnter && isInside) {
        await this.alertsService.create({
          userId,
          alertType: 'geofence_enter',
          severity: 'info',
          title: `Entered zone: ${zone.name}`,
          metadata: { zoneId: zone.id },
        });
        alerts.push(`entered:${zone.name}`);
      }
    }

    return { checked: zones.length, alerts };
  }

  // Emergency
  async triggerEmergency(userId: string, lat?: number, lng?: number) {
    await this.alertsService.create({
      userId,
      alertType: 'emergency_activated',
      severity: 'critical',
      title: 'Emergency activated!',
      metadata: { lat, lng },
    });

    const contacts = await this.getEmergencyContacts(userId);
    return { contacts, alertSent: true };
  }

  async activateLostMode(userId: string, lat?: number, lng?: number) {
    await this.alertsService.create({
      userId,
      alertType: 'lost_mode_activated',
      severity: 'critical',
      title: 'Lost mode activated',
      metadata: { lat, lng },
    });
  }

  // Emergency contacts
  async getEmergencyContacts(userId: string) {
    return this.contactRepo.find({
      where: { userId },
      order: { priorityOrder: 'ASC' },
    });
  }

  async addContact(userId: string, data: Partial<EmergencyContact>) {
    const contact = this.contactRepo.create({ ...data, userId });
    return this.contactRepo.save(contact);
  }

  async deleteContact(id: string) {
    await this.contactRepo.delete(id);
  }

  // Haversine formula for distance calculation
  private haversineDistance(
    lat1: number, lon1: number,
    lat2: number, lon2: number,
  ): number {
    const R = 6371000; // Earth radius in meters
    const dLat = this.toRad(lat2 - lat1);
    const dLon = this.toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(lat1)) *
        Math.cos(this.toRad(lat2)) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private toRad(deg: number): number {
    return (deg * Math.PI) / 180;
  }
}
