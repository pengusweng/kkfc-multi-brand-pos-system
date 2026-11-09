import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/app/routes.dart';
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

        // Unavailable button with tactile press
        AnimatedScale(
          scale: _unavailablePressed ? KkfcMotion.pressScale : 1.0,
          duration: KkfcMotion.durPress,
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(KkfcRadius.sm),
              onTapDown: (_) => setState(() => _unavailablePressed = true),
              onTapCancel: () => setState(() => _unavailablePressed = false),
              onTapUp: (_) => setState(() => _unavailablePressed = false),
              onTap: () => context.go(AppRoutes.availability),
              child: Ink(
                height: 44.0,
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                decoration: BoxDecoration(
                  color: _unavailablePressed
                      ? const Color(0xFFEEE8DC)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  border: Border.all(
                    color: _unavailablePressed
                        ? const Color(0xFF19293E)
                        : const Color(0xFF76849A),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block_outlined,
                      size: 18,
                      color: Color(0xFF19293E),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Unavailable',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF19293E),
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
