import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_update_service.dart';

/// A dismissible inline notice, never a modal or a prerequisite for ordering.
class OptionalUpdateNotice extends ConsumerStatefulWidget {
  const OptionalUpdateNotice({super.key});

  @override
  ConsumerState<OptionalUpdateNotice> createState() =>
      _OptionalUpdateNoticeState();
}

class _OptionalUpdateNoticeState extends ConsumerState<OptionalUpdateNotice> {
  bool _opening = false;
  bool _downloadFailed = false;

  @override
  Widget build(BuildContext context) {
    final update = ref.watch(availableAppUpdateProvider).asData?.value;
    final dismissed = ref.watch(dismissedAppUpdateProvider);
    if (update == null || update.buildNumber == dismissed) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('An app update is available'),
                  if (_downloadFailed)
                    const Text(
                      'Could not open the download. You can try again later.',
                    ),
                  TextButton.icon(
                    onPressed: _opening
                        ? null
                        : () async {
                            setState(() {
                              _opening = true;
                              _downloadFailed = false;
                            });
                            final opened = await ref
                                .read(appUpdateServiceProvider)
                                .download(update);
                            if (mounted) {
                              setState(() {
                                _opening = false;
                                _downloadFailed = !opened;
                              });
                            }
                          },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download update'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Dismiss update',
              onPressed: () {
                ref
                    .read(dismissedAppUpdateProvider.notifier)
                    .dismiss(update.buildNumber);
                ref.read(appUpdateServiceProvider).dismiss(update);
              },
              icon: const Icon(Icons.close, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
