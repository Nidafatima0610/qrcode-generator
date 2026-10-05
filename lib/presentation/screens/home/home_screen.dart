import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_item.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_card.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scan_result_screen.dart';
import 'package:qrcode_generator/presentation/screens/templates/templates_screen.dart';
import 'package:qrcode_generator/presentation/screens/bulk/bulk_create_screen.dart';
import 'package:qrcode_generator/presentation/screens/presets/presets_screen.dart';
import 'package:qrcode_generator/presentation/screens/create/create_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storageService;
  final Function(
    int tabIndex, [
    QrType? initialType,
    int? historySubTab,
    Map<String, dynamic>? initialValues,
    String? initialCollection,
  ]) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.onNavigateToTab,
  });

  Future<void> _confirmDeleteItem(BuildContext context, QrItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete QR Code?'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await storageService.deleteItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${item.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _duplicateItem(BuildContext context, QrItem item) async {
    final duplicated = item.copyWith(
      id: const Uuid().v4(),
      title: '${item.title} (Copy)',
      createdAt: DateTime.now(),
    );
    await storageService.saveItem(duplicated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated "${item.title}"'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QrPreviewScreen(
                    item: duplicated,
                    storageService: storageService,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
  }

  void _openEdit(BuildContext context, QrItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateScreen(
          storageService: storageService,
          editingItem: item,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: storageService,
          builder: (context, _) {
            final recentHistory = storageService.history.take(4).toList();
            final recentScans = storageService.scanHistory.take(3).toList();

            return CustomScrollView(
              slivers: [
                // ==========================================
                // 1. TOP: APP IDENTITY & QUICK ACTIONS
                // ==========================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'QR Studio Pro',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    Text(
                                      'Generate, Style & Scan',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quick action buttons in top right (Search + Scanner + Settings)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightBorder.withValues(alpha: 0.5),
                              ),
                              icon: const Icon(Icons.search_rounded, size: 20),
                              tooltip: 'Search QR Codes',
                              onPressed: () => onNavigateToTab(2, null, 0),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightBorder.withValues(alpha: 0.5),
                              ),
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                              tooltip: 'Open Scanner',
                              onPressed: () => onNavigateToTab(3), // Scanner tab
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppColors.darkCard
                                    : AppColors.lightBorder.withValues(alpha: 0.5),
                              ),
                              icon: const Icon(Icons.settings_outlined, size: 20),
                              tooltip: 'Settings',
                              onPressed: () => onNavigateToTab(4), // Settings tab
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Top: Hero Quick Action Cards (Create QR & Scan QR)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(
                      children: [
                        // Generate QR Card
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onNavigateToTab(1), // Create tab
                            child: Container(
                              height: 114,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.add_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create QR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '11 rich formats',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Scan QR Card
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onNavigateToTab(3), // Scanner tab
                            child: Container(
                              height: 114,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.secondary,
                                    Color(0xFF0891B2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.secondary.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan QR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Camera & Gallery',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top: Clean Quick Utilities Row (Bulk Generator, Presets, Templates)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                    child: Row(
                      children: [
                        _buildQuickToolButton(
                          context: context,
                          icon: Icons.dynamic_feed_rounded,
                          label: 'Bulk QR',
                          color: Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BulkCreateScreen(
                                  storageService: storageService,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickToolButton(
                          context: context,
                          icon: Icons.tune_rounded,
                          label: 'Presets',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PresetsScreen(
                                  storageService: storageService,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildQuickToolButton(
                          context: context,
                          icon: Icons.auto_awesome_rounded,
                          label: 'Templates',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TemplatesScreen(
                                  onSelectTemplate: (tpl) {
                                    Navigator.pop(context);
                                    onNavigateToTab(
                                      1,
                                      tpl.type,
                                      null,
                                      tpl.initialValues,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // 2. MIDDLE: QR TYPE SHORTCUTS & RECENT CONTENT
                // ==========================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Text(
                      'QR Type Shortcuts',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                ),

                // Horizontal Carousel of All 11 Formats (Prioritized with the 6 Quick Types)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 92,
                    child: Builder(
                      builder: (context) {
                        const prioritizedTypes = [
                          QrType.url,
                          QrType.wifi,
                          QrType.contact,
                          QrType.text,
                          QrType.email,
                          QrType.phone,
                          QrType.sms,
                          QrType.location,
                          QrType.social,
                          QrType.businessCard,
                          QrType.businessInfo,
                        ];

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          itemCount: prioritizedTypes.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final type = prioritizedTypes[index];
                            final typeColor = type.color;

                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                onNavigateToTab(1, type);
                              },
                              child: Container(
                                width: 82,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(type.icon,
                                          size: 19, color: typeColor),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      type.shortName,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),

                // Middle: Recent Generated QR Codes Section Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Generated Codes',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                        ),
                        if (storageService.history.isNotEmpty)
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => onNavigateToTab(2, null, 0),
                            child: Text(
                              'View All (${storageService.history.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Middle: Recent History List or Empty State
                if (recentHistory.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: EmptyStateView(
                        icon: Icons.qr_code_2_rounded,
                        title: 'No QR Codes Generated',
                        message:
                            'Select a format above to generate your first custom QR code with color presets, shapes, and export tools!',
                        buttonText: 'Create QR Code',
                        onButtonPressed: () => onNavigateToTab(1),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = recentHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: QrCard(
                              item: item,
                              showDelete: true,
                              onDelete: () => _confirmDeleteItem(context, item),
                              onFavoriteToggle: () async {
                                await storageService.toggleFavorite(item.id);
                              },
                              onEdit: () => _openEdit(context, item),
                              onDuplicate: () => _duplicateItem(context, item),
                              onRegenerate: () => _openEdit(context, item),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrPreviewScreen(
                                      item: item,
                                      storageService: storageService,
                                      onEdit: () => _openEdit(context, item),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: recentHistory.length,
                      ),
                    ),
                  ),

                // ==========================================
                // 2.5 COLLECTIONS & TAGS QUICK SECTION (Requirement 12 & 18)
                // ==========================================
                if (storageService.collections.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.folder_outlined,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Collections & Tags',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => onNavigateToTab(2, null, 0),
                            child: const Text(
                              'View in History',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: storageService.collections.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final col = storageService.collections[idx];
                          final count = storageService.history
                              .where((e) => e.collection == col)
                              .length;

                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => onNavigateToTab(2, null, 0, null, col),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkCard
                                    : Colors.white,
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
                                  const Icon(Icons.folder_rounded,
                                      size: 14, color: AppColors.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    col,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // 3. FAVORITES SECTION (when storageService.favorites.isNotEmpty)
                // ==========================================
                if (storageService.favorites.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded,
                                  size: 16, color: AppColors.error),
                              const SizedBox(width: 6),
                              Text(
                                'Favorite QR Codes',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => onNavigateToTab(2, null, 1),
                            child: Text(
                              'View All (${storageService.favorites.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item =
                              storageService.favorites.take(3).toList()[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: QrCard(
                              item: item,
                              showDelete: true,
                              onDelete: () => _confirmDeleteItem(context, item),
                              onFavoriteToggle: () async {
                                await storageService.toggleFavorite(item.id);
                              },
                              onEdit: () => _openEdit(context, item),
                              onDuplicate: () => _duplicateItem(context, item),
                              onRegenerate: () => _openEdit(context, item),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrPreviewScreen(
                                      item: item,
                                      storageService: storageService,
                                      onEdit: () => _openEdit(context, item),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        childCount: storageService.favorites.take(3).length,
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // 4. ACTIVITY: RECENT SCANS
                // ==========================================
                if (recentScans.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity (Scans)',
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(60, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => onNavigateToTab(2, null, 2),
                            child: Text(
                              'View All (${storageService.scanHistory.length})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = recentScans[index];
                          final typeColor = item.detectedType.color;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(item.detectedType.icon,
                                      color: typeColor, size: 18),
                                ),
                                title: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 13.5, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  DateFormat('MMM d • h:mm a').format(item.scannedAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 13),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScanResultScreen(
                                        scanItem: item,
                                        storageService: storageService,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        childCount: recentScans.length,
                      ),
                    ),
                  ),
                ],

                // ==========================================
                // 5. STATISTICS DASHBOARD
                // ==========================================
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                    child: Text(
                      'Overview & Statistics',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 2, 20, 30),
                    child: Row(
                      children: [
                        _buildStatCard(
                          context: context,
                          label: 'Generated',
                          value: '${storageService.totalGenerated}',
                          icon: Icons.qr_code_rounded,
                          color: AppColors.primary,
                          onTap: () => onNavigateToTab(2, null, 0),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          context: context,
                          label: 'Total Scans',
                          value: '${storageService.totalScans}',
                          icon: Icons.camera_alt_rounded,
                          color: AppColors.secondary,
                          onTap: () => onNavigateToTab(2, null, 2),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          context: context,
                          label: 'Favorites',
                          value: '${storageService.totalFavorites}',
                          icon: Icons.favorite_rounded,
                          color: AppColors.error,
                          onTap: () => onNavigateToTab(2, null, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickToolButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 15, color: color),
                  ),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 13, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
