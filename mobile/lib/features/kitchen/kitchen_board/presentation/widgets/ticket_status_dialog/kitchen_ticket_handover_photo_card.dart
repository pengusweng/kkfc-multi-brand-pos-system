import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile/app/theme/tokens.dart';
import 'package:mobile/app/theme/typography.dart';

/// Data representation for an attached photo evidence item.
class HandoverPhotoEvidence {
  const HandoverPhotoEvidence({
    required this.name,
    this.path,
    this.bytes,
  });

  final String name;
  final String? path;
  final Uint8List? bytes;
}

/// Photo evidence card for delivery orders (foodpanda / GrabFood).
///
/// Prompts the user to capture/upload up to [maxPhotos] photos before
/// confirming the handover.
class KitchenTicketHandoverPhotoCard extends StatelessWidget {
  const KitchenTicketHandoverPhotoCard({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
    this.maxPhotos = 5,
  });

  final List<HandoverPhotoEvidence> photos;
  final VoidCallback onAddPhoto;
  final ValueChanged<int> onRemovePhoto;
  final int maxPhotos;

  bool get _hasPhotos => photos.isNotEmpty;
  bool get _canAddMore => photos.length < maxPhotos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KkfcSpace.s16),
      decoration: BoxDecoration(
        color: KkfcColors.surface,
        borderRadius: BorderRadius.circular(KkfcRadius.md),
        border: Border.all(
          color: KkfcColors.border,
          width: KkfcBorderWidth.thin,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Icon(
                Icons.image_outlined,
                size: 20,
                color: KkfcColors.ink,
              ),
              const SizedBox(width: KkfcSpace.s8),
              const Text(
                'Photo evidence',
                style: TextStyle(
                  fontFamily: KkfcFonts.ibmPlexSans,
                  fontSize: KkfcTextSizes.textLg,
                  fontWeight: KkfcFontWeights.bold,
                  color: KkfcColors.ink,
                ),
              ),
              const Spacer(),
              if (_hasPhotos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KkfcSpace.s8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: KkfcColors.successBg,
                    borderRadius: BorderRadius.circular(KkfcRadius.full),
                    border: Border.all(
                      color: KkfcColors.success.withValues(alpha: 0.35),
                      width: KkfcBorderWidth.thin,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: KkfcColors.success,
                      ),
                      SizedBox(width: KkfcSpace.s4),
                      Text(
                        'Attached',
                        style: TextStyle(
                          fontFamily: KkfcFonts.ibmPlexSans,
                          fontSize: KkfcTextSizes.textXs,
                          fontWeight: KkfcFontWeights.bold,
                          color: KkfcColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: KkfcSpace.s8),

          // Subtitle / Helper text matching reference design
          const Text(
            'Sample evidence only. Real image upload and persistence are not verified.',
            style: TextStyle(
              fontFamily: KkfcFonts.ibmPlexSans,
              fontSize: KkfcTextSizes.textSm,
              fontWeight: KkfcFontWeights.regular,
              color: KkfcColors.ink2,
              height: 1.35,
            ),
          ),
          const SizedBox(height: KkfcSpace.s12),

          // Photos list or empty upload action
          if (!_hasPhotos)
            SizedBox(
              width: double.infinity,
              height: KkfcSizing.controlMd,
              child: OutlinedButton(
                key: const ValueKey('kitchen-ticket-handover-add-photo-button'),
                onPressed: onAddPhoto,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KkfcColors.ink,
                  side: const BorderSide(
                    color: KkfcColors.borderStrong,
                    width: KkfcBorderWidth.thin,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KkfcRadius.sm),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_outlined,
                      size: 20,
                      color: KkfcColors.ink,
                    ),
                    SizedBox(width: KkfcSpace.s8),
                    Text(
                      'Attach photo',
                      style: TextStyle(
                        fontFamily: KkfcFonts.ibmPlexSans,
                        fontSize: KkfcTextSizes.textBase,
                        fontWeight: KkfcFontWeights.bold,
                        color: KkfcColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: KkfcSpace.s8,
              runSpacing: KkfcSpace.s8,
              children: [
                for (var i = 0; i < photos.length; i++)
                  _PhotoThumbnailItem(
                    index: i,
                    photo: photos[i],
                    onRemove: () => onRemovePhoto(i),
                  ),
                if (_canAddMore)
                  _AddMoreThumbnailButton(
                    currentCount: photos.length,
                    maxPhotos: maxPhotos,
                    onTap: onAddPhoto,
                  ),
              ],
            ),
            const SizedBox(height: KkfcSpace.s8),
            Text(
              '${photos.length} of $maxPhotos photos attached',
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textXs,
                fontWeight: KkfcFontWeights.medium,
                color: KkfcColors.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumbnailItem extends StatelessWidget {
  const _PhotoThumbnailItem({
    required this.index,
    required this.photo,
    required this.onRemove,
  });

  final int index;
  final HandoverPhotoEvidence photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: KkfcColors.canvas,
            borderRadius: BorderRadius.circular(KkfcRadius.sm),
            border: Border.all(
              color: KkfcColors.border,
              width: KkfcBorderWidth.thin,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: photo.bytes != null
              ? Image.memory(
                  photo.bytes!,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 30,
                      color: KkfcColors.ticketMuted,
                    ),
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 30,
                    color: KkfcColors.ticketMuted,
                  ),
                ),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: InkWell(
            key: ValueKey('kitchen-ticket-handover-remove-photo-$index'),
            onTap: onRemove,
            borderRadius: BorderRadius.circular(KkfcRadius.full),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: KkfcColors.ink,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.close,
                size: 12,
                color: KkfcColors.onSolid,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMoreThumbnailButton extends StatelessWidget {
  const _AddMoreThumbnailButton({
    required this.currentCount,
    required this.maxPhotos,
    required this.onTap,
  });

  final int currentCount;
  final int maxPhotos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey('kitchen-ticket-handover-add-photo-button'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(KkfcRadius.sm),
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: KkfcColors.canvas,
          borderRadius: BorderRadius.circular(KkfcRadius.sm),
          border: Border.all(
            color: KkfcColors.borderStrong,
            width: KkfcBorderWidth.thin,
            strokeAlign: BorderSide.strokeAlignCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_a_photo_outlined,
              size: 22,
              color: KkfcColors.ink2,
            ),
            const SizedBox(height: KkfcSpace.s4),
            Text(
              '$currentCount/$maxPhotos',
              style: const TextStyle(
                fontFamily: KkfcFonts.ibmPlexSans,
                fontSize: KkfcTextSizes.textXs,
                fontWeight: KkfcFontWeights.medium,
                color: KkfcColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
