import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/task_model.dart';

class MyTasksNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final ApiClient _api;
  MyTasksNotifier(this._api) : super(const AsyncLoading());

  Future<void> loadTasks({String? status}) async {
    state = const AsyncLoading();
    try {
      final params = <String, dynamic>{'limit': 50};
      if (status != null) params['status'] = status;
      final res = await _api.get('/tasks/my', queryParameters: params);
      
      final data = res.data['data'];
      if (data is! List) {
        throw Exception('Expected list of tasks but got ${data.runtimeType}');
      }
      
      final tasks = data.map((e) {
        try {
          return TaskModel.fromJson(e as Map<String, dynamic>);
        } catch (error) {
          print('Error parsing task: $error');
          print('Task data: $e');
          rethrow;
        }
      }).toList();
      
      state = AsyncData(tasks);
    } catch (e) { 
      print('Error loading tasks: $e');
      state = AsyncError(e, StackTrace.current); 
    }
  }

  Future<String?> updateStatus(String taskId, String newStatus, {String? notes}) async {
    try {
      await _api.put('/tasks/$taskId', data: {'status': newStatus, if (notes != null) 'completionNotes': notes});
      await loadTasks();
      return null;
    } catch (e) { return e.toString(); }
  }
}

final myTasksProvider = StateNotifierProvider<MyTasksNotifier, AsyncValue<List<TaskModel>>>((ref) =>
    MyTasksNotifier(ref.watch(apiClientProvider)));
