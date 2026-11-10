import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/new_order/providers/menu_providers.dart';

/// Search input bar with animated focus ring, debounce, clear button,
/// and tactile "Unavailable" navigation button.
class CatalogSearchBar extends ConsumerStatefulWidget {
  const CatalogSearchBar({super.key});

  @override
  ConsumerState<CatalogSearchBar> createState() => _CatalogSearchBarState();
}

class _CatalogSearchBarState extends ConsumerState<CatalogSearchBar> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _searchDebounce;
  bool _searchFocused = false;
  bool _unavailablePressed = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _searchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        ref.read(menuSearchProvider.notifier).set(query);
      }
    });
  }

  void _onClearSearch() {
    _searchController.clear();
    _searchDebounce?.cancel();
    ref.read(menuSearchProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(menuSearchProvider, (_, query) {
      if (_searchController.text != query && !_searchFocusNode.hasFocus) {
        _searchController.text = query;
      }
    });

    final hideUnavailable = ref.watch(hideUnavailableProvider);

    return Row(
      children: [
        // Search bar with animated focus ring & debounce
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            height: 44.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(KkfcRadius.sm),
              border: Border.all(
                color: _searchFocused
                    ? const Color(0xFF1F66C9) // Focus Blue
                    : const Color(0xFF76849A),
                width: _searchFocused ? 1.5 : 1.0,
              ),
              boxShadow: _searchFocused
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1F66C9).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: 14.0,
                color: Color(0xFF19293E),
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search',
                hintStyle: const TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: 14.0,
                  color: Color(0xFF76849A),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF586579),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _onClearSearch,
                      )
                    : null,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: KkfcSpace.s12),

        // Unavailable filter toggle button with tactile press
        AnimatedScale(
          scale: _unavailablePressed ? KkfcMotion.pressScale : 1.0,
          duration: KkfcMotion.durPress,
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('unavailable-filter-button'),
              borderRadius: BorderRadius.circular(KkfcRadius.sm),
              onTapDown: (_) => setState(() => _unavailablePressed = true),
              onTapCancel: () => setState(() => _unavailablePressed = false),
              onTapUp: (_) => setState(() => _unavailablePressed = false),
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(hideUnavailableProvider.notifier).toggle();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                height: 44.0,
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: hideUnavailable
                      ? (_unavailablePressed
                          ? const Color(0xFF151E2E)
                          : const Color(0xFF1D2940))
                      : (_unavailablePressed
                          ? const Color(0xFFEEE8DC)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  border: Border.all(
                    color: hideUnavailable
                        ? const Color(0xFF1D2940)
                        : (_unavailablePressed
                            ? const Color(0xFF19293E)
                            : const Color(0xFF76849A)),
                    width: 1.0,
                  ),
                  boxShadow: hideUnavailable
                      ? [
                          BoxShadow(
                            color:
                                const Color(0xFF1D2940).withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hideUnavailable
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: hideUnavailable
                          ? Colors.white
                          : const Color(0xFF19293E),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Unavailable',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: hideUnavailable
                            ? Colors.white
                            : const Color(0xFF19293E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
