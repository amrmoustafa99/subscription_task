import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'ad_content_validator.dart';
import 'app_theme.dart';
import 'local_video.dart';

const String kAdTextHint =
    'اكتب تفاصيل الإعلان هنا، واذكر السعر والمساحة وعدد الغرف ورقم التواصل';

const int _maxImages = 8;
const int _maxVideos = 4;

const Color _fieldBorder = Color(0xFFEEEEEE);
const Color _errorColor = Color(0xFFB42318);
const Color _errorBackground = Color(0xFFFDECEC);
const Color _warningColor = Color(0xFF8A5A00);
const Color _warningIconColor = Color(0xFFC48A12);

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F111111), blurRadius: 14, offset: Offset(0, 4)),
];

enum PropertyDealType {
  sale('بيع'),
  rent('إيجار'),
  exchange('بدل');

  const PropertyDealType(this.label);
  final String label;
}

class PropertyLocation {
  final String governorate;
  final String area;

  const PropertyLocation({required this.governorate, required this.area});

  String get label => '$area، $governorate';

  @override
  bool operator ==(Object other) {
    return other is PropertyLocation &&
        other.governorate == governorate &&
        other.area == area;
  }

  @override
  int get hashCode => Object.hash(governorate, area);
}

class AdDraft {
  final PropertyDealType dealType;
  final PropertyLocation location;
  final String text;
  final List<String> imagePaths;
  final List<String> videoPaths;

  const AdDraft({
    required this.dealType,
    required this.location,
    required this.text,
    required this.imagePaths,
    required this.videoPaths,
  });
}

class _MediaItem {
  final String id;
  final String path;
  final Uint8List? bytes;
  final bool isVideo;

  const _MediaItem({
    required this.id,
    required this.path,
    required this.isVideo,
    this.bytes,
  });
}

const Map<String, List<String>> _kuwaitAreas = {
  'العاصمة': [
    'مدينة الكويت',
    'الشرق',
    'القبلة',
    'الصوابر',
    'بنيد القار',
    'الدسمة',
    'الدعية',
    'الشامية',
    'الروضة',
    'العديلية',
    'الخالدية',
    'كيفان',
    'القرطبة',
    'السرة',
    'اليرموك',
    'الشويخ',
    'غرناطة',
    'الصليبيخات',
    'الدوحة',
  ],
  'حولي': [
    'حولي',
    'السالمية',
    'الرميثية',
    'بيان',
    'مشرف',
    'الجابرية',
    'الشعب',
    'الشهداء',
    'البدع',
    'السلوى',
    'الزهراء',
    'الصديق',
  ],
  'الفروانية': [
    'الفروانية',
    'خيطان',
    'العمرية',
    'الرابية',
    'الأندلس',
    'جليب الشيوخ',
    'الضجيج',
    'إشبيلية',
    'الرحاب',
  ],
  'الأحمدي': [
    'الأحمدي',
    'الفحيحيل',
    'المنقف',
    'أبو حليفة',
    'الفنطاس',
    'العقيلة',
    'المهبولة',
    'الرقة',
    'صباح الأحمد',
    'الوفرة',
  ],
  'مبارك الكبير': [
    'مبارك الكبير',
    'القرين',
    'العدان',
    'القصور',
    'المسايل',
    'صباح السالم',
    'أبو فطيرة',
  ],
  'الجهراء': [
    'الجهراء',
    'القصر',
    'النعيم',
    'النسيم',
    'تيماء',
    'الواحة',
    'العيون',
    'الصليبية',
    'سعد العبدالله',
  ],
};

class AddAdvertisementPage extends StatefulWidget {
  final int adValidityDays;

  const AddAdvertisementPage({super.key, required this.adValidityDays});

  @override
  State<AddAdvertisementPage> createState() => _AddAdvertisementPageState();
}

