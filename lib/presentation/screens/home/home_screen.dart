import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/qr_type.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/widgets/qr_card.dart';
import 'package:qrcode_generator/presentation/widgets/empty_state_view.dart';
import 'package:qrcode_generator/presentation/screens/preview/qr_preview_screen.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scan_result_screen.dart';
import 'package:qrcode_generator/presentation/screens/templates/templates_screen.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storageService;
  final Function(
    int tabIndex, [
    QrType? initialType,
    int? historySubTab,
    Map<String, dynamic>? initialValues,
  ]) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: storageService,
          builder: (context, _) {
            final recentHistory = storageService.history.take(5).toList();
            final recentScans = storageService.scanHistory.take(3).toList();

            return CustomScrollView(
              slivers: [
                // 1. App Bar / Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.secondary
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'QR Studio Pro',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  'Generate, Customize & Scan',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Quick scan icon button in top right
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
                      ],
                    ),
                  ),
                ),

                // 2. Real Statistics Dashboard (Requirement 13)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
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

                // 3. Hero Quick Action Cards (Create QR & Scan QR)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                    child: Row(
                      children: [
                        // Generate QR Card
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => onNavigateToTab(1), // Create tab
                            child: Container(
                              height: 122,
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
                                    color:
                                        AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.add_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create QR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        '9 custom formats',
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
                              height: 122,
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
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundColor: Colors.white24,
                                    child: Icon(Icons.camera_alt_rounded,
                                        color: Colors.white, size: 19),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Scan QR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Instant camera detection',
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

                // 4. Templates Feature Card Banner (Requirement 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkCard
                              : Colors.purple.shade50.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : Colors.purple.shade100,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready-Made QR Templates',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Wi-Fi, vCard, Social, Location & Business presets',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 5. Quick Create Actions for ALL 9 Formats (Requirement 14)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Quick Create Formats',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 94,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: QrType.values.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final type = QrType.values[index];
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
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
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

                // 6. Recent Scans Section (Requirement 13)
                if (recentScans.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Scans',
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

                // 7. Recent Generated QR Codes Section (Requirement 13)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
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

                // 8. Recent History List or Empty State
                if (recentHistory.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = recentHistory[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: QrCard(
                              item: item,
                              showDelete: false,
                              onFavoriteToggle: () async {
                                await storageService.toggleFavorite(item.id);
                              },
                              onEdit: () {
                                onNavigateToTab(1, item.type);
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QrPreviewScreen(
                                      item: item,
                                      storageService: storageService,
                                      onEdit: () {
                                        onNavigateToTab(1, item.type);
                                      },
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
              ],
            );
          },
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
