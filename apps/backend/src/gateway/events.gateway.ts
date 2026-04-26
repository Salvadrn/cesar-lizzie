import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Server, Socket } from 'socket.io';

function buildAllowedOrigins(config: ConfigService): string[] {
  const fromEnv = (config.get<string>('ALLOWED_ORIGINS') ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  if (config.get<string>('NODE_ENV') !== 'production') {
    fromEnv.push('http://localhost:3000', 'http://localhost:8081');
  }
  return fromEnv;
}

@WebSocketGateway({
  cors: {
    origin: (origin: string | undefined, cb: (err: Error | null, allow?: boolean) => void) => {
      // Allow non-browser clients (no Origin header).
      if (!origin) return cb(null, true);
      const allowed = (process.env.ALLOWED_ORIGINS ?? '')
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      if (process.env.NODE_ENV !== 'production') {
        allowed.push('http://localhost:3000', 'http://localhost:8081');
      }
      if (allowed.includes(origin)) return cb(null, true);
      return cb(new Error(`Origin ${origin} not allowed`), false);
    },
    credentials: true,
  },
  namespace: '/events',
})
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);
  private userSockets = new Map<string, Set<string>>();
  private socketUsers = new Map<string, string>();

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {
    // Touched at startup so a misconfigured prod fails loudly here too.
    buildAllowedOrigins(this.configService);
  }

  private extractToken(client: Socket): string | undefined {
    const authToken =
      (client.handshake.auth?.token as string | undefined) ??
      (client.handshake.headers?.authorization as string | undefined) ??
      (client.handshake.query?.token as string | undefined);
    if (!authToken) return undefined;
    return authToken.startsWith('Bearer ') ? authToken.slice(7) : authToken;
  }

  handleConnection(client: Socket) {
    const token = this.extractToken(client);
    if (!token) {
      this.logger.warn(`WS connection rejected: no token (${client.id})`);
      client.disconnect(true);
      return;
    }

    let userId: string;
    try {
      const payload = this.jwtService.verify<{ sub: string }>(token);
      userId = payload.sub;
    } catch {
      this.logger.warn(`WS connection rejected: invalid token (${client.id})`);
      client.disconnect(true);
      return;
    }

    if (!this.userSockets.has(userId)) {
      this.userSockets.set(userId, new Set());
    }
    this.userSockets.get(userId)!.add(client.id);
    this.socketUsers.set(client.id, userId);
    this.logger.log(`User ${userId} connected (socket: ${client.id})`);
  }

  handleDisconnect(client: Socket) {
    const userId = this.socketUsers.get(client.id);
    if (!userId) return;
    this.socketUsers.delete(client.id);
    const set = this.userSockets.get(userId);
    if (set) {
      set.delete(client.id);
      if (set.size === 0) this.userSockets.delete(userId);
    }
    this.logger.log(`User ${userId} disconnected`);
  }

  emitToUser(userId: string, event: string, data: any) {
    const sockets = this.userSockets.get(userId);
    if (!sockets) return;
    for (const socketId of sockets) {
      this.server.to(socketId).emit(event, data);
    }
  }

  emitToUsers(userIds: string[], event: string, data: any) {
    for (const userId of userIds) {
      this.emitToUser(userId, event, data);
    }
  }

  @SubscribeMessage('ping')
  handlePing(): string {
    return 'pong';
  }
}
