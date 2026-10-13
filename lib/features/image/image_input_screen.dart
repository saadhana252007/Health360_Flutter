import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/router.dart';
import '../../core/api_client.dart';
import '../../data/repositories/checkup_repo.dart';
import '../../state/checkup_draft_provider.dart';
import '../result/result_screen.dart';

/// Image Input screen replicating Android `ImageInputActivity.kt` and `activity_image_input.xml`.
class ImageInputScreen extends ConsumerStatefulWidget {
  const ImageInputScreen({super.key, this.picker});

  /// Injected picker for unit testing.
  final ImagePicker? picker;

  @override
  ConsumerState<ImageInputScreen> createState() => _ImageInputScreenState();
}

class _ImageInputScreenState extends ConsumerState<ImageInputScreen> {
  late final ImagePicker _imagePicker;

  String? _selectedImageType;
  String? _selectedImagePath;
  bool _isSubmitting = false;

  final List<String> _imageTypeOptions = const ['Skin', 'Oral', 'Wound'];

  @override
  void initState() {
    super.initState();
    _imagePicker = widget.picker ?? ImagePicker();
    _loadFromDraft();
  }

  void _loadFromDraft() {
    final draft = ref.read(checkupDraftProvider);
    if (draft.imagePath != null) {
      _selectedImagePath = draft.imagePath;
    }
    if (draft.imageType != null) {
      final match = _imageTypeOptions.firstWhere(
        (opt) => opt.toLowerCase() == draft.imageType!.toLowerCase(),
        orElse: () => draft.imageType!,
      );
      _selectedImageType = match;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImagePath = pickedFile.path;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load image')));
      }
    }
  }

  void _clearImage() {
    setState(() {
      _selectedImagePath = null;
    });
    ref.read(checkupDraftProvider.notifier).clearImage();
  }

  void _skipImage() {
    if (_isSubmitting) return;
    _clearImage();
    _performSubmission(hasImage: false);
  }

  void _continueToSubmission() {
    if (_isSubmitting) return;

    final type = _selectedImageType?.trim() ?? '';
    final path = _selectedImagePath;

    if (type.isEmpty) {
      _showError('Select an image type');
      return;
    }

    if (path == null || path.isEmpty) {
      _showError('Select or capture an image');
      return;
    }

    ref
        .read(checkupDraftProvider.notifier)
        .setImage(path: path, imageType: type.toLowerCase());

    _performSubmission(hasImage: true);
  }

  Future<void> _performSubmission({required bool hasImage}) async {
    setState(() => _isSubmitting = true);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            hasImage
                ? 'Analyzing your checkup...'
                : 'Continuing without image analysis...',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

    try {
      final draft = ref.read(checkupDraftProvider);
      if (draft.patient == null ||
          draft.symptoms == null ||
          draft.vitals == null) {
        setState(() => _isSubmitting = false);
        return;
      }

      final repo = ref.read(checkupRepositoryProvider);

      final response = await repo.submitCheckup(draft);

      // Preserve vitals & symptoms for display before clearing draft
      final vitals = draft.vitals?.toJson();
      final symptoms = draft.symptoms;

      // Submission successful: clear the draft
      ref.read(checkupDraftProvider.notifier).clear();

      if (mounted) {
        setState(() => _isSubmitting = false);
        context.push(
          AppRoutes.result,
          extra: ResultScreenArgs(
            response: response,
            vitals: vitals,
            symptoms: symptoms,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final message = e is ApiException
            ? e.message
            : e.toString().replaceFirst('Exception: ', '');
        _showError(message);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        _selectedImagePath != null && File(_selectedImagePath!).existsSync();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Title & Subtitle ─────────────────────────────────
              const Text(
                'Image Check',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload an image for AI-assisted analysis',
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 28),

              // ── Image Type Dropdown ─────────────────────────────────────
              const Text(
                'Image Type',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedImageType,
                    isExpanded: true,
                    hint: const Text(
                      'Select image type',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xFF6B7280),
                    ),
                    items: _imageTypeOptions.map((type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedImageType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Image Preview Area ──────────────────────────────────────
              Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD5E5E7)),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: InkWell(
                              onTap: _clearImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: Color(0xFF006B6F),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No image selected',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // ── Take Photo Button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Choose from Gallery Button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text(
                    'Choose from Gallery',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Skip Image Button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _skipImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F2F2),
                    foregroundColor: const Color(0xFF006B6F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Skip Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Continue Button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _continueToSubmission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006B6F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
