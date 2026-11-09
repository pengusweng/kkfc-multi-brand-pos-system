import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/data/models/menu_models.dart';
import 'package:mobile/features/new_order/data/repositories/menu_item_modifier_repository.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Shows the item customization modal popup matching the visual design.
/// Returns true if the item was added or updated in the cart.
Future<bool?> showItemCustomizationDialog(
  BuildContext context, {
  required MenuItem item,
  required MenuChannel channel,
  required String brandName,
  CartLine? editing,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) => ItemCustomizationDialog(
      item: item,
      channel: channel,
      brandName: brandName,
      editing: editing,
    ),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ItemCustomizationDialog extends ConsumerStatefulWidget {
  const ItemCustomizationDialog({
    super.key,
    required this.item,
    required this.channel,
    required this.brandName,
    this.editing,
  });

  final MenuItem item;
  final MenuChannel channel;
  final String brandName;
  final CartLine? editing;

  @override
  ConsumerState<ItemCustomizationDialog> createState() =>
      _ItemCustomizationDialogState();
}

class _ItemCustomizationDialogState
    extends ConsumerState<ItemCustomizationDialog> {
  late MenuItem _item;
  late final Map<String, String> _selections;
  late int _quantity;
  late final TextEditingController _kitchenNoteController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _quantity = widget.editing?.quantity ?? 1;
    _kitchenNoteController = TextEditingController(
      text: widget.editing?.kitchenNote ?? '',
    );

    _selections = {
      for (final g in _item.modifierGroups)
        g.id: widget.editing?.selections[g.id] ?? g.defaultOptionId,
    };

    _loadAdditionalModifiersIfNeeded();
  }

  Future<void> _loadAdditionalModifiersIfNeeded() async {
    // If the item has no modifier groups, attempt to load add-ons from repository.
    if (_item.modifierGroups.isEmpty) {
      try {
        final addOns = await ref
            .read(menuItemModifierRepositoryProvider)
            .getForMenuItem(_item.id);
        if (mounted && addOns.isNotEmpty) {
          setState(() {
            _item = _item.withModifierGroups(addOns);
            for (final g in addOns) {
              _selections[g.id] =
                  widget.editing?.selections[g.id] ?? g.defaultOptionId;
            }
          });
        }
      } catch (_) {
        // Mock / offline fallback: keep existing groups
      }
    }
  }

  @override
  void dispose() {
    _kitchenNoteController.dispose();
    super.dispose();
  }

  int get _basePriceCentavos => _item.priceFor(widget.channel);

  int get _modifiersDeltaCentavos {
    var sum = 0;
    for (final g in _item.modifierGroups) {
      final selectedId = _selections[g.id] ?? g.defaultOptionId;
      sum += g.optionById(selectedId).priceDeltaCentavos;
    }
    return sum;
  }

  int get _unitPriceCentavos => _basePriceCentavos + _modifiersDeltaCentavos;

  int get _totalPriceCentavos => _unitPriceCentavos * _quantity;

  void _submit() {
    if (_submitting) return;
    _submitting = true;

    HapticFeedback.mediumImpact();

    final note = _kitchenNoteController.text.trim();
    final noteOrNull = note.isEmpty ? null : note;

    final cartNotifier = ref.read(cartProvider.notifier);
    if (widget.editing == null) {
      cartNotifier.addConfigured(
        _item,
        Map<String, String>.from(_selections),
        _quantity,
        kitchenNote: noteOrNull,
      );
    } else {
      cartNotifier.updateLine(
        widget.editing!.id,
        Map<String, String>.from(_selections),
        _quantity,
        item: _item,
        kitchenNote: noteOrNull,
      );
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isEditing = widget.editing != null;

    final singleChoiceGroups = _item.modifierGroups
        .where((g) => !g.isAddOn)
        .toList();
    final addOnGroups = _item.modifierGroups.where((g) => g.isAddOn).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: mediaQuery.size.height * 0.92,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _item.name,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.ibmPlexSans,
                              fontSize: 18.0,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19293E),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.brandName} · ${widget.channel.label} price · ${formatPeso(_basePriceCentavos)}',
                            style: const TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 13.0,
                              color: Color(0xFF5A6778),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: const Color(0xFFDDD6C9)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8.0),
                          onTap: () => Navigator.of(context).pop(false),
                          child: const Center(
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFF19293E),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8DF)),

              // Scrollable Body
              Flexible(
                child: Container(
                  color: const Color(0xFFF7F3EC), // Warm Sand canvas ground
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        if (_item.description.isNotEmpty) ...[
                          Text(
                            _item.description,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 13.5,
                              height: 1.4,
                              color: Color(0xFF4A5568),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        // Radio modifier groups (single-choice)
                        for (final group in singleChoiceGroups) ...[
                          Row(
                            children: [
                              Text(
                                group.title,
                                style: const TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF19293E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F4E9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFA3D9B5),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Color(0xFF166B3A),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Chosen',
                                      style: TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF166B3A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final option in group.options) ...[
                            _RadioOptionTile(
                              label: option.label,
                              priceDeltaCentavos: option.priceDeltaCentavos,
                              isSelected: _selections[group.id] == option.id,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selections[group.id] = option.id;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 10),
                        ],

                        // Add-Ons group (checkboxes)
                        if (addOnGroups.isNotEmpty) ...[
                          Row(
                            children: [
                              const Text(
                                'Add-Ons',
                                style: TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF19293E),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECEFF3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFD2D9E2),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Text(
                                  'Optional',
                                  style: TextStyle(
                                    fontFamily: KkfcFonts.text,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF5A687A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final addOn in addOnGroups) ...[
                            Builder(
                              builder: (context) {
                                final isChecked =
                                    _selections[addOn.id] ==
                                    ModifierGroup.addOnOn;
                                final onOption = addOn.options.firstWhere(
                                  (o) => o.id == ModifierGroup.addOnOn,
                                  orElse: () => addOn.options.last,
                                );

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: _CheckboxOptionTile(
                                    label: addOn.title,
                                    priceDeltaCentavos:
                                        onOption.priceDeltaCentavos,
                                    isChecked: isChecked,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() {
                                        _selections[addOn.id] = isChecked
                                            ? ModifierGroup.addOnOff
                                            : ModifierGroup.addOnOn;
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 10),
                        ],

                        // Quantity Stepper
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Quantity',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF19293E),
                              ),
                            ),
                            Row(
                              children: [
                                _StepperButton(
                                  icon: Icons.remove,
                                  enabled: _quantity > 1,
                                  onTap: () {
                                    if (_quantity > 1) {
                                      HapticFeedback.lightImpact();
                                      setState(() => _quantity--);
                                    }
                                  },
                                ),
                                SizedBox(
                                  width: 44,
                                  child: Center(
                                    child: Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontFamily: KkfcFonts.ibmPlexSans,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF19293E),
                                        fontFeatures: [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                _StepperButton(
                                  icon: Icons.add,
                                  enabled: true,
                                  isDarkBorder: true,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _quantity++);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Kitchen note
                        const Row(
                          children: [
                            Text(
                              'Kitchen note ',
                              style: TextStyle(
                                fontFamily: KkfcFonts.ibmPlexSans,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF19293E),
                              ),
                            ),
                            Text(
                              '(optional)',
                              style: TextStyle(
                                fontFamily: KkfcFonts.text,
                                fontSize: 13.0,
                                color: Color(0xFF6B7787),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFF76849A),
                              width: 1.0,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: TextField(
                            controller: _kitchenNoteController,
                            maxLines: 2,
                            maxLength: 100,
                            style: const TextStyle(
                              fontFamily: KkfcFonts.text,
                              fontSize: 14.0,
                              color: Color(0xFF19293E),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'For example: no onions',
                              hintStyle: TextStyle(
                                fontFamily: KkfcFonts.text,
                                fontSize: 14.0,
                                color: Color(0xFF8C97A5),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Up to 100 characters.',
                          style: TextStyle(
                            fontFamily: KkfcFonts.text,
                            fontSize: 12.0,
                            color: Color(0xFF6B7787),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, thickness: 1, color: Color(0xFFEDE8DF)),

              // Footer: Action Button
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xFFA8562A), // Burnished Copper
                      borderRadius: BorderRadius.circular(10.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10.0),
                        onTap: _submit,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isEditing ? 'Update item' : 'Add to order',
                                style: const TextStyle(
                                  fontFamily: KkfcFonts.ibmPlexSans,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                child: Text(
                                  formatPeso(_totalPriceCentavos),
                                  key: ValueKey(
                                    'dialog-total-$_totalPriceCentavos',
                                  ),
                                  style: const TextStyle(
                                    fontFamily: KkfcFonts.ibmPlexSans,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioOptionTile extends StatelessWidget {
  const _RadioOptionTile({
    required this.label,
    required this.priceDeltaCentavos,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int priceDeltaCentavos;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE7ECF4) : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF19293E)
                  : const Color(0xFF76849A),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Custom radio circle
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF19293E)
                        : const Color(0xFF76849A),
                    width: isSelected ? 2.0 : 1.5,
                  ),
                  color: Colors.white,
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF19293E),
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF19293E),
                  ),
                ),
              ),
              if (priceDeltaCentavos > 0)
                Text(
                  '+${formatPeso(priceDeltaCentavos)}',
                  style: const TextStyle(
                    fontFamily: KkfcFonts.mono,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C4858),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxOptionTile extends StatelessWidget {
  const _CheckboxOptionTile({
    required this.label,
    required this.priceDeltaCentavos,
    required this.isChecked,
    required this.onTap,
  });

  final String label;
  final int priceDeltaCentavos;
  final bool isChecked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFFE7ECF4) : Colors.white,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF19293E)
                  : const Color(0xFF76849A),
              width: isChecked ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: isChecked
                        ? const Color(0xFF19293E)
                        : const Color(0xFF76849A),
                    width: isChecked ? 2.0 : 1.5,
                  ),
                  color: isChecked ? const Color(0xFF19293E) : Colors.white,
                ),
                child: isChecked
                    ? const Center(
                        child: Icon(Icons.check, size: 14, color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: KkfcFonts.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF19293E),
                  ),
                ),
              ),
              if (priceDeltaCentavos > 0)
                Text(
                  '+${formatPeso(priceDeltaCentavos)}',
                  style: const TextStyle(
                    fontFamily: KkfcFonts.mono,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3C4858),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.isDarkBorder = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  final bool isDarkBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkBorder
              ? const Color(0xFF76849A)
              : const Color(0xFFDDD6C9),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: enabled ? onTap : null,
          child: Center(
            child: Icon(
              icon,
              size: 16,
              color: enabled
                  ? const Color(0xFF19293E)
                  : const Color(0xFFA0AAB5),
            ),
          ),
        ),
      ),
    );
  }
}