class _AddAdvertisementPageState extends State<AddAdvertisementPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey _typeKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _contentKey = GlobalKey();

  PropertyDealType? _dealType;
  PropertyLocation? _location;
  final List<_MediaItem> _images = [];
  final List<_MediaItem> _videos = [];
  List<AdValidationMessage> _contentMessages = const [];

  String? _typeError;
  String? _locationError;
  String? _mediaNotice;
  bool _mediaNoticeIsError = false;
  bool _validationArmed = false;
  bool _submitting = false;
  bool _pickingImages = false;
  bool _pickingVideos = false;
  bool _textFocused = false;
  Timer? _validateTimer;
  int _mediaSeed = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _validateTimer?.cancel();
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (!_validationArmed && !hasText) return;
    _validationArmed = true;
    _validateTimer?.cancel();
    _validateTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      setState(() {
        _contentMessages = AdContentValidator.validate(_textController.text);
      });
    });
  }

  Future<void> _reveal(GlobalKey key) async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    final target = key.currentContext;
    if (target == null || !target.mounted) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      alignment: 0.12,
      curve: Curves.easeOut,
    );
  }

  void _selectDealType(PropertyDealType type) {
    setState(() {
      _dealType = type;
      _typeError = null;
    });
  }

  Future<void> _pickLocation() async {
    final selected = await showModalBottomSheet<PropertyLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => _LocationSheet(selected: _location),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _location = selected;
      _locationError = null;
    });
  }

  Future<_MediaPick?> _pickMediaAction() {
    return showModalBottomSheet<_MediaPick>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 12),
                _SourceTile(
                  icon: Icons.photo_library_outlined,
                  label: 'صور من المعرض',
                  onTap: () =>
                      Navigator.of(context).pop(_MediaPick.galleryImage),
                ),
                const SizedBox(height: 8),
                _SourceTile(
                  icon: Icons.video_library_outlined,
                  label: 'فيديو من المعرض',
                  onTap: () =>
                      Navigator.of(context).pop(_MediaPick.galleryVideo),
                ),
                const SizedBox(height: 8),
                _SourceTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'التقاط صورة',
                  onTap: () =>
                      Navigator.of(context).pop(_MediaPick.cameraImage),
                ),
                const SizedBox(height: 8),
                _SourceTile(
                  icon: Icons.videocam_outlined,
                  label: 'تسجيل فيديو',
                  onTap: () =>
                      Navigator.of(context).pop(_MediaPick.cameraVideo),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMediaPicker() async {
    if (_images.length >= _maxImages && _videos.length >= _maxVideos) {
      setState(() {
        _mediaNotice = 'وصلت للحد الأقصى: $_maxImages صور و $_maxVideos فيديو';
        _mediaNoticeIsError = false;
      });
      return;
    }
    final action = await _pickMediaAction();
    if (!mounted || action == null) return;
    switch (action) {
      case _MediaPick.galleryImage:
        await _addImages(ImageSource.gallery);
      case _MediaPick.cameraImage:
        await _addImages(ImageSource.camera);
      case _MediaPick.galleryVideo:
        await _addVideo(ImageSource.gallery);
      case _MediaPick.cameraVideo:
        await _addVideo(ImageSource.camera);
    }
  }

  Future<void> _addImages(ImageSource source) async {
    if (_images.length >= _maxImages) {
      setState(() {
        _mediaNotice = 'الحد الأقصى للصور هو $_maxImages';
        _mediaNoticeIsError = false;
      });
      return;
    }

    setState(() {
      _pickingImages = true;
      _mediaNotice = null;
    });

    try {
      final remaining = _maxImages - _images.length;
      final List<XFile> files;
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 1600,
        );
        files = file == null ? const [] : [file];
      } else {
        files = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1600,
          limit: remaining,
        );
      }
      if (!mounted) return;

      final accepted = <_MediaItem>[];
      var failedRead = false;
      for (final file in files) {
        if (accepted.length >= remaining) break;
        if (_images.any((item) => item.path == file.path) ||
            accepted.any((item) => item.path == file.path)) {
          continue;
        }
        try {
          final bytes = await file.readAsBytes();
          accepted.add(
            _MediaItem(
              id: 'img-${_mediaSeed++}',
              path: file.path,
              bytes: bytes,
              isVideo: false,
            ),
          );
        } catch (_) {
          failedRead = true;
        }
      }

      setState(() {
        _images.addAll(accepted);
        _pickingImages = false;
        if (failedRead && accepted.isEmpty) {
          _mediaNotice = 'تعذر إضافة الصور، حاول مرة أخرى';
          _mediaNoticeIsError = true;
        } else if (files.length > remaining) {
          _mediaNotice = 'يمكن إضافة $_maxImages صور كحد أقصى';
          _mediaNoticeIsError = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickingImages = false;
        _mediaNotice = 'تعذر اختيار الصور، حاول مرة أخرى';
        _mediaNoticeIsError = true;
      });
    }
  }

  Future<void> _addVideo(ImageSource source) async {
    if (_videos.length >= _maxVideos) {
      setState(() {
        _mediaNotice = 'الحد الأقصى للفيديو هو $_maxVideos';
        _mediaNoticeIsError = false;
      });
      return;
    }

    setState(() {
      _pickingVideos = true;
      _mediaNotice = null;
    });

    try {
      final file = await _picker.pickVideo(source: source);
      if (!mounted) return;
      if (file == null) {
        setState(() => _pickingVideos = false);
        return;
      }
      if (_videos.any((item) => item.path == file.path)) {
        setState(() => _pickingVideos = false);
        return;
      }
      setState(() {
        _videos.add(
          _MediaItem(id: 'vid-${_mediaSeed++}', path: file.path, isVideo: true),
        );
        _pickingVideos = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pickingVideos = false;
        _mediaNotice = 'تعذر اختيار الفيديو، حاول مرة أخرى';
        _mediaNoticeIsError = true;
      });
    }
  }

  void _removeImage(String id) {
    setState(() {
      _images.removeWhere((item) => item.id == id);
      _mediaNotice = null;
    });
  }

  void _removeVideo(String id) {
    setState(() {
      _videos.removeWhere((item) => item.id == id);
      _mediaNotice = null;
    });
  }

  Future<void> _playVideo(_MediaItem item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _VideoDialog(path: item.path),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    _validateTimer?.cancel();

    final messages = AdContentValidator.validate(_textController.text);
    setState(() {
      _validationArmed = true;
      _contentMessages = messages;
      _typeError = _dealType == null ? 'يرجى اختيار نوع الإعلان' : null;
      _locationError = _location == null ? 'يرجى اختيار منطقة العقار' : null;
    });

    if (_typeError != null) {
      await _reveal(_typeKey);
      return;
    }
    if (_locationError != null) {
      await _reveal(_locationKey);
      return;
    }
    if (AdContentValidator.hasBlockingError(messages)) {
      await _reveal(_contentKey);
      return;
    }

    setState(() => _submitting = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _submitting = false);
      await _showSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر نشر الإعلان، حاول مرة أخرى',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
          ),
        ),
      );
    }
  }

  Future<void> _showSuccess() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                Text('تم نشر الإعلان', style: AppTextStyles.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'بإمكانك الآن إضافة عقار آخر',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'حسناً',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final compact = screenHeight < 720 || keyboardOpen;
    final media = <_MediaItem>[..._images, ..._videos];
    final floatingNotes = <_FloatNote>[
      if (_typeError != null) _FloatNote(_typeError!, isError: true),
      if (_locationError != null) _FloatNote(_locationError!, isError: true),
      for (final message in _contentMessages)
        _FloatNote(
          message.text,
          isError: message.severity == AdMessageSeverity.error,
        ),
    ];

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, compact ? 8 : 12, 16, 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final bannerHeight = compact ? 44.0 : 48.0;
                    final chipHeight = compact ? 42.0 : 46.0;
                    final locationHeight = compact ? 46.0 : 50.0;
                    final uploadHeight = compact ? 56.0 : 62.0;
                    final mediaHeight = media.isNotEmpty && !keyboardOpen
                        ? ((constraints.maxWidth - 14) / 2.4 * 0.74).clamp(
                            78.0,
                            108.0,
                          )
                        : 0.0;
                    final gapCount = mediaHeight > 0 ? 5 : 4;
                    final cap = keyboardOpen ? 132.0 : 220.0;
                    final blocks =
                        bannerHeight +
                        chipHeight +
                        locationHeight +
                        uploadHeight +
                        mediaHeight +
                        cap;
                    final spread = (constraints.maxHeight - blocks) / gapCount;
                    final gap = spread.clamp(
                      keyboardOpen ? 10.0 : 16.0,
                      keyboardOpen ? 14.0 : 28.0,
                    );
                    final textRoom =
                        constraints.maxHeight - (blocks - cap) - gap * gapCount;
                    final textHeight = textRoom.clamp(0.0, cap);

                    return Column(
                      children: [
                        _ValidityBanner(
                          days: widget.adValidityDays,
                          height: bannerHeight,
                        ),
                        SizedBox(height: gap),
                        KeyedSubtree(
                          key: _typeKey,
                          child: _DealTypeSelector(
                            selected: _dealType,
                            height: chipHeight,
                            onSelected: _selectDealType,
                          ),
                        ),
                        SizedBox(height: gap),
                        KeyedSubtree(
                          key: _locationKey,
                          child: _LocationField(
                            location: _location,
                            height: locationHeight,
                            error: _locationError,
                            onTap: _pickLocation,
                          ),
                        ),
                        SizedBox(height: gap),
                        KeyedSubtree(
                          key: _contentKey,
                          child: SizedBox(
                            height: textHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: _AdTextField(
                                    controller: _textController,
                                    focused: _textFocused,
                                    messages: _contentMessages,
                                    reserveBottom: floatingNotes.isEmpty
                                        ? 0
                                        : (textHeight * 0.42).clamp(52.0, 96.0),
                                    onFocusChange: (focused) {
                                      setState(() => _textFocused = focused);
                                    },
                                  ),
                                ),
                                if (floatingNotes.isNotEmpty)
                                  PositionedDirectional(
                                    start: 8,
                                    end: 8,
                                    bottom: 8,
                                    child: _FloatingNotes(
                                      notes: floatingNotes,
                                      maxHeight: (textHeight * 0.46).clamp(
                                        48.0,
                                        108.0,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        _UnifiedUpload(
                          imageCount: _images.length,
                          videoCount: _videos.length,
                          loading: _pickingImages || _pickingVideos,
                          height: uploadHeight,
                          notice: _mediaNotice,
                          noticeIsError: _mediaNoticeIsError,
                          onTap: _openMediaPicker,
                        ),
                        if (media.isNotEmpty && !keyboardOpen) ...[
                          SizedBox(height: gap),
                          _MediaStrip(
                            items: media,
                            onRemoveImage: _removeImage,
                            onRemoveVideo: _removeVideo,
                            onPlay: _playVideo,
                          ),
                        ],
                        const Spacer(),
                      ],
                    );
                  },
                ),
              ),
            ),
            _PublishBar(submitting: _submitting, onPublish: _submit),
          ],
        ),
      ),
    );
  }
}

