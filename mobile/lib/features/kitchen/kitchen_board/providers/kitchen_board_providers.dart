import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/user_role.dart';
import 'package:mobile/features/auth/data/repository/auth_repository.dart';
import 'package:mobile/features/auth/providers/session_provider.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/repositories/kitchen_board_repository.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/fail_qc_send_to_rework_dialog.dart';
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

  List<KitchenBoardTicket> ticketsForLane(KitchenBoardLane lane) {
    final laneTickets = tickets
        .where((t) => t.lane == lane)
        .toList(growable: false);
    if (lane == KitchenBoardLane.preparing) {
      final reworkTickets = <KitchenBoardTicket>[];
      final nonReworkTickets = <KitchenBoardTicket>[];
      for (final ticket in laneTickets) {
        final isRework =
            ticket.rawStatus.toUpperCase() == 'REWORKING' ||
            ticket.data.status == KkfcStatus.reworking;
        if (isRework) {
          reworkTickets.add(ticket);
        } else {
          nonReworkTickets.add(ticket);
        }
      }
      return [...reworkTickets, ...nonReworkTickets];
    }
    return laneTickets;
  }

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
    // Automatically refresh kitchen tickets whenever the user logs in or switches accounts
    ref.listen<String?>(sessionTokenProvider, (previous, next) {
      if (next != null && next != previous) {
        refresh(force: true);
      } else if (next == null && previous != null) {
        state = const KitchenBoardState(isLoading: false, tickets: []);
      }
    });

    Future.microtask(loadInitial);
    return const KitchenBoardState(isLoading: true);
  }

  Future<void> loadInitial() async {
    await _fetch(isRefresh: false);
  }

  Future<void> refresh({bool force = false}) async {
    if (!force && (state.isLoading || state.isRefreshing)) return;
    if (force && state.isRefreshing) return;
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
      final prevMap = {for (final t in state.tickets) t.kitchenTicketId: t};
      final mergedTickets = tickets.map((t) {
        final prev = prevMap[t.kitchenTicketId];
        if (prev != null) {
          final returnedReason = t.qcReturnedReason ?? prev.qcReturnedReason;
          final notes = t.reworkNotes ?? prev.reworkNotes;
          if (returnedReason != null || notes != null) {
            return t.copyWith(
              qcReturnedReason: returnedReason,
              reworkNotes: notes,
              data: t.data.copyWith(
                qcReturnedReason: returnedReason,
                reworkNotes: notes,
              ),
            );
          }
        }
        return t;
      }).toList();

      state = state.copyWith(
        tickets: mergedTickets,
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
    final userRole = ref.read(userRoleProvider);
    if (userRole == UserRole.supervisor) return false;

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
    final userRole = ref.read(userRoleProvider);
    if (userRole == UserRole.supervisor) return false;

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

  Future<bool> sendToQc(
    String kitchenTicketId, {
    String? reworkNotes,
  }) async {
    final userRole = ref.read(userRoleProvider);
    if (userRole == UserRole.supervisor) return false;

    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      await repo.sendToQc(kitchenTicketId, preparerId: userId);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      final prevTicket = state.tickets.firstWhere(
        (t) => t.kitchenTicketId == kitchenTicketId,
        orElse: () => tickets.firstWhere(
          (t) => t.kitchenTicketId == kitchenTicketId,
          orElse: () => tickets.first,
        ),
      );
      final effectiveReworkNotes = reworkNotes ?? prevTicket.reworkNotes;
      final effectiveQcReturnedReason = prevTicket.qcReturnedReason;

      final updatedTickets = tickets.map((t) {
        if (t.kitchenTicketId == kitchenTicketId &&
            (t.rawStatus.toUpperCase() == 'PREPARING' ||
                t.rawStatus.toUpperCase() == 'REWORKING' ||
                t.data.status == KkfcStatus.preparing ||
                t.data.status == KkfcStatus.reworking)) {
          return t.copyWith(
            rawStatus: 'FOR_CHECKING',
            lane: KitchenBoardLane.qcCheck,
            clearQcAttemptId: true,
            qcReturnedReason: effectiveQcReturnedReason,
            reworkNotes: effectiveReworkNotes,
            data: t.data.copyWith(
              status: KkfcStatus.checking,
              qcReturnedReason: effectiveQcReturnedReason,
              reworkNotes: effectiveReworkNotes,
            ),
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

  Future<bool> passQc({
    required String kitchenTicketId,
    String? attemptId,
  }) async {
    final userRole = ref.read(userRoleProvider);
    if (userRole != null && !userRole.canPassQc) return false;

    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      await repo.passQcForTicket(
        kitchenTicketId: kitchenTicketId,
        attemptId: attemptId,
        checkerId: userId,
      );
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      final updatedTickets = tickets.map((t) {
        if (t.kitchenTicketId == kitchenTicketId &&
            (t.rawStatus.toUpperCase() == 'FOR_CHECKING' ||
                t.rawStatus.toUpperCase() == 'CHECKING' ||
                t.data.status == KkfcStatus.checking ||
                t.lane == KitchenBoardLane.qcCheck)) {
          return t.copyWith(
            rawStatus: 'READY',
            lane: KitchenBoardLane.ready,
            data: t.data.copyWith(status: KkfcStatus.ready),
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

  Future<bool> rejectQc({
    required String kitchenTicketId,
    String? reason,
    String? attemptId,
    List<String>? orderItemIds,
    List<QcItemRejection>? rejections,
  }) async {
    final userRole = ref.read(userRoleProvider);
    if (userRole != null && !userRole.canPassQc) return false;

    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      final userId = await _resolveCurrentUserId();
      final effectiveReason = reason ??
          (rejections != null && rejections.isNotEmpty
              ? rejections.first.reason
              : 'QC failed');
      final rejectionsPayload = rejections?.map((r) => r.toJson()).toList();

      await repo.rejectQcForTicket(
        kitchenTicketId: kitchenTicketId,
        reason: effectiveReason,
        attemptId: attemptId,
        checkerId: userId,
        orderItemIds: orderItemIds,
        rejections: rejectionsPayload,
      );
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      final updatedTickets = tickets.map((t) {
        if (t.kitchenTicketId == kitchenTicketId) {
          return t.copyWith(
            rawStatus: 'REWORKING',
            lane: KitchenBoardLane.preparing,
            clearQcAttemptId: true,
            qcReturnedReason: effectiveReason,
            data: t.data.copyWith(
              status: KkfcStatus.reworking,
              qcReturnedReason: effectiveReason,
            ),
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

  Future<bool> handOverTicket(String kitchenTicketId) async {
    final userRole = ref.read(userRoleProvider);
    if (userRole == UserRole.supervisor) return false;

    if (state.loadingTicketIds.contains(kitchenTicketId)) return false;

    state = state.copyWith(
      loadingTicketIds: {...state.loadingTicketIds, kitchenTicketId},
      clearError: true,
    );

    try {
      final repo = ref.read(kitchenBoardRepositoryProvider);
      await repo.handOverTicket(kitchenTicketId);
      final tickets = await repo.fetchTodaysTickets();
      final nextLoading = Set<String>.from(state.loadingTicketIds)
        ..remove(kitchenTicketId);

      // Filter out the handed-over ticket so it disappears from board immediately
      final updatedTickets = tickets
          .where((t) => t.kitchenTicketId != kitchenTicketId)
          .toList();

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
    final isQcLane =
        raw == 'FOR_CHECKING' ||
        raw == 'CHECKING' ||
        ticket.data.status == KkfcStatus.checking ||
        ticket.lane == KitchenBoardLane.qcCheck;

    final userRole = ref.read(userRoleProvider);
    if (userRole != null &&
        !userRole.canChangeTicketStatus(isQcCheck: isQcLane)) {
      return false;
    }

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

    final isPreparingOrReworking =
        raw == 'PREPARING' ||
        raw == 'REWORKING' ||
        ticket.data.status == KkfcStatus.preparing ||
        ticket.data.status == KkfcStatus.reworking;
    if (isPreparingOrReworking) {
      return sendToQc(ticket.kitchenTicketId, reworkNotes: ticket.reworkNotes);
    }

    if (isQcLane) {
      return passQc(
        kitchenTicketId: ticket.kitchenTicketId,
        attemptId: ticket.qcAttemptId,
      );
    }

    final isReady =
        raw == 'READY' ||
        ticket.data.status == KkfcStatus.ready ||
        ticket.lane == KitchenBoardLane.ready;
    if (isReady) {
      return handOverTicket(ticket.kitchenTicketId);
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
