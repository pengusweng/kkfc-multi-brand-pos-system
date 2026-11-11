import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';
import 'package:mobile/features/kitchen/kitchen_board/data/models/kitchen_board_ticket.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_body.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_footer.dart';
import 'package:mobile/features/kitchen/kitchen_board/presentation/widgets/ticket_status_dialog/kitchen_ticket_handover_photo_card.dart';

/// Stateful coordinator for the Handover modal workflow.
///
/// Ensures the user cannot press `Confirm handover` until:
/// 1. All 3 outgoing checklist items have been ticked.
/// 2. For delivery orders (foodpanda / GrabFood), at least 1 photo evidence
///    has been uploaded (maximum of 5 photos).
class KitchenTicketHandoverView extends StatefulWidget {
  const KitchenTicketHandoverView({
    super.key,
    required this.ticket,
    required this.isActionLoading,
    this.isActionEnabled = true,
    required this.onHandover,
    this.imagePicker,
    this.onPickImage,
    this.initialPhotos,
  });

  final KitchenBoardTicket ticket;
  final bool isActionLoading;
  final bool isActionEnabled;
  final VoidCallback? onHandover;
  final ImagePicker? imagePicker;
  final Future<XFile?> Function(ImageSource source)? onPickImage;
  final List<HandoverPhotoEvidence>? initialPhotos;

  static const int maxPhotos = 5;

  @override
  State<KitchenTicketHandoverView> createState() =>
      _KitchenTicketHandoverViewState();
}

class _KitchenTicketHandoverViewState extends State<KitchenTicketHandoverView> {
  final Map<HandoverCheckItem, bool> _checklist = {
    for (final item in HandoverCheckItem.values) item: false,
  };

  late final List<HandoverPhotoEvidence> _photos;
  late final ImagePicker _imagePicker;

  @override
  void initState() {
    super.initState();
    _photos =
        List<HandoverPhotoEvidence>.from(widget.initialPhotos ?? const []);
    _imagePicker = widget.imagePicker ?? ImagePicker();
  }

  bool get _allChecked =>
      HandoverCheckItem.values.every((item) => _checklist[item] == true);

  bool get _isDelivery => widget.ticket.isDelivery;

  bool get _canHandover {
    if (!widget.isActionEnabled) return false;
    if (!_allChecked) return false;
    if (_isDelivery && _photos.isEmpty) return false;
    return true;
  }

  void _handleToggle(HandoverCheckItem item) {
    setState(() {
      _checklist[item] = !(_checklist[item] ?? false);
    });
  }

  Future<void> _handlePickPhoto() async {
    if (_photos.length >= KitchenTicketHandoverView.maxPhotos) return;

    if (widget.onPickImage != null) {
      final file = await widget.onPickImage!(ImageSource.camera);
      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        setState(() {
          _photos.add(
            HandoverPhotoEvidence(
              name: file.name,
              path: file.path,
              bytes: bytes,
            ),
          );
        });
      }
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: KkfcColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(KkfcRadius.lg),
        ),
      ),
      builder: (bottomSheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KkfcSpace.s16,
            vertical: KkfcSpace.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: KkfcColors.ink,
                ),
                title: const Text(
                  'Take photo',
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontWeight: KkfcFontWeights.medium,
                    color: KkfcColors.ink,
                  ),
                ),
                onTap: () =>
                    Navigator.of(bottomSheetContext).pop(ImageSource.camera),
              ),
              const Divider(color: KkfcColors.divider, height: 1),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: KkfcColors.ink,
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(
                    fontFamily: KkfcFonts.ibmPlexSans,
                    fontWeight: KkfcFontWeights.medium,
                    color: KkfcColors.ink,
                  ),
                ),
                onTap: () =>
                    Navigator.of(bottomSheetContext).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null && mounted) {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null && mounted) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _photos.add(
            HandoverPhotoEvidence(
              name: picked.name,
              path: picked.path,
              bytes: bytes,
            ),
          );
        });
      }
    }
  }

  void _handleRemovePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      setState(() {
        _photos.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: KitchenTicketHandoverBody(
            ticket: widget.ticket,
            checklist: _checklist,
            onToggleItem: _handleToggle,
            photos: _photos,
            onAddPhoto: _handlePickPhoto,
            onRemovePhoto: _handleRemovePhoto,
            maxPhotos: KitchenTicketHandoverView.maxPhotos,
          ),
        ),
        KitchenTicketHandoverFooter(
          canHandover: _canHandover,
          isChecklistComplete: _allChecked,
          isDelivery: _isDelivery,
          isPhotoAttached: _photos.isNotEmpty,
          isActionLoading: widget.isActionLoading,
          onConfirmHandover: _canHandover ? widget.onHandover : null,
        ),
      ],
    );
  }
}
