import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/consent.dart';
import '../providers/family_provider.dart';
import '../services/ocr_service.dart';
import 'ocr_review_screen.dart';

/// What the capture flow reports back to the records screen when it closes.
enum OcrCaptureOutcome {
  /// A record was saved from the review screen.
  saved,

  /// OCR failed or found no text. The records screen should open the manual
  /// add-record form.
  enterManually,
}

/// Modern Entry point for scanning a prescription or report (PRD F9).
class OcrCaptureScreen extends ConsumerStatefulWidget {
  const OcrCaptureScreen({super.key});

  @override
  ConsumerState<OcrCaptureScreen> createState() => _OcrCaptureScreenState();
}

class _OcrCaptureScreenState extends ConsumerState<OcrCaptureScreen> {
  final _picker = ImagePicker();
  final _ocr = const OcrService();
  bool _busy = false;
  bool _failed = false;

  Future<void> _capture(ImageSource source) async {
    if (_busy) return;
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _failed = false;
    });

    try {
      final picked = await _picker.pickImage(source: source);
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      final text = await _ocr.recognise(picked.path);
      if (!mounted) return;
      if (text.trim().isEmpty) {
        setState(() {
          _busy = false;
          _failed = true;
        });
        return;
      }

      setState(() => _busy = false);
      final saved = await navigator.push<bool>(
        MaterialPageRoute(
          builder: (_) => OcrReviewScreen(
            imagePath: picked.path,
            ocrText: text,
          ),
        ),
      );
      if (saved == true && mounted) {
        navigator.pop(OcrCaptureOutcome.saved);
      }
    } on Exception {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final consents = ref.watch(consentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.ocrTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: consents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.genericError)),
        data: (granted) {
          if (granted[ConsentPurpose.ocrProcessing] != true) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 48, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(l10n.ocrNeedsConsent, textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return _buildCapture(l10n);
        },
      ),
    );
  }

  Widget _buildCapture(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            // Scanner Viewfinder Card
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: _busy
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            l10n.ocrProcessing,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      )
                    : Icon(
                        Icons.document_scanner_rounded,
                        size: 80,
                        color: scheme.primary.withValues(alpha: 0.6),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Position Rx Slip or Report',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ocrIntro,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),

            if (!_busy) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _capture(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.ocrCamera, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _capture(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l10n.ocrGallery, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],

            if (_failed && !_busy) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      l10n.ocrFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(OcrCaptureOutcome.enterManually),
                      child: Text(l10n.ocrEnterManually),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