enum _MediaPick { galleryImage, cameraImage, galleryVideo, cameraVideo }

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          if (canPop)
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.ultraLightGray,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.black,
                ),
              ),
            )
          else
            const SizedBox(width: 40, height: 40),
          Expanded(
            child: Text(
              'إضافة إعلان',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ValidityBanner extends StatelessWidget {
  final int days;
  final double height;

  const _ValidityBanner({required this.days, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'مدة صلاحية الإعلان',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.darkGray,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$days يوم',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DealTypeSelector extends StatelessWidget {
  final PropertyDealType? selected;
  final double height;
  final ValueChanged<PropertyDealType> onSelected;

  const _DealTypeSelector({
    required this.selected,
    required this.height,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < PropertyDealType.values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _DealChip(
                  label: PropertyDealType.values[i].label,
                  height: height,
                  selected: selected == PropertyDealType.values[i],
                  onTap: () => onSelected(PropertyDealType.values[i]),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DealChip extends StatelessWidget {
  final String label;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  const _DealChip({
    required this.label,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: height,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.white : AppColors.darkGray,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final PropertyLocation? location;
  final double height;
  final String? error;
  final VoidCallback onTap;

  const _LocationField({
    required this.location,
    required this.height,
    required this.error,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = location != null;
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Ink(
              height: height,
              decoration: BoxDecoration(
                color: hasError ? _errorBackground : AppColors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: hasError ? _errorColor : _fieldBorder,
                  width: hasError ? 1.3 : 1,
                ),
                boxShadow: _softShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: hasError
                          ? _errorColor
                          : hasValue
                          ? AppColors.primary
                          : AppColors.mediumGray,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hasValue ? location!.label : 'منطقة العقار',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: hasValue
                              ? AppColors.black
                              : AppColors.mediumGray,
                          fontWeight: hasValue
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: hasError ? _errorColor : AppColors.mediumGray,
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

class _FloatNote {
  final String text;
  final bool isError;

  const _FloatNote(this.text, {required this.isError});
}

class _AdTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool focused;
  final List<AdValidationMessage> messages;
  final double reserveBottom;
  final ValueChanged<bool> onFocusChange;

  const _AdTextField({
    required this.controller,
    required this.focused,
    required this.messages,
    required this.reserveBottom,
    required this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = messages.any(
      (message) => message.severity == AdMessageSeverity.error,
    );
    final hasWarning = messages.any(
      (message) => message.severity == AdMessageSeverity.warning,
    );
    final borderColor = hasError
        ? _errorColor
        : hasWarning
        ? _warningIconColor
        : focused
        ? AppColors.primary
        : _fieldBorder;

    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: borderColor,
            width: hasError || hasWarning || focused ? 1.4 : 1,
          ),
          boxShadow: _softShadow,
        ),
        child: TextField(
          key: const ValueKey('ad-text-field'),
          controller: controller,
          expands: true,
          maxLines: null,
          textAlignVertical: TextAlignVertical.top,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.black,
            fontSize: 15,
            height: 1.55,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: kAdTextHint,
            hintMaxLines: 3,
            maintainHintSize: false,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.mediumGray,
              fontWeight: FontWeight.w400,
              height: 1.55,
            ),
            contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 12 + reserveBottom),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _FloatingNotes extends StatelessWidget {
  final List<_FloatNote> notes;
  final double maxHeight;

  const _FloatingNotes({required this.notes, required this.maxHeight});

  @override
  Widget build(BuildContext context) {
    final hasError = notes.any((note) => note.isError);
    final accent = hasError ? _errorColor : _warningIconColor;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.16)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: accent),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Column(
                        children: [
                          for (var i = 0; i < notes.length; i++) ...[
                            if (i > 0) const SizedBox(height: 6),
                            _FieldNote(
                              text: notes[i].text,
                              isError: notes[i].isError,
                            ),
                          ],
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
    );
  }
}

class _FieldNote extends StatelessWidget {
  final String text;
  final bool isError;

  const _FieldNote({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? _errorColor : _warningColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
          size: 16,
          color: isError ? _errorColor : _warningIconColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _UnifiedUpload extends StatelessWidget {
  final int imageCount;
  final int videoCount;
  final bool loading;
  final double height;
  final String? notice;
  final bool noticeIsError;
  final VoidCallback onTap;

  const _UnifiedUpload({
    required this.imageCount,
    required this.videoCount,
    required this.loading,
    required this.height,
    required this.notice,
    required this.noticeIsError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imagesFull = imageCount >= _maxImages;
    final videosFull = videoCount >= _maxVideos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Opacity(
          opacity: imagesFull && videosFull ? 0.55 : 1,
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: loading ? null : onTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Ink(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: _fieldBorder),
                  boxShadow: _softShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(
                                Icons.file_upload_outlined,
                                size: 20,
                                color: AppColors.primary,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إضافة صور وفيديو',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Row(
                                children: [
                                  Text(
                                    'صور',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$imageCount من $_maxImages',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                      color: imagesFull
                                          ? AppColors.primary
                                          : AppColors.mediumGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '  ·  فيديو',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$videoCount من $_maxVideos',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                      color: videosFull
                                          ? AppColors.primary
                                          : AppColors.mediumGray,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 6),
          _FieldNote(text: notice!, isError: noticeIsError),
        ],
      ],
    );
  }
}

class _MediaStrip extends StatelessWidget {
  final List<_MediaItem> items;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onRemoveVideo;
  final ValueChanged<_MediaItem> onPlay;

  const _MediaStrip({
    required this.items,
    required this.onRemoveImage,
    required this.onRemoveVideo,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final viewport = constraints.maxWidth;
        final itemWidth = (viewport - gap * 1.4) / 2.4;
        final itemHeight = (itemWidth * 0.74).clamp(78.0, 108.0);
        return SizedBox(
          height: itemHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: gap),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: itemWidth,
                child: _MediaTile(
                  key: ValueKey(item.id),
                  item: item,
                  onRemove: () => item.isVideo
                      ? onRemoveVideo(item.id)
                      : onRemoveImage(item.id),
                  onPlay: item.isVideo ? () => onPlay(item) : null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final _MediaItem item;
  final VoidCallback onRemove;
  final VoidCallback? onPlay;

  const _MediaTile({
    super.key,
    required this.item,
    required this.onRemove,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: AppColors.ultraLightGray,
            child: item.isVideo
                ? _VideoThumbnail(path: item.path)
                : _ImagePreview(bytes: item.bytes),
          ),
          if (item.isVideo)
            Center(
              child: GestureDetector(
                onTap: onPlay,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          PositionedDirectional(
            top: 6,
            start: 6,
            child: Semantics(
              button: true,
              label: item.isVideo ? 'حذف الفيديو' : 'حذف الصورة',
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                    boxShadow: _softShadow,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final Uint8List? bytes;

  const _ImagePreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    final data = bytes;
    if (data == null || data.isEmpty) {
      return const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.mediumGray,
          size: 22,
        ),
      );
    }
    return Image.memory(
      data,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: AppColors.mediumGray,
            size: 22,
          ),
        );
      },
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final String path;

  const _VideoThumbnail({required this.path});

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final controller = await openLocalVideo(widget.path);
      await controller.setVolume(0);
      await controller.pause();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _failed) {
      return ColoredBox(
        color: const Color(0xFF2A2A2A),
        child: Center(
          child: _failed
              ? const SizedBox.shrink()
              : const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.white,
                  ),
                ),
        ),
      );
    }

    final size = controller.value.size;
    if (size.isEmpty) {
      return const ColoredBox(color: Color(0xFF2A2A2A));
    }

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _VideoDialog extends StatefulWidget {
  final String path;

  const _VideoDialog({required this.path});

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final controller = await openLocalVideo(widget.path);
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Dialog(
      backgroundColor: AppColors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: controller?.value.aspectRatio ?? 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (controller != null && controller.value.isInitialized)
                VideoPlayer(controller)
              else
                ColoredBox(
                  color: const Color(0xFF1C1C1C),
                  child: Center(
                    child: _failed
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'تعذر تشغيل الفيديو',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          )
                        : const CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                  ),
                ),
              PositionedDirectional(
                top: 8,
                start: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSheet extends StatefulWidget {
  final PropertyLocation? selected;

  const _LocationSheet({required this.selected});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, List<String>>> get _filtered {
    final query = _query.trim();
    final result = <MapEntry<String, List<String>>>[];
    for (final entry in _kuwaitAreas.entries) {
      if (query.isEmpty || entry.key.contains(query)) {
        result.add(MapEntry(entry.key, entry.value));
        continue;
      }
      final areas = entry.value.where((area) => area.contains(query)).toList();
      if (areas.isNotEmpty) {
        result.add(MapEntry(entry.key, areas));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cap = screenHeight * 0.78;
          final available = constraints.maxHeight;
          final height = !available.isFinite || available > cap
              ? cap
              : available;
          return SizedBox(
            height: height,
            child: Column(
              children: [
                const SizedBox(height: 10),
                const _SheetHandle(),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'اختيار منطقة العقار',
                      style: AppTextStyles.titleMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.ultraLightGray,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.black,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'ابحث عن المنطقة',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.mediumGray,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.mediumGray,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 36,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد نتائج',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.mediumGray,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          children: [
                            for (final group in _filtered) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
                                child: Text(
                                  group.key,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ),
                              for (final area in group.value)
                                _AreaTile(
                                  label: area,
                                  selected:
                                      widget.selected?.area == area &&
                                      widget.selected?.governorate == group.key,
                                  onTap: () {
                                    Navigator.of(context).pop(
                                      PropertyLocation(
                                        governorate: group.key,
                                        area: area,
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AreaTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: selected ? AppColors.primary : AppColors.black,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.ultraLightGray,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }
}

class _PublishBar extends StatelessWidget {
  final bool submitting;
  final VoidCallback onPublish;

  const _PublishBar({required this.submitting, required this.onPublish});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 28,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              key: const ValueKey('publish-ad'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              onPressed: submitting ? null : onPublish,
              child: submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: AppColors.white,
                      ),
                    )
                  : Text(
                      'نشر الإعلان',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
