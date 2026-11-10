import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/auth/providers/auth_profile_provider.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/brand_repository.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/new_order/data/seed/sample_brands.dart';

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
String resolveActiveBrandId(
  AssignedBrand brand,
  List<AssignedBrand> allBrands,
) {
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

/// Represents the dynamic channel availability and authorization state for a brand.
class BrandChannelsState {
  const BrandChannelsState({
    required this.isAuthorized,
    required this.channels,
  });

  final bool isAuthorized;
  final List<MenuChannel> channels;
}

/// Dynamically fetches the available channels for a given brand from the backend menu catalog.
///
/// If staff is not authorized for the brand (e.g. 403 Forbidden or [AssignedBrand.isAuthorized] is false),
/// [BrandChannelsState.isAuthorized] is set to false.
/// Falls back to [brand.channels] or default channels when offline or running in mock unit tests.
final brandChannelsProvider =
    FutureProvider.family<BrandChannelsState, AssignedBrand>((
      ref,
      brand,
    ) async {
      if (!brand.isAuthorized) {
        return const BrandChannelsState(isAuthorized: false, channels: []);
      }

      try {
        final allBrands = ref.watch(assignedBrandsProvider);
        final targetBrandId = resolveActiveBrandId(brand, allBrands);
        final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(targetBrandId);

        if (isUuid) {
          final menuRepo = ref.watch(menuRepositoryProvider);
          final items = await menuRepo.getByBrand(targetBrandId);
          final listed = {for (final item in items) ...item.channels};
          if (listed.isNotEmpty) {
            final channels = [
              for (final channel in MenuChannel.values)
                if (listed.contains(channel)) channel,
            ];
            return BrandChannelsState(isAuthorized: true, channels: channels);
          }
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 403) {
          return const BrandChannelsState(isAuthorized: false, channels: []);
        }
      } catch (_) {
        // Fall back gracefully for offline or mock tests
      }

      return BrandChannelsState(
        isAuthorized: brand.isAuthorized,
        channels:
            brand.channels ??
            (brand.code.toUpperCase().contains('AI')
                ? const [MenuChannel.dineIn]
                : const [MenuChannel.dineIn, MenuChannel.takeaway]),
      );
    });
