import 'package:mobile/core/models/brand_models.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_lane.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/shared/data/models/kitchen_ticket_data.dart';
import 'package:mobile/shared/widgets/status_badge/kkfc_status.dart';

/// Sample kitchen board tickets matching the KDS reference design.
const List<KitchenBoardTicket> sampleKitchenBoardTickets = [
  KitchenBoardTicket(
    kitchenTicketId: '00000000-0000-4000-8000-000000000016',
    orderId: '00000000-0000-4000-8000-000000000116',
    orderCode: 'ORD-2026-1105-016',
    lane: KitchenBoardLane.queued,
    rawStatus: 'QUEUED',
    sentToKitchenLabel: '7:39 PM',
    preparationStartedLabel: 'Not started',
    data: KitchenTicketData(
      ticketNumber: 'T-016',
      elapsed: Duration(minutes: 2),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.queued,
      channel: 'Takeaway',
      reference: 'Call: Ana',
      brand: AssignedBrand(id: 'brand-kk', code: 'KK', name: 'King Kungs Kafé'),
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Iced Sea Salt Cream Latte',
          orderItemId: '00000000-0000-4000-8000-000000000216',
          modifiers: [
            '50% Less Sweet',
            '22oz Large Cup',
            'Note: Separate straws',
          ],
        ),
      ],
      paymentStatus: 'Paid',
    ),
  ),
  KitchenBoardTicket(
    kitchenTicketId: '00000000-0000-4000-8000-000000000015',
    orderId: '00000000-0000-4000-8000-000000000115',
    orderCode: 'ORD-2026-1105-015',
    lane: KitchenBoardLane.preparing,
    rawStatus: 'PREPARING',
    sentToKitchenLabel: '7:35 PM',
    preparationStartedLabel: '7:37 PM',
    data: KitchenTicketData(
      ticketNumber: 'T-015',
      elapsed: Duration(minutes: 6),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.preparing,
      channel: 'Dine-in',
      reference: 'Table 4',
      brand: AssignedBrand(
        id: 'brand-ai',
        code: 'AI',
        name: "Aurelia's Inasal",
      ),
      items: [
        KitchenTicketItem(
          quantity: 1,
          name: "Aurelia's Chicken Inasal Pecho",
          orderItemId: '00000000-0000-4000-8000-000000000215',
          modifiers: [
            'Toasted Garlic Inasal Rice',
            'Note: Extra calamansi please',
          ],
        ),
      ],
      paymentStatus: 'Unpaid',
    ),
  ),
  KitchenBoardTicket(
    kitchenTicketId: '00000000-0000-4000-8000-000000000014',
    orderId: '00000000-0000-4000-8000-000000000114',
    orderCode: 'ORD-2026-1105-014',
    lane: KitchenBoardLane.ready,
    rawStatus: 'READY',
    sentToKitchenLabel: '7:29 PM',
    preparationStartedLabel: '7:31 PM',
    data: KitchenTicketData(
      ticketNumber: 'T-014',
      elapsed: Duration(minutes: 12),
      age: KitchenTicketAge.onTime,
      status: KkfcStatus.ready,
      channel: 'GrabFood',
      reference: 'Ref GF-993821',
      brand: AssignedBrand(id: 'brand-gc', code: 'GC', name: 'Gamcheon'),
      items: [
        KitchenTicketItem(
          quantity: 2,
          name: 'Gamcheon Samgyupsal Rice Bowl',
          orderItemId: '00000000-0000-4000-8000-000000000214',
          modifiers: [
            'Garlic Butter Rice',
            'Spicy Fire Garlic',
            'Note: Well done crispy pork',
          ],
        ),
        KitchenTicketItem(
          quantity: 1,
          name: 'Korean Kimchi Pancake',
          orderItemId: '00000000-0000-4000-8000-000000000213',
          modifiers: ['Dipping Sauce: Sweet Soy'],
        ),
      ],
      paymentStatus: 'Paid',
    ),
  ),
];
