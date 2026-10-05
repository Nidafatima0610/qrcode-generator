import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/services/qr_content_actions.dart';
import 'package:qrcode_generator/core/services/qr_sharing_service.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/create/create_screen.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class QrPreviewScreen extends StatefulWidget {
  final QrItem item;
  final StorageService storageService;
  final VoidCallback? onEdit;

  const QrPreviewScreen({
    super.key,
    required this.item,
    required this.storageService,
    this.onEdit,
  });

  @override
  State<QrPreviewScreen> createState() => _QrPreviewScreenState();
}

class _QrPreviewScreenState extends State<QrPreviewScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;
  bool _showRawPayload = false;
  late QrItem _currentItem;
  late bool _isFavorite;
  late QrExportMode _exportMode;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    // Check current favorite status from storage service
    final storedItem = widget.storageService.history
        .firstWhere((e) => e.id == widget.item.id, orElse: () => widget.item);
    _isFavorite = storedItem.isFavorite;

    // Load default export mode from settings
    _exportMode = QrExportMode.fromString(widget.storageService.defaultExportMode);
  }

  Future<void> _toggleFavorite() async {
    final newStatus = await widget.storageService.toggleFavorite(_currentItem.id);
    setState(() => _isFavorite = newStatus);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Added "${_currentItem.title}" to Favorites'
                : 'Removed "${_currentItem.title}" from Favorites',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  Future<void> _checkContrastAndProceed(Future<void> Function() onProceed) async {
    if (_currentItem.customization.hasSufficientContrast) {
      await onProceed();
      return;
    }

    final ratio = _currentItem.customization.contrastRatio.toStringAsFixed(1);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Low Contrast Warning'),
          ],
        ),
        content: Text(
          'This QR code has low foreground/background contrast ($ratio:1, recommended ≥ 3.0:1).\n\nSome scanners may have trouble scanning it. Would you like to switch to High Contrast before exporting, or proceed anyway?',
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'proceed'),
            child: const Text('Proceed Anyway'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, 'fix'),
            child: const Text('Fix to High Contrast'),
          ),
        ],
      ),
    );

    if (action == 'fix') {
      _applyHighContrast();
      await Future.delayed(const Duration(milliseconds: 150));
      await onProceed();
    } else if (action == 'proceed') {
      await onProceed();
    }
  }

  void _applyHighContrast() async {
    final updated = _currentItem.copyWith(
      customization: _currentItem.customization.copyWith(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        errorCorrectionLevel: 'H',
      ),
    );
    await widget.storageService.saveItem(updated);
    setState(() {
      _currentItem = updated;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Applied High Contrast design (readable & scannable)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveQrImage() async {
    await _checkContrastAndProceed(() async {
      if (_isSaving) return;
      setState(() => _isSaving = true);

    try {
      final savedPath = await QrSharingService.saveQrImageToDevice(
        repaintBoundaryKey: _repaintBoundaryKey,
        title: _currentItem.title,
      );

      if (!mounted) return;

      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Saved QR image successfully!\nLocation: $savedPath',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save QR image. Please check permissions.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
    });
  }

  Future<void> _shareQrImage() async {
    await _checkContrastAndProceed(() async {
      if (_isSharing) return;
      setState(() => _isSharing = true);

    try {
      final success = await QrSharingService.shareQrImage(
        repaintBoundaryKey: _repaintBoundaryKey,
        title: _currentItem.title,
        additionalText: _currentItem.subtitle,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to prepare QR image for sharing'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
    });
  }

  void _copyContent() {
    QrSharingService.copyToClipboard(
      context,
      _currentItem.rawPayload,
      message: 'QR content copied to clipboard!',
    );
  }

  Future<void> _duplicateItem() async {
    final duplicate = _currentItem.copyWith(
      id: const Uuid().v4(),
      title: 'Copy of ${_currentItem.title}',
      createdAt: DateTime.now(),
      isFavorite: false,
    );
    await widget.storageService.saveItem(duplicate);
    setState(() {
      _currentItem = duplicate;
      _isFavorite = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated as "${duplicate.title}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _regenerateItem() {
    setState(() {
      _currentItem = _currentItem.copyWith(createdAt: DateTime.now());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code regenerated with updated timestamp'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _editItem() {
    if (widget.onEdit != null) {
      Navigator.pop(context);
      widget.onEdit!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreateScreen(
            storageService: widget.storageService,
            initialType: _currentItem.type,
            editingItem: _currentItem,
          ),
        ),
      );
    }
  }

  void _useAsTemplate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          storageService: widget.storageService,
          initialType: _currentItem.type,
          initialValues: _currentItem.formData,
        ),
      ),
    );
  }

  void _editNote() {
    final noteController = TextEditingController(text: _currentItem.note ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a personal label or reminder for this QR code (e.g., "Office Wi-Fi", "Event Registration").',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note / Description',
                hintText: 'Enter short note...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (_currentItem.note != null && _currentItem.note!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await widget.storageService
                    .updateItemNote(_currentItem.id, null);
                setState(() {
                  _currentItem = _currentItem.copyWith(clearNote: true);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note removed'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Remove Note',
                  style: TextStyle(color: AppColors.error)),
            ),
          ElevatedButton(
            onPressed: () async {
              final newNote = noteController.text.trim();
              Navigator.pop(ctx);
              await widget.storageService
                  .updateItemNote(_currentItem.id, newNote);
              setState(() {
                _currentItem = _currentItem.copyWith(
                  note: newNote,
                  clearNote: newNote.isEmpty,
                );
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        newNote.isNotEmpty ? 'Note saved!' : 'Note removed'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _chooseCollection() {
    final collections = widget.storageService.collections;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assign Collection / Tag',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currentItem.collection != null) ...[
                ListTile(
                  leading: const Icon(Icons.label_off_rounded,
                      color: AppColors.error),
                  title: const Text('Remove from collection'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await widget.storageService
                        .assignCollection(_currentItem.id, null);
                    setState(() {
                      _currentItem =
                          _currentItem.copyWith(clearCollection: true);
                    });
                  },
                ),
                const Divider(),
              ],
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: collections.length,
                  itemBuilder: (context, idx) {
                    final col = collections[idx];
                    final isAssigned = _currentItem.collection == col;
                    return ListTile(
                      leading: Icon(
                        Icons.folder_outlined,
                        color: isAssigned ? AppColors.primary : Colors.grey,
                      ),
                      title: Text(col,
                          style: TextStyle(
                            fontWeight:
                                isAssigned ? FontWeight.w700 : FontWeight.w500,
                            color: isAssigned ? AppColors.primary : null,
                          )),
                      trailing: isAssigned
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await widget.storageService
                            .assignCollection(_currentItem.id, col);
                        setState(() {
                          _currentItem = _currentItem.copyWith(collection: col);
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showCreateCollectionDialog();
                },
                icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                label: const Text('Create New Collection'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateCollectionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Collection Name',
            hintText: 'e.g. Marketing, Events',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await widget.storageService.createCollection(name);
                await widget.storageService
                    .assignCollection(_currentItem.id, name);
                setState(() {
                  _currentItem = _currentItem.copyWith(collection: name);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added to collection "$name"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Create & Assign'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QR Code?'),
        content: Text('Are you sure you want to delete "${_currentItem.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.storageService.deleteItem(_currentItem.id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${_currentItem.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _currentItem;
    final typeColor = item.type.color;
    final formattedDate =
        DateFormat('MMMM d, y • h:mm a').format(item.createdAt);

    final contextActions = QrContentActions.getActionsForContent(
      context: context,
      rawContent: item.rawPayload,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Details'),
        actions: [
          // Favorite
          IconButton(
            icon: Icon(
              _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorite ? AppColors.error : null,
            ),
            tooltip: _isFavorite ? 'Remove Favorite' : 'Mark as Favorite',
            onPressed: _toggleFavorite,
          ),
          // Share
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share QR Image',
            onPressed: _shareQrImage,
          ),
          // More popup menu (Duplicate, Regenerate, Edit, Delete)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 'template') {
                _useAsTemplate();
              } else if (val == 'note') {
                _editNote();
              } else if (val == 'collection') {
                _chooseCollection();
              } else if (val == 'edit') {
                _editItem();
              } else if (val == 'duplicate') {
                _duplicateItem();
              } else if (val == 'regenerate') {
                _regenerateItem();
              } else if (val == 'copy') {
                _copyContent();
              } else if (val == 'delete') {
                _confirmDeleteItem();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'template',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Use as Template'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'note',
                child: Row(
                  children: [
                    Icon(Icons.sticky_note_2_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit Note'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'collection',
                child: Row(
                  children: [
                    Icon(Icons.folder_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Assign Collection'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Edit / Modify'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_all_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'regenerate',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Regenerate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Copy Content'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Type Badge & Collection Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: typeColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.type.icon, size: 16, color: typeColor),
                        const SizedBox(width: 6),
                        Text(
                          item.type.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _chooseCollection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkCard
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            item.collection != null
                                ? Icons.folder_rounded
                                : Icons.create_new_folder_outlined,
                            size: 14,
                            color: item.collection != null
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item.collection ?? 'Add Collection',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: item.collection != null
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 4),

              // Date
              Text(
                'Created $formattedDate',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // 4 Export Modes Selector (Requirement: QR Only, QR + Title, QR + Title + Content, Presentation Card)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: QrExportMode.values.map((mode) {
                      final isActive = _exportMode == mode;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => setState(() => _exportMode = mode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? (isDark ? AppColors.primary : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                mode.icon,
                                size: 15,
                                color: isActive
                                    ? (isDark ? Colors.white : AppColors.primary)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                mode.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight:
                                      isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive
                                      ? (isDark ? Colors.white : AppColors.primary)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Readability Contrast Warning Banner
              if (!item.customization.hasSufficientContrast) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Low Readability Contrast',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.warning),
                            ),
                            Text(
                              'Contrast is ${item.customization.contrastRatio.toStringAsFixed(1)}:1 (recommended ≥ 3:1). Cameras might struggle to scan this code.',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _applyHighContrast,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Fix Contrast', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],

              // Dynamic QR Presentation View (with RepaintBoundary)
              Center(
                child: QrRenderView(
                  data: item.rawPayload,
                  customization: item.customization,
                  size: 240,
                  repaintBoundaryKey: _repaintBoundaryKey,
                  exportMode: _exportMode,
                  cardTitle: item.title,
                  cardSubtitle: item.subtitle,
                  note: item.note,
                  cardTypeLabel: item.type.label,
                  cardTypeIcon: item.type.icon,
                  cardTypeColor: item.type.color,
                ),
              ),
              const SizedBox(height: 16),

              // Customization Spec Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _infoChip(
                    context,
                    'Error Correction: ${item.customization.errorCorrectionLevel}',
                  ),
                  _infoChip(
                    context,
                    'Size: ${item.customization.size.toInt()}px',
                  ),
                  if (item.customization.dataModuleShape != 'square')
                    _infoChip(
                      context,
                      'Dots: ${item.customization.dataModuleShape}',
                    ),
                  if (item.customization.eyeShape != 'square')
                    _infoChip(
                      context,
                      'Eyes: ${item.customization.eyeShape}',
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Note / Description Card (Requirement 14)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.sticky_note_2_outlined,
                            size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Note / Description',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.note != null && item.note!.isNotEmpty
                                  ? item.note!
                                  : 'No note added. Tap to add a description...',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle:
                                    item.note != null && item.note!.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                color: item.note != null &&
                                        item.note!.isNotEmpty
                                    ? null
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          item.note != null && item.note!.isNotEmpty
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline_rounded,
                          size: 18,
                        ),
                        tooltip: item.note != null && item.note!.isNotEmpty
                            ? 'Edit Note'
                            : 'Add Note',
                        onPressed: _editNote,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Primary Export Actions (Save & Share)
              Row(
                children: [
                  // Save to Device / Gallery Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSaving ? null : _saveQrImage,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(_isSaving ? 'Saving...' : 'Save Image'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Share Image Button
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSharing ? null : _shareQrImage,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 20),
                      label: Text(_isSharing ? 'Sharing...' : 'Share Image'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Edit, Template & Duplicate Action Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _editItem,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _useAsTemplate,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Template',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _duplicateItem,
                      icon: const Icon(Icons.copy_all_rounded, size: 16),
                      label: const Text('Duplicate',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Back to Create & Generate New Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateScreen(
                                storageService: widget.storageService,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Create'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateScreen(
                              storageService: widget.storageService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('Generate New'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Content Utilities Row (Call, Email, Maps, Web, Copy, etc.)
              if (contextActions.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Content Actions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: contextActions.map((act) {
                    return ActionChip(
                      avatar: Icon(act.icon, size: 16, color: act.color ?? AppColors.primary),
                      label: Text(act.label),
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      onPressed: act.onTap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Content Payload Card (safe scrollable without overflow)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Content Payload',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 26),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _copyContent,
                                child: const Text('Copy', style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(60, 26),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showRawPayload = !_showRawPayload;
                                  });
                                },
                                child: Text(
                                  _showRawPayload ? 'Summary' : 'View Raw',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: SelectableText(
                            _showRawPayload
                                ? item.rawPayload
                                : (item.subtitle.isNotEmpty
                                    ? item.subtitle
                                    : item.rawPayload),
                            style: TextStyle(
                              fontFamily: _showRawPayload ? 'monospace' : null,
                              fontSize: 12.5,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ],
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

  Widget _infoChip(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkCard
            : AppColors.lightBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
