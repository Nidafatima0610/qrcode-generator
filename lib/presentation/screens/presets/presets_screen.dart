import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_preset.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/widgets/qr_render_view.dart';

class PresetsScreen extends StatefulWidget {
  final StorageService storageService;
  final ValueChanged<QrPreset>? onUsePreset;

  const PresetsScreen({
    super.key,
    required this.storageService,
    this.onUsePreset,
  });

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  final TextEditingController _searchController = TextEditingController();
  QrType? _filterType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRenameDialog(QrPreset preset) {
    final textController = TextEditingController(text: preset.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Preset'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'e.g. My Custom Style',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                Navigator.pop(ctx);
                await widget.storageService.renamePreset(preset.id, newName);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Renamed preset to "$newName"'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePreset(QrPreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Preset?'),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
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
              await widget.storageService.deletePreset(preset.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted "${preset.name}"'),
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

  void _showPresetEditorDialog({QrPreset? editingPreset}) {
    final nameController =
        TextEditingController(text: editingPreset?.name ?? '');
    final titleController =
        TextEditingController(text: editingPreset?.defaultTitle ?? '');
    QrType selectedType = editingPreset?.type ?? QrType.url;
    int selectedColorIndex = 0;
    if (editingPreset != null) {
      for (int i = 0; i < AppColors.presets.length; i++) {
        if (AppColors.presets[i].foreground.toARGB32() ==
                editingPreset.customization.foregroundColor.toARGB32() &&
            AppColors.presets[i].background.toARGB32() ==
                editingPreset.customization.backgroundColor.toARGB32()) {
          selectedColorIndex = i;
          break;
        }
      }
    }
    String selectedEc = editingPreset?.customization.errorCorrectionLevel ?? 'M';
    String eyeShape = editingPreset?.customization.eyeShape ?? 'square';
    String moduleShape = editingPreset?.customization.dataModuleShape ?? 'square';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final colorPreset = AppColors.presets[selectedColorIndex];
          final testCustomization = QrCustomization(
            foregroundColor: colorPreset.foreground,
            backgroundColor: colorPreset.background,
            dataModuleShape: moduleShape,
            eyeShape: eyeShape,
            errorCorrectionLevel: selectedEc,
          );

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        editingPreset != null
                            ? 'Edit QR Preset'
                            : 'Create QR Preset',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preset Name
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Preset Name *',
                      hintText: 'e.g. VIP Business Card',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Default Title
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Default Title (Optional)',
                      hintText: 'e.g. Official Profile',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // QR Type selector
                  const Text(
                    'QR Type',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: QrType.values.map((t) {
                      final isSelected = t == selectedType;
                      return ChoiceChip(
                        avatar: Icon(t.icon,
                            size: 16,
                            color: isSelected ? Colors.white : t.color),
                        label: Text(t.shortName),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          if (val) setModalState(() => selectedType = t);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color preset selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Color Theme',
                        style:
                            TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Contrast: ${testCustomization.contrastRatio.toStringAsFixed(1)}:1',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: testCustomization.hasSufficientContrast
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: AppColors.presets.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (c, idx) {
                        final p = AppColors.presets[idx];
                        final isSel = idx == selectedColorIndex;
                        return InkWell(
                          onTap: () =>
                              setModalState(() => selectedColorIndex = idx),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: p.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSel
                                    ? AppColors.primary
                                    : Colors.grey.shade300,
                                width: isSel ? 2.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: p.foreground,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shapes & Resilience row
                  Row(
                    children: [
                      // Module shape
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Module Style',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'square',
                                    label: Text('Square',
                                        style: TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'circle',
                                    label: Text('Dot',
                                        style: TextStyle(fontSize: 11))),
                              ],
                              selected: {moduleShape},
                              onSelectionChanged: (val) => setModalState(
                                  () => moduleShape = val.first),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Resilience
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error Correction',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'L',
                                    label: Text('L',
                                        style: TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'M',
                                    label: Text('M',
                                        style: TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'Q',
                                    label: Text('Q',
                                        style: TextStyle(fontSize: 11))),
                                ButtonSegment(
                                    value: 'H',
                                    label: Text('H',
                                        style: TextStyle(fontSize: 11))),
                              ],
                              selected: {selectedEc},
                              onSelectionChanged: (val) =>
                                  setModalState(() => selectedEc = val.first),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a preset name'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        // Readability contrast check (Requirement 3 & 4)
                        if (!testCustomization.hasSufficientContrast) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Insufficient contrast (${testCustomization.contrastRatio.toStringAsFixed(1)}:1). Please pick colors with higher contrast to ensure scan readability.'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final targetId =
                            editingPreset?.id ?? const Uuid().v4();
                        final targetCreatedAt =
                            editingPreset?.createdAt ?? DateTime.now();

                        final newPreset = QrPreset(
                          id: targetId,
                          name: name,
                          type: selectedType,
                          defaultTitle: titleController.text.trim(),
                          customization: testCustomization,
                          createdAt: targetCreatedAt,
                        );

                        await widget.storageService.savePreset(newPreset);
                        if (modalCtx.mounted) Navigator.pop(modalCtx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(editingPreset != null
                                  ? 'Updated preset "$name"'
                                  : 'Created preset "$name"'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.bookmark_add_rounded),
                      label: Text(editingPreset != null
                          ? 'Update Preset'
                          : 'Save Preset'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Presets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Preset',
            onPressed: () => _showPresetEditorDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.storageService,
          builder: (context, _) {
            final allPresets = widget.storageService.presets;
            final query = _searchController.text.trim().toLowerCase();

            final filtered = allPresets.where((p) {
              final matchesType = _filterType == null || p.type == _filterType;
              final matchesQuery = query.isEmpty ||
                  p.name.toLowerCase().contains(query) ||
                  p.defaultTitle.toLowerCase().contains(query) ||
                  p.type.label.toLowerCase().contains(query);
              return matchesType && matchesQuery;
            }).toList();

            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search presets...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),

                // Type filter chips
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('All'),
                          selected: _filterType == null,
                          onSelected: (val) {
                            setState(() => _filterType = null);
                          },
                        ),
                      ),
                      ...QrType.values.map((t) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(t.icon, size: 14, color: t.color),
                            label: Text(t.shortName),
                            selected: _filterType == t,
                            onSelected: (val) {
                              setState(() => _filterType = val ? t : null);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // List of presets
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyStateView(
                          icon: Icons.bookmark_border_rounded,
                          title: 'No Presets Found',
                          message: allPresets.isEmpty
                              ? 'Save your commonly used QR configurations as presets to quickly build styled codes.'
                              : 'No presets match your current search/filter.',
                          buttonText: 'Create New Preset',
                          onButtonPressed: () => _showPresetEditorDialog(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final preset = filtered[index];
                            final typeColor = preset.type.color;

                            return Card(
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Mini QR preview thumbnail
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 58,
                                        height: 58,
                                        color: preset.customization.backgroundColor,
                                        padding: const EdgeInsets.all(4),
                                        child: Center(
                                          child: QrRenderView(
                                            data: 'https://preset.qr',
                                            customization: preset.customization,
                                            size: 50,
                                            showContainer: false,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Preset Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 7,
                                                    vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: typeColor.withValues(
                                                      alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(preset.type.icon,
                                                        size: 11,
                                                        color: typeColor),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      preset.type.shortName,
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: typeColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'ECC: ${preset.customization.errorCorrectionLevel}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            preset.name,
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (preset.defaultTitle.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Default: ${preset.defaultTitle}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark
                                                    ? AppColors.darkTextSecondary
                                                    : AppColors
                                                        .lightTextSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Action button to use preset
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        textStyle: const TextStyle(fontSize: 12),
                                      ),
                                      onPressed: () {
                                        if (widget.onUsePreset != null) {
                                          widget.onUsePreset!(preset);
                                        } else {
                                          Navigator.pop(context, preset);
                                        }
                                      },
                                      child: const Text('Use'),
                                    ),

                                    // Popup Menu for Edit / Duplicate / Rename / Delete
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert_rounded,
                                          size: 18),
                                      onSelected: (val) async {
                                        if (val == 'edit') {
                                          _showPresetEditorDialog(
                                              editingPreset: preset);
                                        } else if (val == 'duplicate') {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final dup = await widget
                                              .storageService
                                              .duplicatePreset(preset.id);
                                          if (mounted && dup != null) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Duplicated as "${dup.name}"'),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } else if (val == 'rename') {
                                          _showRenameDialog(preset);
                                        } else if (val == 'delete') {
                                          _confirmDeletePreset(preset);
                                        }
                                      },
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.tune_rounded, size: 16),
                                              SizedBox(width: 8),
                                              Text('Edit Style'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              Icon(Icons.copy_all_rounded,
                                                  size: 16),
                                              SizedBox(width: 8),
                                              Text('Duplicate'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 16),
                                              SizedBox(width: 8),
                                              Text('Rename'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline_rounded,
                                                  size: 16,
                                                  color: AppColors.error),
                                              SizedBox(width: 8),
                                              Text('Delete',
                                                  style: TextStyle(
                                                      color: AppColors.error)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
