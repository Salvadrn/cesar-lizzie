export type UserRole = 'user' | 'caregiver' | 'admin';

export type SensoryMode = 'default' | 'low_stimulation' | 'high_contrast';

export type PreferredInput = 'touch' | 'voice' | 'switch';

export interface User {
  id: string;
  email: string;
  role: UserRole;
  displayName: string;
  avatarUrl?: string;
  isActive: boolean;
  lastLoginAt?: string;
  createdAt: string;
  updatedAt: string;
}

export interface UserProfile {
  id: string;
  userId: string;

  // Adaptive engine state
  currentComplexity: number; // 1-5
  avgErrorRate: number;
  avgCompletionTime: number;
  avgTaskCompletion: number;
  totalSessions: number;

  // Sensory preferences
  sensoryMode: SensoryMode;
  hapticEnabled: boolean;
  hapticIntensity: number; // 1-5
  audioEnabled: boolean;
  audioSpeed: number;
  fontScale: number;
  animationEnabled: boolean;

  // Safety / Lost mode
  lostModeName?: string;
  lostModeAddress?: string;
  lostModePhone?: string;
  lostModePhotoUrl?: string;

  // Interface
  preferredInput: PreferredInput;
  language: string;
}

export interface CaregiverLink {
  id: string;
  userId: string;
  caregiverId: string;
  relationship?: string;
  permissions: CaregiverPermissions;
  inviteCode?: string;
  status: 'pending' | 'active' | 'revoked';
  linkedAt?: string;
  createdAt: string;
}

export interface CaregiverPermissions {
  viewActivity: boolean;
  editRoutines: boolean;
  viewLocation: boolean;
}
