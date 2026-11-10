import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/repositories/kitchen_board_repository.dart';

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

  Future<void> performTicketAction(KitchenBoardTicket ticket) async {
    final id = ticket.kitchenTicketId;
    if (state.loadingTicketIds.contains(id)) return;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, id},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      await repo.advanceTicket(ticket);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)..remove(id);
      state = state.copyWith(
        tickets: tickets,
        updatedAt: DateTime.now(),
        loadingTicketIds: nextLoading,
        clearError: true,
      );
    } catch (error) {
      final nextLoading = Set<String>.from(state.loadingTicketIds)..remove(id);
      state = state.copyWith(
        loadingTicketIds: nextLoading,
        errorMessage: error.toString(),
      );
    }
  }
}

final kitchenBoardProvider =
    NotifierProvider<KitchenBoardNotifier, KitchenBoardState>(
      KitchenBoardNotifier.new,
    );
