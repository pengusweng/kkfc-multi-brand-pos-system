import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/repositories/kitchen_board_repository.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

@immutable
class KitchenBoardState {
  const KitchenBoardState({
    this.tickets = const [],
    this.updatedAt,
    this.isLoading = false,
    this.isRefreshing = false,
    this.loadingTicketIds = const {},
    this.errorMessage,
  });

  final List<KitchenBoardTicket> tickets;
  final DateTime? updatedAt;
  final bool isLoading;
  final bool isRefreshing;
  final Set<String> loadingTicketIds;
  final String? errorMessage;

  int get activeCount => tickets.length;

  List<KitchenBoardTicket> ticketsForLane(KitchenBoardLane lane) =>
      tickets.where((t) => t.lane == lane).toList(growable: false);

  KitchenBoardState copyWith({
    List<KitchenBoardTicket>? tickets,
    DateTime? updatedAt,
    bool? isLoading,
    bool? isRefreshing,
    Set<String>? loadingTicketIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return KitchenBoardState(
      tickets: tickets ?? this.tickets,
      updatedAt: updatedAt ?? this.updatedAt,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      loadingTicketIds: loadingTicketIds ?? this.loadingTicketIds,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Formats a [DateTime] into 12-hour clock format (e.g. `'7:41 PM'`).
  static String formatTimeOfDay(DateTime dt) {
    final hour24 = dt.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }
}

class KitchenBoardNotifier extends Notifier<KitchenBoardState> {
  @override
  KitchenBoardState build() {
    Future.microtask(loadInitial);
    return const KitchenBoardState(isLoading: true);
  }

  Future<void> loadInitial() async {
    await _fetch(isRefresh: false);
  }

  Future<void> refresh() async {
    if (state.isLoading || state.isRefreshing) return;
    await _fetch(isRefresh: true);
  }

  Future<void> _fetch({required bool isRefresh}) async {
    state = state.copyWith(
      isLoading: !isRefresh,
      isRefreshing: isRefresh,
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final tickets = await repo.fetchTodaysTickets();
      state = state.copyWith(
        tickets: tickets,
        updatedAt: DateTime.now(),
        isLoading: false,
        isRefreshing: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<String?> _resolveCurrentUserId() async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      return await authRepo.getCurrentUserId().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> acknowledgeTicket(String kitchenTicketId) async {
    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      await repo.acknowledgeTicket(kitchenTicketId, preparerId: userId);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      // Ensure the ticket is in ACKNOWLEDGED state even if the repository
      // response is static or offline mock data.
      final updatedTickets = tickets.map((t) {
        if (t.kitchenTicketId == kitchenTicketId &&
            t.rawStatus.toUpperCase() == 'QUEUED') {
          return t.copyWith(
            rawStatus: 'ACKNOWLEDGED',
            lane: KitchenBoardLane.preparing,
            data: t.data.copyWith(status: KkfcStatus.acknowledged),
          );
        }
        return t;
      }).toList();

      state = state.copyWith(
        tickets: updatedTickets,
        updatedAt: DateTime.now(),
        loadingTicketIds: nextLoading,
        clearError: true,
      );
      return true;
    } catch (error) {
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);
      state = state.copyWith(
        loadingTicketIds: nextLoading,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> prepareTicket(String kitchenTicketId) async {
    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      await repo.prepareTicket(kitchenTicketId, preparerId: userId);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      // Ensure the ticket is in PREPARING state even if the repository
      // response is static or offline mock data.
      final updatedTickets = tickets.map((t) {
        if (t.kitchenTicketId == kitchenTicketId &&
            (t.rawStatus.toUpperCase() == 'ACKNOWLEDGED' ||
                t.data.status == KkfcStatus.acknowledged)) {
          return t.copyWith(
            rawStatus: 'PREPARING',
            lane: KitchenBoardLane.preparing,
            data: t.data.copyWith(status: KkfcStatus.preparing),
          );
        }
        return t;
      }).toList();

      state = state.copyWith(
        tickets: updatedTickets,
        updatedAt: DateTime.now(),
        loadingTicketIds: nextLoading,
        clearError: true,
      );
      return true;
    } catch (error) {
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);
      state = state.copyWith(
        loadingTicketIds: nextLoading,
        errorMessage: error.toString(),
      );
      return false;
    }
  }

  Future<bool> performTicketAction(KitchenBoardTicket ticket) async {
    final raw = ticket.rawStatus.toUpperCase();
    final isQueued =
        raw == 'QUEUED' ||
        ticket.data.status == KkfcStatus.queued ||
        ticket.lane == KitchenBoardLane.queued;
    if (isQueued) {
      return acknowledgeTicket(ticket.kitchenTicketId);
    }

    final isAcknowledged =
        raw == 'ACKNOWLEDGED' || ticket.data.status == KkfcStatus.acknowledged;
    if (isAcknowledged) {
      return prepareTicket(ticket.kitchenTicketId);
    }

    final id = ticket.kitchenTicketId;
    if (state.loadingTicketIds.contains(id)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, id},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      await repo.advanceTicket(ticket, preparerId: userId);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)..remove(id);
      state = state.copyWith(
        tickets: tickets,
        updatedAt: DateTime.now(),
        loadingTicketIds: nextLoading,
        clearError: true,
      );
      return true;
    } catch (error) {
      final nextLoading = Set<String>.from(state.loadingTicketIds)..remove(id);
      state = state.copyWith(
        loadingTicketIds: nextLoading,
        errorMessage: error.toString(),
      );
      return false;
    }
  }
}

final kitchenBoardProvider =
    NotifierProvider<KitchenBoardNotifier, KitchenBoardState>(
      KitchenBoardNotifier.new,
    );
