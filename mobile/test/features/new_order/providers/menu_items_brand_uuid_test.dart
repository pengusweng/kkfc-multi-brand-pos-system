import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/brand_repository.dart';
import 'package:mobile/features/new_order/data/repositories/menu_repository.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

class _MockBrandRepository implements BrandRepository {
  _MockBrandRepository(this.brands);
  final List<AssignedBrand> brands;

  @override
  Future<List<AssignedBrand>> getAll({bool activeOnly = true}) async => brands;

  @override
  Future<AssignedBrand> getById(String brandId) async {
    return brands.firstWhere((b) => b.id == brandId);
  }
}

class _MockMenuRepository implements MenuRepository {
  final List<String> requestedBrandIds = [];

  @override
  Future<List<MenuItem>> getByBrand(
    String brandId, {
    bool activeOnly = true,
  }) async {
    requestedBrandIds.add(brandId);
    return [
      MenuItem(
        id: 'item-1',
        name: 'Item for $brandId',
        description: 'Test item',
        pricesCentavos: {MenuChannel.dineIn: 10000},
      ),
    ];
  }
}

void main() {
  const gamcheonUuid = 'fdf3a147-b1bd-4985-8ff4-c4f1b7db719d';
  const aureliaUuid = '889c31f7-56fd-43c9-84a8-a7d8959151a4';

  final backendBrands = [
    const AssignedBrand(id: gamcheonUuid, code: 'GC', name: 'Gamcheon'),
    const AssignedBrand(id: aureliaUuid, code: 'AI', name: "Aurelia's Inasal"),
  ];

  late _MockBrandRepository mockBrandRepo;
  late _MockMenuRepository mockMenuRepo;

  setUp(() {
    mockBrandRepo = _MockBrandRepository(backendBrands);
    mockMenuRepo = _MockMenuRepository();
  });

  test(
    'menuItemsProvider resolves slug brand to real backend UUID before calling getByBrand',
    () async {
      final container = ProviderContainer(
        overrides: [
          brandRepositoryProvider.overrideWithValue(mockBrandRepo),
          menuRepositoryProvider.overrideWithValue(mockMenuRepo),
        ],
      );
      addTearDown(container.dispose);

      // Initially activeBrand has slug 'gamcheon'
      expect(container.read(activeBrandProvider).id, 'gamcheon');

      // Keep autoDispose provider alive during async execution
      final sub = container.listen(menuItemsProvider, (previous, next) {});
      addTearDown(sub.close);

      // Fetch menu items
      final items = await container.read(menuItemsProvider.future);

      expect(items, isNotEmpty);
      // Verify the requested ID was the UUID, NOT the slug 'gamcheon'
      expect(mockMenuRepo.requestedBrandIds, contains(gamcheonUuid));
      expect(mockMenuRepo.requestedBrandIds, isNot(contains('gamcheon')));
    },
  );

  test(
    'menuItemsProvider uses brand UUID directly when activeBrand already has a UUID',
    () async {
      final container = ProviderContainer(
        overrides: [
          brandRepositoryProvider.overrideWithValue(mockBrandRepo),
          menuRepositoryProvider.overrideWithValue(mockMenuRepo),
        ],
      );
      addTearDown(container.dispose);

      // Select Aurelia directly with UUID
      container
          .read(activeBrandProvider.notifier)
          .select(backendBrands[1]); // aureliaUuid

      final sub = container.listen(menuItemsProvider, (previous, next) {});
      addTearDown(sub.close);

      final items = await container.read(menuItemsProvider.future);

      expect(items, isNotEmpty);
      expect(mockMenuRepo.requestedBrandIds.last, aureliaUuid);
    },
  );
}
