import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/presentation/widgets/item_customization_dialog.dart';
import 'package:mobile/features/new_order/providers/brand_providers.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Opens the item customization popup dialog.
Future<bool?> openCustomize(
  BuildContext context,
  WidgetRef ref, {
  required MenuItem item,
  CartLine? editing,
}) async {
  final channel = ref.read(menuChannelProvider);
  final brand = ref.read(activeBrandProvider);

  return showItemCustomizationDialog(
    context,
    item: item,
    channel: channel,
    brandName: brand.name,
    editing: editing,
  );
}
