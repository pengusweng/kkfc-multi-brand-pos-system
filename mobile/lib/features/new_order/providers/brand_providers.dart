import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/repositories/brand_repository.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';
import 'package:mobile/core/models/brand_models.dart';

/// Preferred ordering of brand tabs matching the design hierarchy.
const _preferredBrandOrder = ['GC', 'AI', 'KK'];

/// Fetches all active brands from the API. Falls back to sample brands if
/// the API is unreachable (e.g. offline / mock unit tests).
final brandsListProvider = FutureProvider<List<AssignedBrand>>((ref) async {
  try {
    final fetched = await ref.watch(brandRepositoryProvider).getAll();
    if (fetched.isNotEmpty) {
      final sorted = List<AssignedBrand>.from(fetched)
        ..sort((a, b) {
          final indexA = _preferredBrandOrder.indexOf(a.code.toUpperCase());
          final indexB = _preferredBrandOrder.indexOf(b.code.toUpperCase());
          if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
          if (indexA != -1) return -1;
          if (indexB != -1) return 1;
          return a.name.compareTo(b.name);
        });
      return sorted;
    }
  } catch (_) {
    // Fall back to sampleAssignedBrands in tests or offline
  }
  return sampleAssignedBrands;
});

final assignedBrandsProvider = Provider<List<AssignedBrand>>((ref) {
  final asyncBrands = ref.watch(brandsListProvider);
  return asyncBrands.value ?? sampleAssignedBrands;
});

/// The only brand a non-superadmin may access under the current API contract.
final assignedBrandProvider = FutureProvider.autoDispose<AssignedBrand>((
  ref,
) async {
  final brandId = await ref.watch(authenticatedBrandIdProvider.future);
  return ref.watch(brandRepositoryProvider).getById(brandId);
});

class ActiveBrandNotifier extends Notifier<AssignedBrand> {
  AssignedBrand? _manualSelection;

  @override
  AssignedBrand build() {
    final brands = ref.watch(assignedBrandsProvider);
    final selection = _manualSelection;
    if (selection != null) {
      return brands.firstWhere(
        (b) =>
            b.id == selection.id ||
            b.code.toUpperCase() == selection.code.toUpperCase(),
        orElse: () => selection,
      );
    }
    return brands.isNotEmpty ? brands[0] : sampleAssignedBrands[0];
  }

  void select(AssignedBrand brand) {
    _manualSelection = brand;
    state = brand;
  }
}

final activeBrandProvider =
    NotifierProvider<ActiveBrandNotifier, AssignedBrand>(
      ActiveBrandNotifier.new,
    );

/// Resolves the real UUID of the currently active brand.
String resolveActiveBrandId(AssignedBrand brand, List<AssignedBrand> allBrands) {
  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  if (uuidRegex.hasMatch(brand.id)) return brand.id;
  for (final b in allBrands) {
    if (b.code.toUpperCase() == brand.code.toUpperCase() &&
        uuidRegex.hasMatch(b.id)) {
      return b.id;
    }
  }
  return brand.id;
}

