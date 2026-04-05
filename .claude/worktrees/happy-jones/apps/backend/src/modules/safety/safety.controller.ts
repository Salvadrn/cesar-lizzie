import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { SafetyService } from './safety.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('safety')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  constructor(private safetyService: SafetyService) {}

  // Safety Zones
  @Get('zones')
  async getZones(@CurrentUser() user: { id: string }) {
    return this.safetyService.getZones(user.id);
  }

  @Post('zones')
  async createZone(
    @CurrentUser() user: { id: string },
    @Body() data: any,
  ) {
    return this.safetyService.createZone(user.id, data);
  }

  @Put('zones/:id')
  async updateZone(@Param('id') id: string, @Body() data: any) {
    return this.safetyService.updateZone(id, data);
  }

  @Delete('zones/:id')
  async deleteZone(@Param('id') id: string) {
    return this.safetyService.deleteZone(id);
  }

  // Location reporting
  @Post('location')
  async reportLocation(
    @CurrentUser() user: { id: string },
    @Body() body: { latitude: number; longitude: number },
  ) {
    return this.safetyService.checkLocation(user.id, body.latitude, body.longitude);
  }

  // Emergency
  @Post('emergency')
  async triggerEmergency(
    @CurrentUser() user: { id: string },
    @Body() body: { latitude?: number; longitude?: number },
  ) {
    return this.safetyService.triggerEmergency(user.id, body.latitude, body.longitude);
  }

  @Post('lost-mode')
  async activateLostMode(
    @CurrentUser() user: { id: string },
    @Body() body: { latitude?: number; longitude?: number },
  ) {
    return this.safetyService.activateLostMode(user.id, body.latitude, body.longitude);
  }

  // Emergency contacts
  @Get('emergency-contacts')
  async getContacts(@CurrentUser() user: { id: string }) {
    return this.safetyService.getEmergencyContacts(user.id);
  }

  @Post('emergency-contacts')
  async addContact(
    @CurrentUser() user: { id: string },
    @Body() data: any,
  ) {
    return this.safetyService.addContact(user.id, data);
  }

  @Delete('emergency-contacts/:id')
  async deleteContact(@Param('id') id: string) {
    return this.safetyService.deleteContact(id);
  }
}
