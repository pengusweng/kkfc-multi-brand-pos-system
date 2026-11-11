import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';
import { CreateUserDTO } from './dto/create-user.dto';
import { UpdateUserDTO } from './dto/update-user.dto';
import { FindUsersDTO } from './dto/find-users.dto';
import { Prisma } from '@prisma/client';
import * as argon2 from 'argon2';

@Injectable()
export class UsersRepository {
  constructor(private prisma: PrismaService) {}

  async create(
    dto: CreateUserDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const { password, ...userData } = dto;
    const passwordHash = await argon2.hash(password);

    return tx.user.create({
      data: {
        ...userData,
        password_hash: passwordHash,
      },
      omit: {
        password_hash: true,
      },
    });
  }

  async findAll(
    skip: number,
    take: number,
    { status, search, role }: Pick<FindUsersDTO, 'status' | 'search' | 'role'>,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    // Everything except status, which the per-status counts below vary.
    const matchesFilters: Prisma.UserWhereInput = {
      ...this.searchWhere(search),
      role,
    };
    const where: Prisma.UserWhereInput = {
      ...matchesFilters,
      is_active: status === 'all' ? undefined : status === 'active',
    };

    const usersQuery = tx.user.findMany({
      where,
      skip,
      take,
      orderBy: [{ created_at: 'desc' }, { user_id: 'asc' }],
      omit: { password_hash: true },
    });
    // Per-status counts honour the search and role but not the status filter,
    // so a client can label every status tab from a single response.
    const activeQuery = tx.user.count({
      where: { ...matchesFilters, is_active: true },
    });
    const inactiveQuery = tx.user.count({
      where: { ...matchesFilters, is_active: false },
    });

    const [users, active, inactive] =
      '$transaction' in tx
        ? await tx.$transaction([usersQuery, activeQuery, inactiveQuery], {
            isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead,
          })
        : await Promise.all([usersQuery, activeQuery, inactiveQuery]);

    return { users, counts: { all: active + inactive, active, inactive } };
  }

  // Every whitespace-separated term must match the username, first name, or
  // last name, so "ana rey" finds "Ana Reyes".
  private searchWhere(search?: string): Prisma.UserWhereInput {
    const terms = search?.split(/\s+/).filter(Boolean) ?? [];
    if (terms.length === 0) return {};

    return {
      AND: terms.map((term) => ({
        OR: (['username', 'first_name', 'last_name'] as const).map((field) => ({
          [field]: { contains: term, mode: 'insensitive' },
        })),
      })),
    };
  }

  async findOne(
    userId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: {
        user_id: userId,
        is_active: activeOnly ? true : undefined,
      },
      omit: { password_hash: true },
    });
  }

  async findCredentialsByUserId(
    userId: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: { user_id: userId, is_active: activeOnly ? true : undefined },
      select: { user_id: true, password_hash: true },
    });
  }

  async findByUsername(
    username: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: { username, is_active: activeOnly ? true : undefined },
      select: { user_id: true, password_hash: true },
    });
  }

  async safeFindByUsername(
    username: string,
    activeOnly = true,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.findUnique({
      where: {
        username: username,
        is_active: activeOnly ? true : undefined,
      },
      omit: { password_hash: true },
    });
  }

  async update(
    userId: string,
    dto: UpdateUserDTO,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.update({
      where: { user_id: userId, is_active: true },
      data: {
        username: dto.username,
        first_name: dto.first_name,
        last_name: dto.last_name,
        password_hash:
          dto.password !== undefined
            ? await argon2.hash(dto.password)
            : undefined,
        modified_at: new Date(),
      },
      omit: { password_hash: true },
    });
  }

  async delete(
    userId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    return tx.user.update({
      where: { user_id: userId },
      data: { is_active: false },
      omit: { password_hash: true },
    });
  }
}
