import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:flutter/foundation.dart' show mapEquals;

class MenuChannelNotifier extends Notifier<MenuChannel> {
  MenuChannel? _previous;

  @override
  MenuChannel build() {
    _previous = null;
    return MenuChannel.dineIn;
  }

  MenuChannel? get previousChannel => _previous;

  void select(MenuChannel channel) {
    if (channel == state) return;
    _previous = state;
    state = channel;
  }

  bool undo() {
    final previous = _previous;
    if (previous == null || previous == state) return false;
    _previous = state;
    state = previous;
    return true;
  }

  void reset() {
    _previous = null;
    state = MenuChannel.dineIn;
  }
}

final menuChannelProvider = NotifierProvider<MenuChannelNotifier, MenuChannel>(
  MenuChannelNotifier.new,
);

class MenuSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String query) => state = query;
  void clear() => state = '';
}

final menuSearchProvider = NotifierProvider<MenuSearchNotifier, String>(
  MenuSearchNotifier.new,
);

class OrderReferenceNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String reference) => state = reference;
  void clear() => state = '';
}

final orderReferenceProvider = NotifierProvider<OrderReferenceNotifier, String>(
  OrderReferenceNotifier.new,
);

class StoreReferenceNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String reference) => state = reference;
  void clear() => state = '';
}

final storeReferenceProvider = NotifierProvider<StoreReferenceNotifier, String>(
  StoreReferenceNotifier.new,
);

final menuItemsProvider = FutureProvider.autoDispose<List<MenuItem>>((
  ref,
) async {
  final activeBrand = ref.watch(activeBrandProvider);
  var targetBrandId = activeBrand.id;

  // Ensure targetBrandId is a valid UUID before sending to the backend.
  // If activeBrand.id is still a placeholder slug (e.g. 'gamcheon'),
  // wait for the backend brands to load and resolve the matching UUID.
  final isUuid = RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(targetBrandId);
  if (!isUuid) {
    try {
      final brands = await ref.watch(brandsListProvider.future);
      final match = brands.firstWhere(
        (b) =>
            b.code.toUpperCase() == activeBrand.code.toUpperCase() ||
            b.name.toLowerCase() == activeBrand.name.toLowerCase(),
        orElse: () => brands.first,
      );
      targetBrandId = match.id;
    } catch (_) {
      // In tests with mock IDs, leave targetBrandId as-is
    }
  }

  return ref.watch(menuRepositoryProvider).getByBrand(targetBrandId);
});

/// Channels to show as tabs: those the loaded menu items are sold on, in
/// [MenuChannel] order. Falls back to every channel while the menu is
/// loading, on error, or when the backend lists no channels.
final availableChannelsProvider = Provider.autoDispose<List<MenuChannel>>((
  ref,
) {
  final items = ref.watch(menuItemsProvider).asData?.value;
  if (items == null) return MenuChannel.values;
  final listed = {for (final item in items) ...item.channels};
  if (listed.isEmpty) return MenuChannel.values;
  return [
    for (final channel in MenuChannel.values)
      if (listed.contains(channel)) channel,
  ];
});

class MenuCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void set(String category) => state = category;
}

final menuCategoryProvider = NotifierProvider<MenuCategoryNotifier, String>(
  MenuCategoryNotifier.new,
);

class HideUnavailableNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool hide) => state = hide;
}

final hideUnavailableProvider = NotifierProvider<HideUnavailableNotifier, bool>(
  HideUnavailableNotifier.new,
);

final visibleMenuItemsProvider =
    Provider.autoDispose<AsyncValue<List<MenuItem>>>((ref) {
      final query = ref.watch(menuSearchProvider).trim().toLowerCase();
      final hideUnavailable = ref.watch(hideUnavailableProvider);
      final currentChannel = ref.watch(menuChannelProvider);

      return ref
          .watch(menuItemsProvider)
          .whenData(
            (items) => items.where((i) {
              final matchesQuery =
                  query.isEmpty ||
                  i.name.toLowerCase().contains(query) ||
                  i.description.toLowerCase().contains(query) ||
                  (i.category ?? '').toLowerCase().contains(query);
              final matchesAvailability =
                  !hideUnavailable ||
                  i.availabilityFor(currentChannel) ==
                      MenuAvailability.available;
              return matchesQuery && matchesAvailability;
            }).toList(),
          );
    });

