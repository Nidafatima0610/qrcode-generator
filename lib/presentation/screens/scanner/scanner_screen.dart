import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:qrcode_generator/core/constants/app_colors.dart';
import 'package:qrcode_generator/core/models/scan_item.dart';
import 'package:qrcode_generator/core/services/qr_payload_builder.dart';
import 'package:qrcode_generator/core/services/storage_service.dart';
import 'package:qrcode_generator/presentation/screens/scanner/scan_result_screen.dart';

class ScannerScreen extends StatefulWidget {
  final StorageService storageService;

  const ScannerScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _isProcessing = true);

    final cleanValue = rawValue.trim();
    final parsed = QrPayloadBuilder.parse(cleanValue);

    final scanRecord = ScanItem(
      id: const Uuid().v4(),
      rawContent: cleanValue,
      detectedType: parsed.type,
      title: parsed.displayTitle,
      subtitle: parsed.displaySubtitle,
      scannedAt: DateTime.now(),
      details: parsed.details,
    );

    // Save to persistent scan history
    await widget.storageService.saveScanItem(scanRecord);

    if (!mounted) return;

    // Navigate to rich Scan Result screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          scanItem: scanRecord,
          storageService: widget.storageService,
          onScanAgain: () {
            // Callback to re-enable scanning
          },
        ),
      ),
    );

    // Delay before re-enabling scanning to prevent duplicate scans
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? AppColors.warning : Colors.white,
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: () async {
              await _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            tooltip: 'Switch Camera',
            onPressed: () async {
              await _controller.switchCamera();
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Mobile Scanner View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Camera Unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please verify camera permissions are granted in settings to scan QR codes.\n${error.errorCode.name}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _controller.start();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        label: const Text('Retry Camera'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Reticle Overlay
          _buildReticleOverlay(),

          // 3. Status Badge at Bottom
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isProcessing
                          ? Icons.hourglass_top_rounded
                          : Icons.center_focus_strong_rounded,
                      color: _isProcessing ? AppColors.warning : Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isProcessing
                          ? 'Processing code...'
                          : 'Align QR code within frame to scan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReticleOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanArea = constraints.maxWidth * 0.68;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Darkened vignette background with cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: scanArea,
                      width: scanArea,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Reticle frame border with glowing rounded corners
            Container(
              height: scanArea,
              width: scanArea,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isProcessing
                      ? AppColors.warning
                      : AppColors.primaryLight,
                  width: 2.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
