import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/salary_model.dart';

class MySalariesNotifier extends StateNotifier<AsyncValue<List<SalaryModel>>> {
  final ApiClient _api;
  
  MySalariesNotifier(this._api) : super(const AsyncLoading());

  Future<void> loadSalaries({int? month, int? year}) async {
    state = const AsyncLoading();
    try {
      final params = <String, dynamic>{};
      if (month != null) params['month'] = month;
      if (year != null) params['year'] = year;
      
      final res = await _api.get('/salary/my', queryParameters: params);
      
      final data = res.data['data'];
      List<SalaryModel> salaries;
      
      if (data is List) {
        salaries = data.map((e) {
          try {
            return SalaryModel.fromJson(e as Map<String, dynamic>);
          } catch (error) {
            print('Error parsing salary: $error');
            print('Salary data: $e');
            rethrow;
          }
        }).toList();
      } else {
        salaries = [];
      }
      
      state = AsyncData(salaries);
    } catch (e) {
      print('Error loading salaries: $e');
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<SalaryModel?> getSalarySlip(int month, int year) async {
    try {
      final res = await _api.get('/salary/my/slip', queryParameters: {
        'month': month,
        'year': year,
      });
      
      return SalaryModel.fromJson(res.data['data']);
    } catch (e) {
      print('Error loading salary slip: $e');
      return null;
    }
  }
}

final mySalariesProvider = StateNotifierProvider<MySalariesNotifier, AsyncValue<List<SalaryModel>>>(
  (ref) => MySalariesNotifier(ref.watch(apiClientProvider))
);