import 'package:mobile/features/new_order/data/models/menu_models.dart';

final sampleGamcheonMenu = <MenuItem>[
  MenuItem(
    id: 'gamcheon-samgyupsal',
    name: 'Gamcheon Samgyupsal Rice Bowl',
    description: 'Thinly sliced pork belly marinated in house gochujang sweet soy, sesame and scallions over warm rice.',
    category: 'Rice bowls',
    pricesCentavos: {
      MenuChannel.dineIn: 22000,
      MenuChannel.takeaway: 22000,
      MenuChannel.grabFood: 24000,
      MenuChannel.foodpanda: 24000,
    },
    modifierGroups: [
      ModifierGroup(
        id: 'rice-choice',
        title: 'Rice Choice',
        defaultOptionId: 'steamed-white-rice',
        options: [
          ModifierOption(
            id: 'steamed-white-rice',
            label: 'Steamed White Rice',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'garlic-butter-rice',
            label: 'Garlic Butter Rice',
            priceDeltaCentavos: 1500,
          ),
        ],
      ),
      ModifierGroup(
        id: 'spice-level',
        title: 'Spice Level',
        defaultOptionId: 'mild',
        options: [
          ModifierOption(
            id: 'mild',
            label: 'Mild (Touch of Sweetness)',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'medium',
            label: 'Medium Traditional',
            priceDeltaCentavos: 0,
          ),
          ModifierOption(
            id: 'spicy-fire-garlic',
            label: 'Spicy Fire Garlic',
            priceDeltaCentavos: 1000,
          ),
        ],
      ),
      ModifierGroup.addOn(
        id: 'fried-egg',
        name: 'Fried Sunny-Side Egg',
        priceCentavos: 2500,
      ),
      ModifierGroup.addOn(
        id: 'house-kimchi',
        name: 'House Kimchi Portion (60g)',
        priceCentavos: 3000,
      ),
    ],
  ),
  MenuItem(
    id: 'spicy-pork-bulgogi',
    name: 'Spicy Pork Bulgogi Set',
    description: 'Tender pork tenderloin bulgogi stir-fried with onion and cabbage. Served with side dishes and soup.',
    category: 'Sets',
    pricesCentavos: {
      MenuChannel.dineIn: 24000,
      MenuChannel.takeaway: 24000,
      MenuChannel.grabFood: 26000,
      MenuChannel.foodpanda: 26000,
    },
  ),
  MenuItem(
    id: 'korean-kimchi-pancake',
    name: 'Korean Kimchi Pancake',
    description: 'Crispy savory pancake with aged house kimchi and spring onions, accompanied by seasoned soy dip.',
    category: 'Snacks',
    pricesCentavos: {
      MenuChannel.dineIn: 15000,
      MenuChannel.takeaway: 15000,
      MenuChannel.grabFood: 17000,
      MenuChannel.foodpanda: 17000,
    },
  ),
];

const sampleAureliasMenu = <MenuItem>[
  MenuItem(
    id: 'paa-inasal',
    name: 'Paa Inasal',
    description: 'Grilled chicken leg quarter, with rice',
    category: 'Sets',
    pricesCentavos: {MenuChannel.dineIn: 17900, MenuChannel.grabFood: 20500},
  ),
  MenuItem(
    id: 'pecho-inasal',
    name: 'Pecho Inasal',
    description: 'Grilled chicken breast, with rice',
    category: 'Sets',
    pricesCentavos: {MenuChannel.dineIn: 18900, MenuChannel.grabFood: 21500},
  ),
  MenuItem(
    id: 'pork-inasal',
    name: 'Pork Inasal',
    description: 'Grilled pork belly, with rice',
    category: 'Rice bowls',
    pricesCentavos: {MenuChannel.dineIn: 19900, MenuChannel.grabFood: 22900},
  ),
  MenuItem(
    id: 'halo-halo',
    name: 'Halo-halo',
    description: 'Shaved ice dessert',
    category: 'Snacks',
    pricesCentavos: {MenuChannel.dineIn: 10900, MenuChannel.grabFood: 12900},
  ),
];

final sampleMenu = sampleGamcheonMenu;

List<MenuItem> sampleMenuForBrand(String? brandCodeOrId) {
  final norm = (brandCodeOrId ?? '').toLowerCase();
  if (norm.contains('ai') || norm.contains('aurelia')) {
    return sampleAureliasMenu;
  }
  return sampleGamcheonMenu;
}
