import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { RobotService } from './robot.service';
import { EventsGateway } from '../../gateway/events.gateway';

/**
 * Allowed origins for WebSocket connections.
 * Robot hardware connects authenticated via apiKey (not CORS), so the
 * main purpose of this restriction is to block malicious web origins
 * from opening a socket. Production URLs should be added via env.
 */
const ROBOT_GATEWAY_ALLOWED_ORIGINS = (process.env.ROBOT_ALLOWED_ORIGINS ?? '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean)
  .concat([
    'http://localhost:3000',
    'http://localhost:8081',
    'https://adaptai.app',
    'https://dashboard.adaptai.app',
  ]);

@WebSocketGateway({
  cors: {
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      // Allow requests without origin (native RPi python-socketio client)
      if (!origin) return callback(null, true);
      if (ROBOT_GATEWAY_ALLOWED_ORIGINS.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error(`Origin ${origin} not allowed`), false);
    },
    credentials: true,
  },
  namespace: '/robot',
})
export class RobotGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RobotGateway.name);
  private robotSockets = new Map<string, string>();

  constructor(
    private robotService: RobotService,
    private eventsGateway: EventsGateway,
  ) {}

  async handleConnection(client: Socket) {
    const robotId = client.handshake.query.robotId as string;
    const apiKey = client.handshake.query.apiKey as string;

    if (!robotId || !apiKey) {
      this.logger.warn('Robot connection rejected: missing credentials');
      client.disconnect();
      return;
    }

    const robot = await this.robotService.validateApiKey(robotId, apiKey);
    if (!robot) {
      this.logger.warn(`Robot connection rejected: invalid API key for ${robotId}`);
      client.disconnect();
      return;
    }

    this.robotSockets.set(robotId, client.id);
    await this.robotService.updateStatus(robotId, 'online');
    this.logger.log(`Robot ${robotId} connected (socket: ${client.id})`);

    this.eventsGateway.emitToUser(robot.userId, 'robot:status_update', {
      robotId,
      status: 'online',
    });
  }

  async handleDisconnect(client: Socket) {
    const robotId = client.handshake.query.robotId as string;
    if (robotId && this.robotSockets.get(robotId) === client.id) {
      this.robotSockets.delete(robotId);
      await this.robotService.updateStatus(robotId, 'offline');
      this.logger.log(`Robot ${robotId} disconnected`);

      const robot = await this.robotService.findById(robotId);
      this.eventsGateway.emitToUser(robot.userId, 'robot:status_update', {
        robotId,
        status: 'offline',
      });

      await this.robotService.handleRobotAlert(
        robotId,
        'robot_disconnected',
        'Robot disconnected',
      );
    }
  }

  @SubscribeMessage('robot:telemetry')
  async handleTelemetry(client: Socket, data: any) {
    const robotId = client.handshake.query.robotId as string;
    if (!robotId) return;

    await this.robotService.saveTelemetry({ ...data, robotId });

    const robot = await this.robotService.findById(robotId);
    this.eventsGateway.emitToUser(robot.userId, 'robot:telemetry_update', {
      robotId,
      ...data,
    });

    if (data.state === 'emergency_stop') {
      await this.robotService.updateStatus(robotId, 'emergency_stop');
      await this.robotService.handleRobotAlert(
        robotId,
        'robot_emergency_stop',
        'Robot emergency stop activated',
        { reason: data.emergencyReason },
      );
    }

    if (data.batteryPercent < 15) {
      await this.robotService.handleRobotAlert(
        robotId,
        'robot_low_battery',
        `Robot battery low: ${data.batteryPercent}%`,
      );
    }

    if (!data.bleTargetFound) {
      await this.robotService.handleRobotAlert(
        robotId,
        'robot_target_lost',
        'Robot lost sight of patient',
      );
    }
  }

  @SubscribeMessage('robot:status_change')
  async handleStatusChange(client: Socket, data: { state: string }) {
    const robotId = client.handshake.query.robotId as string;
    if (!robotId) return;

    const statusMap: Record<string, 'online' | 'error' | 'emergency_stop'> = {
      following: 'online',
      idle: 'online',
      paused: 'online',
      error: 'error',
      emergency_stop: 'emergency_stop',
    };

    const status = statusMap[data.state] || 'online';
    await this.robotService.updateStatus(robotId, status);

    const robot = await this.robotService.findById(robotId);
    this.eventsGateway.emitToUser(robot.userId, 'robot:status_update', {
      robotId,
      status,
      state: data.state,
    });
  }

  sendCommandToRobot(robotId: string, command: any) {
    const socketId = this.robotSockets.get(robotId);
    if (socketId) {
      this.server.to(socketId).emit('robot:command', command);
    }
  }

  isRobotConnected(robotId: string): boolean {
    return this.robotSockets.has(robotId);
  }
}
