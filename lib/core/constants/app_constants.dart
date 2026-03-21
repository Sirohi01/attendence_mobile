class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'http://192.168.0.131:5000/api/v1'; // Real device
  // static const String baseUrl = 'http://10.0.2.2:5000/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:5000/api/v1'; // iOS simulator
  // static const String baseUrl = 'https://api.namoganga.com/api/v1'; // Production

  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Storage keys
  static const String hiveBoxName = 'namo_ganga_box';
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String offlineQueueKey = 'offline_queue';

  // Route names
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String attendanceRoute = '/attendance';
  static const String attendanceHistoryRoute = '/attendance/history';
  static const String checkInRoute = '/attendance/check-in';
  static const String leaveRoute = '/leave';
  static const String applyLeaveRoute = '/leave/apply';
  static const String tasksRoute = '/tasks';
  static const String taskDetailRoute = '/tasks/:id';
  static const String profileRoute = '/profile';
  static const String changePasswordRoute = '/profile/change-password';
  static const String notificationsRoute = '/notifications';
  static const String salaryRoute = '/salary';

  // Pagination
  static const int defaultPageSize = 10;

  // UI
  static const double borderRadius = 16.0;
  static const double cardElevation = 2.0;
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 16.0;

  // Geo-fencing (overridden by backend config)
  static const double officeLat = 28.6139;
  static const double officeLng = 77.2090;
  static const double officeRadius = 200.0; // meters
}
