import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { RobotService } from './robot.service';

@WebSocketGateway({
  namespace: '/robot',
  cors: {
    origin: [
      'http://localhost:3000',
      'http://localhost:8081',
      process.env.DASHBOARD_URL,
    ].filter(Boolean),
    credentials: true,
  },
})
export class RobotGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private connectedRobots = new Map<string, string>(); // socketId -> robotId

  constructor(private robotService: RobotService) {}

  async handleConnection(client: Socket) {
    const { robotId, apiKey } = client.handshake.auth;

    if (!robotId || !apiKey) {
      client.disconnect();
      return;
    }

    const valid = await this.robotService.validateApiKey(robotId, apiKey);
    if (!valid) {
      client.emit('error', { message: 'Invalid API key' });
      client.disconnect();
      return;
    }

    this.connectedRobots.set(client.id, robotId);
    await this.robotService.updateStatus(robotId, 'online');

    // Join room for this robot
    client.join(`robot:${robotId}`);

    console.log(`Robot ${robotId} connected`);
  }

  async handleDisconnect(client: Socket) {
    const robotId = this.connectedRobots.get(client.id);
    if (robotId) {
      await this.robotService.updateStatus(robotId, 'offline');
      this.connectedRobots.delete(client.id);
      console.log(`Robot ${robotId} disconnected`);
    }
  }

  @SubscribeMessage('robot:telemetry')
  async handleTelemetry(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: Record<string, unknown>,
  ) {
    const robotId = this.connectedRobots.get(client.id);
    if (!robotId) return;

    await this.robotService.saveTelemetry(robotId, data);

    // Forward telemetry to dashboard/app listeners
    this.server.to(`robot:${robotId}`).emit('robot:telemetry_update', {
      robotId,
      ...data,
      receivedAt: new Date().toISOString(),
    });
  }

  @SubscribeMessage('robot:status_change')
  async handleStatusChange(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { state: string },
  ) {
    const robotId = this.connectedRobots.get(client.id);
    if (!robotId) return;

    const status = data.state as 'online' | 'error' | 'emergency_stop';
    await this.robotService.updateStatus(robotId, status);

    this.server.to(`robot:${robotId}`).emit('robot:status_update', {
      robotId,
      status,
      timestamp: new Date().toISOString(),
    });
  }

  @SubscribeMessage('robot:emergency')
  async handleEmergency(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { reason: string },
  ) {
    const robotId = this.connectedRobots.get(client.id);
    if (!robotId) return;

    await this.robotService.updateStatus(robotId, 'emergency_stop');

    this.server.to(`robot:${robotId}`).emit('robot:emergency_alert', {
      robotId,
      reason: data.reason,
      timestamp: new Date().toISOString(),
    });
  }

  /**
   * Send a command to a specific robot from the dashboard/app
   */
  sendCommandToRobot(robotId: string, command: Record<string, unknown>) {
    this.server.to(`robot:${robotId}`).emit('robot:command', command);
  }
}
