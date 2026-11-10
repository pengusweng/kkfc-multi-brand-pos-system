import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';

// Demo data from the design. Production: the list comes from RBAC.
const sampleAssignedBrands = <AssignedBrand>[
  AssignedBrand(
    id: 'gamcheon',
    code: 'GC',
    name: 'Gamcheon',
    isAuthorized: true,
    channels: [
      MenuChannel.dineIn,
      MenuChannel.takeaway,
      MenuChannel.grabFood,
      MenuChannel.foodpanda,
    ],
  ),
  AssignedBrand(
    id: 'aurelias-inasal',
    code: 'AI',
    name: "Aurelia's Inasal",
    isAuthorized: true,
    channels: [MenuChannel.dineIn],
  ),
  AssignedBrand(
    id: 'king-kungs-kafe',
    code: 'KK',
    name: 'King Kungs Kafé',
    isAuthorized: false,
    channels: [MenuChannel.dineIn, MenuChannel.takeaway],
  ),
];
