export type InteractionEventType =
  | 'tap'
  | 'swipe'
  | 'long_press'
  | 'stall'
  | 'error'
  | 'navigation'
  | 'voice_command';

export interface InteractionEvent {
  eventType: InteractionEventType;
  screen: string;
  targetElement?: string;
  tapAccuracy?: number;
  responseTime?: number;
  wasError: boolean;
  errorType?: string;
  complexityLevel: number;
  metadata?: Record<string, unknown>;
  timestamp: string;
}

export interface InteractionBatch {
  sessionId: string;
  events: InteractionEvent[];
}

export interface AdaptiveMetrics {
  errorRate: number;
  avgResponseTime: number;
  taskCompletionRate: number;
  stallRate: number;
  avgSessionDuration: number;
  tapAccuracy: number;
}

export interface AdaptivePrediction {
  complexityLevel: number;
  confidence: number;
  suggestedModifications: string[];
}

export interface ComplexityLevelConfig {
  level: number;
  name: string;
  buttonSize: number;
  itemsPerScreen: number;
  showText: 'none' | 'short' | 'medium' | 'detailed' | 'full';
  audioMode: 'auto' | 'on_tap' | 'optional' | 'hidden';
  confirmationLevel: 'every' | 'important' | 'destructive' | 'none';
  animationEnabled: boolean;
  colorCoding: 'strong' | 'icon' | 'text' | 'minimal';
}
