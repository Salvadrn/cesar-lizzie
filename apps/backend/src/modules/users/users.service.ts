import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';
import { UpdateProfileDto } from './dto/update-profile.dto';

// Whitelist of profile fields that the user is allowed to update via the API.
// Anything else (currentComplexity, totalSessions, complexityFloor/ceiling,
// userId, timestamps, etc.) is owned by the server / caregiver flow.
const USER_EDITABLE_PROFILE_FIELDS = [
  'sensoryMode',
  'hapticEnabled',
  'hapticIntensity',
  'audioEnabled',
  'audioSpeed',
  'fontScale',
  'animationEnabled',
  'lostModeName',
  'lostModeAddress',
  'lostModePhone',
  'preferredInput',
  'language',
] as const satisfies ReadonlyArray<keyof UserProfile>;

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
    @InjectRepository(UserProfile)
    private profileRepo: Repository<UserProfile>,
  ) {}

  async create(data: {
    email: string;
    passwordHash: string;
    displayName: string;
    role: 'user' | 'caregiver' | 'admin';
  }): Promise<User> {
    const user = this.userRepo.create(data);
    const savedUser = await this.userRepo.save(user);

    // Create profile for users (not caregivers)
    if (data.role === 'user') {
      const profile = this.profileRepo.create({ userId: savedUser.id });
      await this.profileRepo.save(profile);
    }

    return savedUser;
  }

  async findById(id: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { id } });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepo.findOne({ where: { email } });
  }

  async findByIdOrFail(id: string): Promise<User> {
    const user = await this.findById(id);
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async getProfile(userId: string): Promise<UserProfile | null> {
    return this.profileRepo.findOne({ where: { userId } });
  }

  async getProfileOrFail(userId: string): Promise<UserProfile> {
    const profile = await this.getProfile(userId);
    if (!profile) throw new NotFoundException('User profile not found');
    return profile;
  }

  async updateProfile(userId: string, data: UpdateProfileDto): Promise<UserProfile> {
    const profile = await this.getProfileOrFail(userId);
    for (const field of USER_EDITABLE_PROFILE_FIELDS) {
      if (data[field as keyof UpdateProfileDto] !== undefined) {
        (profile as any)[field] = data[field as keyof UpdateProfileDto];
      }
    }
    return this.profileRepo.save(profile);
  }

  async updateLastLogin(userId: string): Promise<void> {
    await this.userRepo.update(userId, { lastLoginAt: new Date() });
  }
}
