import type { ComplexityLevelConfig } from '@neuronav/shared-types';

export const COMPLEXITY_LEVELS: Record<number, ComplexityLevelConfig> = {
  1: {
    level: 1,
    name: 'Essential',
    buttonSize: 80,
    itemsPerScreen: 2,
    showText: 'none',
    audioMode: 'auto',
    confirmationLevel: 'every',
    animationEnabled: false,
    colorCoding: 'strong',
  },
  2: {
    level: 2,
    name: 'Simplified',
    buttonSize: 64,
    itemsPerScreen: 4,
    showText: 'short',
    audioMode: 'on_tap',
    confirmationLevel: 'important',
    animationEnabled: false,
    colorCoding: 'icon',
  },
  3: {
    level: 3,
    name: 'Standard',
    buttonSize: 48,
    itemsPerScreen: 6,
    showText: 'medium',
    audioMode: 'optional',
    confirmationLevel: 'destructive',
    animationEnabled: true,
    colorCoding: 'icon',
  },
  4: {
    level: 4,
    name: 'Enriched',
    buttonSize: 44,
    itemsPerScreen: 8,
    showText: 'detailed',
    audioMode: 'hidden',
    confirmationLevel: 'none',
    animationEnabled: true,
    colorCoding: 'text',
  },
  5: {
    level: 5,
    name: 'Full',
    buttonSize: 36,
    itemsPerScreen: 12,
    showText: 'full',
    audioMode: 'hidden',
    confirmationLevel: 'none',
    animationEnabled: true,
    colorCoding: 'minimal',
  },
};

export const MIN_COMPLEXITY = 1;
export const MAX_COMPLEXITY = 5;
export const DEFAULT_COMPLEXITY = 3;

// Smoothing factor for adaptive level changes
export const ADAPTIVE_SMOOTHING_FACTOR = 0.3;
export const MAX_LEVEL_CHANGE_PER_SESSION = 1;
