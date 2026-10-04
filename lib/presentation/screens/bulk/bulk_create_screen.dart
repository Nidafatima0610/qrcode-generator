import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_customization.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/bulk/bulk_results_screen.dart';

class BulkEntryRow {
  final String id;
  final TextEditingController titleController;
  final TextEditingController contentController;

  BulkEntryRow({
    required this.id,
    String initialTitle = '',
    String initialContent = '',
  })  : titleController = TextEditingController(text: initialTitle),
        contentController = TextEditingController(text: initialContent);

  bool get isValid => contentController.text.trim().isNotEmpty;

  void dispose() {
    titleController.dispose();
    contentController.dispose();
  }
}

class BulkCreateScreen extends StatefulWidget {
  final StorageService storageService;

  const BulkCreateScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<BulkCreateScreen> createState() => _BulkCreateScreenState();
}

class _BulkCreateScreenState extends State<BulkCreateScreen> {
  final List<BulkEntryRow> _rows = [];

  @override
  void initState() {
    super.initState();
    // Start with 3 sample rows
    _addRow(initialTitle: 'Product A', initialContent: 'https://example.com/a');
    _addRow(initialTitle: 'Product B', initialContent: 'https://example.com/b');
    _addRow(initialTitle: 'Product C', initialContent: 'https://example.com/c');
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow({String initialTitle = '', String initialContent = ''}) {
    final row = BulkEntryRow(
      id: const Uuid().v4(),
      initialTitle: initialTitle,
      initialContent: initialContent,
    );
    row.contentController.addListener(() => setState(() {}));
    row.titleController.addListener(() => setState(() {}));
    setState(() {
      _rows.add(row);
    });
  }

  void _removeRow(int index) {
    if (index >= 0 && index < _rows.length) {
      final removed = _rows.removeAt(index);
      removed.dispose();
      setState(() {});
    }
  }

  void _clearInvalidEntries() {
    final toRemove = <BulkEntryRow>[];
    for (final row in _rows) {
      if (!row.isValid) {
        toRemove.add(row);
      }
    }
    for (final row in toRemove) {
      _rows.remove(row);
      row.dispose();
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${toRemove.length} empty row${toRemove.length == 1 ? '' : 's'}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showBatchPasteDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batch Paste / Import'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste rows below. Each line can be formatted as:\n"Title, URL" or just "Content / URL"',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Item 1, https://example.com/1\nItem 2, https://example.com/2\nhttps://example.com/3',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final raw = textController.text.trim();
              if (raw.isNotEmpty) {
                final lines = raw.split('\n');
                int added = 0;
                for (final line in lines) {
                  final trimmed = line.trim();
                  if (trimmed.isEmpty) continue;
                  if (trimmed.contains(',')) {
                    final parts = trimmed.split(',');
                    final title = parts.first.trim();
                    final content = parts.sublist(1).join(',').trim();
                    _addRow(initialTitle: title, initialContent: content);
                  } else {
                    _addRow(initialContent: trimmed);
                  }
                  added++;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Imported $added rows'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Import Rows'),
          ),
        ],
      ),
    );
  }

  void _generateValidEntries() {
    final validRows = _rows.where((r) => r.isValid).toList();

    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid row with content to generate QR codes.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Generate real QrItems for every valid row
    final generatedItems = <QrItem>[];
    for (final row in validRows) {
      final rawContent = row.contentController.text.trim();
      final parsed = QrPayloadBuilder.parse(rawContent);

      final title = row.titleController.text.trim().isNotEmpty
          ? row.titleController.text.trim()
          : parsed.displayTitle;

      final item = QrItem(
        id: const Uuid().v4(),
        type: parsed.type,
        title: title,
        subtitle: parsed.displaySubtitle,
        rawPayload: parsed.rawPayload,
        createdAt: DateTime.now(),
        customization: const QrCustomization(),
      );
      generatedItems.add(item);
    }

    // Navigate to Bulk Results Screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BulkResultsScreen(
          items: generatedItems,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final validCount = _rows.where((r) => r.isValid).length;
    final invalidCount = _rows.length - validCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk QR Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.paste_rounded),
            tooltip: 'Paste / Import Lines',
            onPressed: _showBatchPasteDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Row',
            onPressed: () => _addRow(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Validation summary card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  // Valid count pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 5),
                        Text(
                          '$validCount Valid',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Invalid count pill
                  if (invalidCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 14, color: AppColors.warning),
                          const SizedBox(width: 5),
                          Text(
                            '$invalidCount Empty/Invalid',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Spacer(),
                  if (invalidCount > 0)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: _clearInvalidEntries,
                      child: const Text('Clear Invalid', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),

            // Rows list
            Expanded(
              child: _rows.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.playlist_add_rounded,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text(
                            'No Entries in Bulk List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add rows manually or paste multiple links/titles.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _addRow(),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add First Entry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                      itemCount: _rows.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final isValid = row.isValid;

                        return Card(
                          margin: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isValid
                                  ? (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder)
                                  : AppColors.warning,
                              width: isValid ? 1 : 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row Index Badge
                                CircleAvatar(
                                  radius: 13,
                                  backgroundColor: isValid
                                      ? AppColors.primary.withValues(alpha: 0.12)
                                      : AppColors.warning.withValues(alpha: 0.15),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isValid
                                          ? AppColors.primary
                                          : AppColors.warning,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Row Form Fields
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        controller: row.titleController,
                                        style: const TextStyle(fontSize: 13.5),
                                        decoration: InputDecoration(
                                          hintText: 'Title (e.g. Product ${index + 1})',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: row.contentController,
                                        style: const TextStyle(fontSize: 13.5),
                                        decoration: InputDecoration(
                                          hintText: 'Content or URL * (Required)',
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 8),
                                          errorText: !isValid &&
                                                  row.contentController.text.isNotEmpty
                                              ? 'Content cannot be empty'
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Delete Row Button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 20, color: Colors.grey),
                                  tooltip: 'Remove Row',
                                  onPressed: () => _removeRow(index),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _addRow(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Row'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: validCount > 0 ? _generateValidEntries : null,
                icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                label: Text('Generate ($validCount Valid)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
