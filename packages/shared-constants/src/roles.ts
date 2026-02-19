export const ROLES = {
  USER: 'user',
  CAREGIVER: 'caregiver',
  ADMIN: 'admin',
} as const;

export const ROUTINE_CATEGORIES = [
  'cooking',
  'hygiene',
  'laundry',
  'medication',
  'transit',
  'shopping',
  'cleaning',
  'social',
  'custom',
] as const;

export const SCHEDULE_TYPES = ['daily', 'weekly', 'custom', 'on_demand'] as const;
