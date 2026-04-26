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
import { RoutinesService } from './routines.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { CreateRoutineDto } from './dto/create-routine.dto';

@Controller('routines')
@UseGuards(JwtAuthGuard)
export class RoutinesController {
  constructor(private routinesService: RoutinesService) {}

  @Get()
  async findAll(@CurrentUser() user: { id: string; role: string }) {
    return this.routinesService.findAll(user.id, user.role);
  }

  @Get('templates')
  async findTemplates() {
    return this.routinesService.findTemplates();
  }

  @Get(':id')
  async findById(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
  ) {
    return this.routinesService.findByIdAuthorized(id, user);
  }

  @Post()
  async create(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateRoutineDto,
  ) {
    return this.routinesService.create(dto, user.id);
  }

  @Put(':id')
  async update(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
    @Body() data: Partial<CreateRoutineDto>,
  ) {
    return this.routinesService.update(id, data as any, user);
  }

  @Delete(':id')
  async delete(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') id: string,
  ) {
    return this.routinesService.softDelete(id, user);
  }

  @Post(':id/steps')
  async addStep(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') routineId: string,
    @Body() stepData: any,
  ) {
    return this.routinesService.addStep(routineId, stepData, user);
  }

  @Put(':routineId/steps/:stepId')
  async updateStep(
    @CurrentUser() user: { id: string; role: string },
    @Param('stepId') stepId: string,
    @Body() data: any,
  ) {
    return this.routinesService.updateStep(stepId, data, user);
  }

  @Delete(':routineId/steps/:stepId')
  async deleteStep(
    @CurrentUser() user: { id: string; role: string },
    @Param('stepId') stepId: string,
  ) {
    return this.routinesService.deleteStep(stepId, user);
  }

  @Put(':id/steps/reorder')
  async reorderSteps(
    @CurrentUser() user: { id: string; role: string },
    @Param('id') routineId: string,
    @Body('stepIds') stepIds: string[],
  ) {
    return this.routinesService.reorderSteps(routineId, stepIds, user);
  }
}
