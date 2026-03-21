import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/attendance_provider.dart';
import '../models/attendance_model.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});
  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  Position? _position;
  File? _selfie;
  bool _locating = false;
  bool _inGeofence = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _getLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todayAttendanceProvider.notifier).loadToday();
    });
  }

  Future<void> _getLocation() async {
    setState(() { _locating = true; _locationError = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'Location services disabled'; _locating = false; });
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          setState(() { _locationError = 'Location permission denied'; _locating = false; });
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final dist = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, AppConstants.officeLat, AppConstants.officeLng);
      setState(() {
        _position = pos;
        _inGeofence = dist <= AppConstants.officeRadius;
        _locating = false;
      });
    } catch (e) {
      setState(() { _locationError = e.toString(); _locating = false; });
    }
  }

  Future<void> _takeSelfie() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 800, imageQuality: 80);
    if (img != null) setState(() => _selfie = File(img.path));
  }

  Future<void> _performAction(bool isCheckIn) async {
    if (_position == null) { await _getLocation(); return; }
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie'), backgroundColor: AppColors.warning, behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      final notifier = ref.read(checkInOutProvider.notifier);
      AttendanceRecord? record;
      if (isCheckIn) {
        record = await notifier.checkIn(lat: _position!.latitude, lng: _position!.longitude, selfieFilePath: _selfie!.path);
      } else {
        record = await notifier.checkOut(lat: _position!.latitude, lng: _position!.longitude, selfieFilePath: _selfie!.path);
      }
      if (record != null) ref.read(todayAttendanceProvider.notifier).updateRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isCheckIn ? '✅ Checked in successfully!' : '✅ Checked out successfully!'),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        setState(() => _selfie = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayRecord = ref.watch(todayAttendanceProvider);
    final checkInOutState = ref.watch(checkInOutProvider);
    final hasCheckedIn = todayRecord?.checkIn?.time != null;
    final hasCheckedOut = todayRecord?.checkOut?.time != null;
    final isLoading = checkInOutState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _getLocation),
      ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          // ─── Status Card ─────────────────────────────────────────────
          _StatusCard(hasCheckedIn: hasCheckedIn, hasCheckedOut: hasCheckedOut, record: todayRecord),
          const SizedBox(height: 20),

          // ─── Location Card ────────────────────────────────────────────
          _buildLocationCard(),
          const SizedBox(height: 20),

          // ─── Selfie Card ──────────────────────────────────────────────
          _SelfieCard(selfie: _selfie, onTap: _takeSelfie),
          const SizedBox(height: 32),

          // ─── Action Button ────────────────────────────────────────────
          if (!hasCheckedOut)
            ElevatedButton.icon(
              onPressed: isLoading ? null : () => _performAction(!hasCheckedIn),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasCheckedIn ? AppColors.error : AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(hasCheckedIn ? Icons.logout : Icons.login, color: Colors.white),
              label: Text(
                isLoading ? 'Processing...' : (hasCheckedIn ? 'Check Out' : 'Check In'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.success.withOpacity(0.3))),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Text("Today's attendance completed!", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 16)),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
            color: _inGeofence ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14)),
          child: Icon(_locating ? Icons.gps_not_fixed : (_inGeofence ? Icons.location_on : Icons.location_off),
              color: _locating ? AppColors.textSecondary : (_inGeofence ? AppColors.success : AppColors.warning), size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_locating ? 'Locating...' : (_locationError != null ? 'Location Error' : (_inGeofence ? 'Within Office Zone ✓' : 'Outside Office Zone')),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                  color: _inGeofence ? AppColors.success : AppColors.warning)),
          if (_position != null)
            Text('${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          if (_locationError != null)
            Text(_locationError!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ])),
        if (_locating) const CircularProgressIndicator(strokeWidth: 2),
      ]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool hasCheckedIn, hasCheckedOut;
  final dynamic record;
  const _StatusCard({required this.hasCheckedIn, required this.hasCheckedOut, this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Text("Today's Status", style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Text(hasCheckedOut ? 'Day Complete' : (hasCheckedIn ? 'Checked In' : 'Not Checked In'),
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        if (record != null && hasCheckedIn) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _TimeChip(label: 'IN', time: record.checkIn?.time),
            if (hasCheckedOut) ...[const SizedBox(width: 12), _TimeChip(label: 'OUT', time: record.checkOut?.time)],
            if (hasCheckedOut && record.workingHours > 0) ...[
              const SizedBox(width: 12),
              _TimeChip(label: 'HRS', time: null, extra: '${record.workingHours.toStringAsFixed(1)}h'),
            ],
          ]),
        ],
      ]),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final DateTime? time;
  final String? extra;
  const _TimeChip({required this.label, this.time, this.extra});

  @override
  Widget build(BuildContext context) {
    String display = extra ?? (time != null ? '${time!.hour.toString().padLeft(2,'0')}:${time!.minute.toString().padLeft(2,'0')}' : '--:--');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(display, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _SelfieCard extends StatelessWidget {
  final File? selfie;
  final VoidCallback onTap;
  const _SelfieCard({this.selfie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selfie != null ? AppColors.primary : AppColors.border, width: selfie != null ? 2 : 1),
        ),
        child: selfie != null
            ? ClipRRect(borderRadius: BorderRadius.circular(15),
                child: Image.file(selfie!, fit: BoxFit.cover))
            : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.camera_alt_outlined, size: 42, color: AppColors.textHint),
                const SizedBox(height: 10),
                const Text('Tap to take selfie', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                const Text('Required for attendance', style: TextStyle(color: AppColors.textHint, fontSize: 12)),
              ]),
      ),
    );
  }
}
