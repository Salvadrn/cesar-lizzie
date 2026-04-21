import { Injectable, ForbiddenException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { randomBytes } from 'crypto';
import { CaregiverLink } from './entities/caregiver-link.entity';

@Injectable()
export class CaregiverService {
  constructor(
    @InjectRepository(CaregiverLink)
    private linkRepo: Repository<CaregiverLink>,
  ) {}

  async generateInviteCode(userId: string): Promise<string> {
    const code = randomBytes(4).toString('hex').toUpperCase();
    const link = this.linkRepo.create({
      userId,
      caregiverId: userId, // placeholder, updated when accepted
      inviteCode: code,
      status: 'pending',
    });
    await this.linkRepo.save(link);
    return code;
  }

  async acceptInvite(caregiverId: string, inviteCode: string, relationship?: string) {
    const link = await this.linkRepo.findOne({
      where: { inviteCode, status: 'pending' },
    });
    if (!link) throw new NotFoundException('Invalid or expired invite code');

    link.caregiverId = caregiverId;
    link.status = 'active';
    link.linkedAt = new Date();
    link.relationship = relationship ?? null;
    return this.linkRepo.save(link);
  }

  async getLinkedUsers(caregiverId: string) {
    return this.linkRepo.find({
      where: { caregiverId, status: 'active' },
      relations: ['user'],
    });
  }

  async verifyAccess(caregiverId: string, userId: string, permission?: string) {
    const link = await this.linkRepo.findOne({
      where: { caregiverId, userId, status: 'active' },
    });
    if (!link) throw new ForbiddenException('No active link to this user');
    if (permission && !link.permissions[permission as keyof typeof link.permissions]) {
      throw new ForbiddenException(`Permission '${permission}' not granted`);
    }
    return link;
  }

  async updatePermissions(
    linkId: string,
    permissions: Partial<CaregiverLink['permissions']>,
    caregiverId: string,
  ) {
    const link = await this.linkRepo.findOne({ where: { id: linkId } });
    if (!link) throw new NotFoundException('Link not found');
    if (link.caregiverId !== caregiverId) {
      throw new ForbiddenException('No tienes permiso para modificar este enlace');
    }
    link.permissions = { ...link.permissions, ...permissions };
    return this.linkRepo.save(link);
  }

  async revokeLink(linkId: string) {
    await this.linkRepo.update(linkId, { status: 'revoked' });
  }
}