class CartNotifier extends Notifier<List<CartLine>> {
  int _seq = 0;

  @override
  List<CartLine> build() => const [];

  /// Fills in the default option for any group that has no selection.
  Map<String, String> _normalize(MenuItem item, Map<String, String> s) => {
    for (final g in item.modifierGroups) g.id: s[g.id] ?? g.defaultOptionId,
  };

  int _findIdentical(
    MenuItem item,
    Map<String, String> sel, {
    String? except,
    String? kitchenNote,
  }) => state.indexWhere(
    (l) =>
        l.id != except &&
        l.item.id == item.id &&
        mapEquals(l.selections, sel) &&
        (l.kitchenNote ?? '') == (kitchenNote ?? ''),
  );

  /// Quick add with defaults (no modifiers).
  void add(MenuItem item) => addConfigured(item, const {}, 1);

  void addConfigured(
    MenuItem item,
    Map<String, String> selections,
    int quantity, {
    String? kitchenNote,
  }) {
    final sel = _normalize(item, selections);
    final note = (kitchenNote != null && kitchenNote.trim().isNotEmpty)
        ? kitchenNote.trim()
        : null;
    final i = _findIdentical(item, sel, kitchenNote: note);
    if (i != -1) {
      state = [
        for (var k = 0; k < state.length; k++)
          if (k == i)
            state[k].copyWith(quantity: state[k].quantity + quantity)
          else
            state[k],
      ];
      return;
    }
    state = [
      ...state,
      CartLine(
        id: 'line-${_seq++}',
        item: item,
        quantity: quantity,
        selections: sel,
        kitchenNote: note,
      ),
    ];
  }

  void updateLine(
    String lineId,
    Map<String, String> selections,
    int quantity, {
    MenuItem? item,
    String? kitchenNote,
  }) {
    final i = state.indexWhere((l) => l.id == lineId);
    if (i == -1) return;
    final line = item == null
        ? state[i]
        : CartLine(
            id: state[i].id,
            item: item,
            quantity: state[i].quantity,
            selections: state[i].selections,
            kitchenNote: state[i].kitchenNote,
          );
    final sel = _normalize(line.item, selections);
    final note = kitchenNote != null
        ? (kitchenNote.trim().isEmpty ? null : kitchenNote.trim())
        : line.kitchenNote;

    // If the edit makes this line identical to another, merge them.
    final j = _findIdentical(line.item, sel, except: lineId, kitchenNote: note);
    if (j != -1) {
      final otherId = state[j].id;
      state = [
        for (final l in state)
          if (l.id != lineId)
            (l.id == otherId ? l.copyWith(quantity: l.quantity + quantity) : l),
      ];
      return;
    }
    state = [
      for (final l in state)
        if (l.id == lineId)
          CartLine(
            id: line.id,
            item: line.item,
            quantity: quantity,
            selections: sel,
            kitchenNote: note,
          )
        else
          l,
    ];
  }

  void incrementLine(String lineId) => state = [
    for (final l in state)
      if (l.id == lineId) l.copyWith(quantity: l.quantity + 1) else l,
  ];

  void decrementLine(String lineId) => state = [
    for (final l in state)
      if (l.id != lineId)
        l
      else if (l.quantity > 1)
        l.copyWith(quantity: l.quantity - 1),
  ];

  void removeLine(String lineId) => state = [
    for (final l in state)
      if (l.id != lineId) l,
  ];

  void clear() => state = const [];
}

/// Not autoDispose: the draft order must survive tab changes.
final cartProvider = NotifierProvider<CartNotifier, List<CartLine>>(
  CartNotifier.new,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, l) => sum + l.quantity),
);

final cartTotalProvider = Provider<int>((ref) {
  final channel = ref.watch(menuChannelProvider);
  return ref
      .watch(cartProvider)
      .fold(0, (sum, l) => sum + l.totalCentavos(channel));
});
