export type ZoneType = 'safe' | 'restricted';

export interface SafetyZone {
  id: string;
  userId: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  zoneType: ZoneType;
  alertOnExit: boolean;
  alertOnEnter: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface EmergencyContact {
  id: string;
  userId: string;
  name: string;
  phone: string;
  relationship?: string;
  isPrimary: boolean;
  priorityOrder: number;
  createdAt: string;
}

export interface LocationReport {
  userId: string;
  latitude: number;
  longitude: number;
  timestamp: string;
}
