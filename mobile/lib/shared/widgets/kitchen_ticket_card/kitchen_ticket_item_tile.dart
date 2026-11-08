import 'package:flutter/material.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';

class KitchenTicketItemTile extends StatelessWidget {
  const KitchenTicketItemTile({super.key, required this.item});

  final KitchenTicketItem item;

  @override
  Widget build(BuildContext context) {
    final notes = <String>[];
    final regularMods = <String>[];

    for (final mod in item.modifiers) {
      final trimmed = mod.trim();
      if (trimmed.toLowerCase().startsWith('note:') ||
          trimmed.toLowerCase().startsWith('note ')) {
        notes.add(trimmed);
      } else {
        regularMods.add(trimmed);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            '${item.quantity}×',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF102A43),
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF102A43),
                  height: 1.2,
                ),
              ),
              if (regularMods.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    regularMods.join(' · '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                ),
              for (final note in notes)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      note,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF102A43),
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
