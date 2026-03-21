import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/attendance_model.dart';

class TodayAttendanceNotifier extends StateNotifier<AttendanceRecord?> {
  final ApiClient _api;
  TodayAttendanceNotifier(this._api) : super(null);

  Future<void> loadToday() async {
    try {
      final now = DateTime.now();
      final response = await _api.get('/attendance/my',
          queryParameters: {'month': now.month, 'year': now.year});
      final records = (response.data['data']['records'] as List)
          .map((e) => AttendanceRecord.fromJson(e))
          .toList();
      final today = records.where((r) {
        final d = r.date;
        return d.year == now.year && d.month == now.month && d.day == now.day;
      }).firstOrNull;
      state = today;
    } catch (_) {}
  }

  void updateRecord(AttendanceRecord record) => state = record;
}

final todayAttendanceProvider =
    StateNotifierProvider<TodayAttendanceNotifier, AttendanceRecord?>((ref) =>
        TodayAttendanceNotifier(ref.watch(apiClientProvider)));

class AttendanceHistoryNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final ApiClient _api;
  AttendanceHistoryNotifier(this._api) : super(const AsyncLoading());

  Future<void> loadHistory({required int month, required int year}) async {
    state = const AsyncLoading();
    try {
      final response = await _api.get('/attendance/my',
          queryParameters: {'month': month, 'year': year});
      state = AsyncData(response.data['data']);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final attendanceHistoryProvider = StateNotifierProvider<
    AttendanceHistoryNotifier,
    AsyncValue<Map<String, dynamic>>>((ref) =>
    AttendanceHistoryNotifier(ref.watch(apiClientProvider)));

class CheckInOutNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiClient _api;
  CheckInOutNotifier(this._api) : super(const AsyncData(null));

  FormData _buildFormData(double lat, double lng, String? filePath) {
    final data = FormData.fromMap(
        {'latitude': lat.toString(), 'longitude': lng.toString()});
    if (filePath != null) {
      data.files
          .add(MapEntry('selfie', MultipartFile.fromFileSync(filePath)));
    }
    return data;
  }

  Future<AttendanceRecord?> checkIn(
      {required double lat,
      required double lng,
      String? selfieFilePath}) async {
    state = const AsyncLoading();
    try {
      final res = await _api.postFormData(
          '/attendance/check-in', _buildFormData(lat, lng, selfieFilePath));
      state = const AsyncData(null);
      return AttendanceRecord.fromJson(res.data['data']);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  Future<AttendanceRecord?> checkOut(
      {required double lat,
      required double lng,
      String? selfieFilePath}) async {
    state = const AsyncLoading();
    try {
      final res = await _api.postFormData(
          '/attendance/check-out', _buildFormData(lat, lng, selfieFilePath));
      state = const AsyncData(null);
      return AttendanceRecord.fromJson(res.data['data']);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}

final checkInOutProvider =
    StateNotifierProvider<CheckInOutNotifier, AsyncValue<void>>((ref) =>
        CheckInOutNotifier(ref.watch(apiClientProvider)));
