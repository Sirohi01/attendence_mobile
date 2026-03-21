import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/leave_model.dart';

class LeaveListNotifier extends StateNotifier<AsyncValue<List<LeaveModel>>> {
  final ApiClient _api;
  LeaveListNotifier(this._api) : super(const AsyncLoading());

  Future<void> loadLeaves({String? status}) async {
    state = const AsyncLoading();
    try {
      final params = <String, dynamic>{'limit': 50};
      if (status != null) params['status'] = status;
      final res = await _api.get('/leaves/my', queryParameters: params);
      final records = (res.data['data'] as List).map((e) => LeaveModel.fromJson(e)).toList();
      state = AsyncData(records);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<String?> applyLeave(Map<String, dynamic> data) async {
    try {
      await _api.post('/leaves', data: data);
      await loadLeaves();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> cancelLeave(String leaveId, String reason) async {
    try {
      await _api.patch('/leaves/$leaveId/cancel', data: {'reason': reason});
      await loadLeaves();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }
}

final leaveListProvider = StateNotifierProvider<LeaveListNotifier, AsyncValue<List<LeaveModel>>>((ref) =>
    LeaveListNotifier(ref.watch(apiClientProvider)));
