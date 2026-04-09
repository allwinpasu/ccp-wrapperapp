// lib/features/onboarding/presentation/pages/consent_selfie_screen.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConsentSelfieScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const ConsentSelfieScreen({super.key, required this.onCompleted});

  @override
  State<ConsentSelfieScreen> createState() => _ConsentSelfieScreenState();
}

class _ConsentSelfieScreenState extends State<ConsentSelfieScreen> {
  // ── Step: 0 = consent dialog, 1 = camera, 2 = preview ──────────────────────
  int _step = 0;

  // Consent
  bool _consentChecked = false;

  // Camera
  CameraController? _camCtrl;
  bool _cameraReady = false;
  bool _capturing = false;
  String? _capturedPath;
  String? _cameraError;

  static const _kSelfiePathKey = 'user_selfie_path';

  @override
  void dispose() {
    _camCtrl?.dispose();
    super.dispose();
  }

  // ─── Camera init ────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _camCtrl = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _camCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = 'Could not open camera: $e');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_camCtrl == null || !_cameraReady || _capturing) return;
    setState(() => _capturing = true);

    try {
      final xFile = await _camCtrl!.takePicture();
      // Save to app documents directory as profile_selfie.jpg
      final dir = await getApplicationDocumentsDirectory();
      final destPath = p.join(dir.path, 'profile_selfie.jpg');
      await File(xFile.path).copy(destPath);

      // Persist path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kSelfiePathKey, destPath);

      if (mounted) {
        setState(() {
          _capturedPath = destPath;
          _step = 2; // preview step
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Capture failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _retake() {
    setState(() {
      _capturedPath = null;
      _step = 1;
    });
  }

  Future<void> _finish() async {
    // Mark onboarding complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    widget.onCompleted();
  }

  // ─── Step navigation ────────────────────────────────────────────────────────

  void _proceedToCamera() {
    setState(() => _step = 1);
    _initCamera();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _step == 1 ? Colors.black : null,
      body: switch (_step) {
        0 => _buildConsent(),
        1 => _buildCamera(),
        _ => _buildPreview(),
      },
    );
  }

  // ─── Step 0: Consent ────────────────────────────────────────────────────────

  Widget _buildConsent() {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.verified_user,
                  size: 40, color: theme.primaryColor),
            ),
            const SizedBox(height: 20),

            Text('User Consent',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),

            const SizedBox(height: 8),

            Text(
              'Please read and accept the following before continuing.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Consent text box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _consentSection(
                        icon: Icons.location_on,
                        color: Colors.blue,
                        title: 'Location tracking',
                        body:
                            'I consent to the app collecting my GPS location during work hours and sharing it with Cholamandalam for field activity monitoring.',
                      ),
                      const Divider(height: 24),
                      _consentSection(
                        icon: Icons.camera_alt,
                        color: Colors.purple,
                        title: 'Photo capture',
                        body:
                            'I consent to the app capturing my photo for identity verification and storing it securely on this device.',
                      ),
                      const Divider(height: 24),
                      _consentSection(
                        icon: Icons.data_usage,
                        color: Colors.teal,
                        title: 'Data usage',
                        body:
                            'I understand that my location and activity data will be used solely for business operations and field activity tracking.',
                      ),
                      const Divider(height: 24),
                      _consentSection(
                        icon: Icons.privacy_tip,
                        color: Colors.orange,
                        title: 'Privacy',
                        body:
                            'I acknowledge that my data is handled in accordance with the company\'s data privacy policy and applicable laws.',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Checkbox
            GestureDetector(
              onTap: () => setState(() => _consentChecked = !_consentChecked),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _consentChecked,
                      onChanged: (v) =>
                          setState(() => _consentChecked = v ?? false),
                      activeColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I agree to sharing my location information with Chola through this application.',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _consentChecked ? _proceedToCamera : null,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Okay, take my photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _consentSection({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Camera ─────────────────────────────────────────────────────────

  Widget _buildCamera() {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview or error
          if (_cameraError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_cameraError!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center),
              ),
            )
          else if (!_cameraReady)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _camCtrl!.value.previewSize!.height,
                    height: _camCtrl!.value.previewSize!.width,
                    child: CameraPreview(_camCtrl!),
                  ),
                ),
              ),
            ),

          // Oval face guide overlay
          CustomPaint(painter: _FaceGuidePainter()),

          // Top instruction
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Position your face in the oval',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Capture button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _capturing ? null : _capturePhoto,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white38, width: 4),
                    ),
                    child: _capturing
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: Colors.black),
                          )
                        : const Icon(Icons.camera_alt,
                            color: Colors.black, size: 32),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tap to capture',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Preview ────────────────────────────────────────────────────────

  Widget _buildPreview() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 32),

            Text('Photo captured!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),

            const SizedBox(height: 8),

            Text('This will be used for identity verification.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center),

            const SizedBox(height: 28),

            // Photo preview
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).primaryColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: ClipOval(
                  child: Image.file(
                    File(_capturedPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Retake
            OutlinedButton.icon(
              onPressed: _retake,
              icon: const Icon(Icons.refresh),
              label: const Text('Retake photo'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Continue
            ElevatedButton.icon(
              onPressed: _finish,
              icon: const Icon(Icons.check),
              label: const Text('Looks good, continue'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Face guide oval painter ──────────────────────────────────────────────────

class _FaceGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rx = size.width * 0.32;
    final ry = size.height * 0.28;

    // Dim overlay with oval cutout
    final paint = Paint()..color = Colors.black.withOpacity(0.45);
    final full = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final oval = Path()
      ..addOval(Rect.fromCenter(
          center: Offset(cx, cy), width: rx * 2, height: ry * 2));
    canvas.drawPath(Path.combine(PathOperation.difference, full, oval), paint);

    // Oval border
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
