import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { UserProfile } from './entities/user-profile.entity';

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

  async updateProfile(userId: string, data: Partial<UserProfile>): Promise<UserProfile> {
    const profile = await this.getProfileOrFail(userId);
    Object.assign(profile, data);
    return this.profileRepo.save(profile);
  }

  async updateLastLogin(userId: string): Promise<void> {
    await this.userRepo.update(userId, { lastLoginAt: new Date() });
  }
}
