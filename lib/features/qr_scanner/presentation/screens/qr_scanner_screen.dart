import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_code_generator/core/theme/app_theme.dart';
import 'package:qr_code_generator/core/utils/snackbar_helper.dart';
import 'package:qr_code_generator/features/qr_scanner/presentation/widgets/scanned_result_sheet.dart';

/// Camera viewfinder screen supporting live QR code detection and gallery photo scanning.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  bool _isProcessing = false;
  bool _isTorchOn = false;
  bool _isFrontCamera = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    _isProcessing = true;
    _controller.stop();

    ScannedResultSheet.show(
      context,
      rawContent: rawValue,
      onScanAgain: () {
        _isProcessing = false;
        _controller.start();
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _controller.start();
      }
    });
  }

  Future<void> _scanFromGallery() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (file == null) return; // User cancelled

      setState(() => _isProcessing = true);

      final BarcodeCapture? capture = await _controller.analyzeImage(file.path);

      if (!mounted) return;

      if (capture != null && capture.barcodes.isNotEmpty) {
        final raw = capture.barcodes.first.rawValue;
        if (raw != null && raw.isNotEmpty) {
          _controller.stop();
          await ScannedResultSheet.show(
            context,
            rawContent: raw,
            onScanAgain: () {
              _isProcessing = false;
              _controller.start();
            },
          );
          return;
        }
      }

      SnackBarHelper.showInfo(
        context,
        'No QR code detected in the selected image. Please try a clearer picture.',
      );
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Failed to analyze image: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  void _switchCamera() async {
    try {
      await _controller.switchCamera();
      setState(() => _isFrontCamera = !_isFrontCamera);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        elevation: 0,
        actions: [
          // Gallery Image Scanner Button
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Scan Image from Gallery',
            onPressed: _scanFromGallery,
          ),
          // Flashlight Toggle
          IconButton(
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? Colors.amber : null,
            ),
            tooltip: 'Toggle Flashlight',
            onPressed: _toggleTorch,
          ),
          // Switch Camera Toggle
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded),
            tooltip: 'Flip Camera',
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live Camera Stream
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_off_rounded,
                          size: 48,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Camera Access Needed',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please allow camera permission in your device settings to scan QR codes live.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _controller.start(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _scanFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Scan Image from Gallery Instead'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Viewfinder Overlay
          CustomPaint(
            painter: _ViewfinderOverlayPainter(),
          ),

          // Helper Instructional Overlay Text
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Align QR code within the frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _scanFromGallery,
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: const Text('Upload Photo / Screenshot'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black38,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),

          // Loading Indicator when analyzing gallery image
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter rendering the darkened outer overlay and rounded viewfinder frame.
class _ViewfinderOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const boxSize = 250.0;
    final left = (size.width - boxSize) / 2;
    final top = (size.height - boxSize) / 2.4;
    final rect = Rect.fromLTWH(left, top, boxSize, boxSize);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(24));

    // Darkened cutout
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawPath(backgroundPath, bgPaint);

    // Corner Accents
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    const cornerRadius = 24.0;

    // Top-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top + cornerRadius)
        ..arcToPoint(
          Offset(left + cornerRadius, top),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );

    // Top-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxSize - cornerLength, top)
        ..lineTo(left + boxSize - cornerRadius, top)
        ..arcToPoint(
          Offset(left + boxSize, top + cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(left + boxSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + boxSize - cornerLength)
        ..lineTo(left, top + boxSize - cornerRadius)
        ..arcToPoint(
          Offset(left + cornerRadius, top + boxSize),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(left + cornerLength, top + boxSize),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawPath(
      Path()
        ..moveTo(left + boxSize - cornerLength, top + boxSize)
        ..lineTo(left + boxSize - cornerRadius, top + boxSize)
        ..arcToPoint(
          Offset(left + boxSize, top + boxSize - cornerRadius),
          radius: const Radius.circular(cornerRadius),
        )
        ..lineTo(left + boxSize, top + boxSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
