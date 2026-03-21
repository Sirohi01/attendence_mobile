import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/attendance/screens/check_in_screen.dart';
import '../../features/attendance/screens/attendance_history_screen.dart';
import '../../features/leave/screens/leave_list_screen.dart';
import '../../features/leave/screens/apply_leave_screen.dart';
import '../../features/tasks/screens/task_list_screen.dart';
import '../../features/tasks/screens/task_detail_screen.dart';
import '../../features/salary/screens/salary_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/change_password_screen.dart';
import '../constants/app_constants.dart';
import '../widgets/main_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppConstants.splashRoute,
    redirect: (context, state) {
      final isLoggedIn = authState.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final isLoading = authState.maybeWhen(loading: () => true, orElse: () => false);
      final isOnSplash = state.matchedLocation == AppConstants.splashRoute;
      final isOnLogin = state.matchedLocation == AppConstants.loginRoute;

      print('🧭 Router redirect - isLoggedIn: $isLoggedIn, isLoading: $isLoading, location: ${state.matchedLocation}');

      if (isLoading) {
        print('⏳ Still loading, staying on splash');
        return isOnSplash ? null : AppConstants.splashRoute;
      }
      if (!isLoggedIn && !isOnLogin) {
        print('🔒 Not logged in, redirecting to login');
        return AppConstants.loginRoute;
      }
      if (isLoggedIn && (isOnLogin || isOnSplash)) {
        print('✅ Logged in, redirecting to dashboard');
        return AppConstants.dashboardRoute;
      }
      print('➡️ No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppConstants.dashboardRoute,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppConstants.checkInRoute,
            builder: (context, state) => const CheckInScreen(),
          ),
          GoRoute(
            path: AppConstants.attendanceHistoryRoute,
            builder: (context, state) => const AttendanceHistoryScreen(),
          ),
          GoRoute(
            path: AppConstants.leaveRoute,
            builder: (context, state) => const LeaveListScreen(),
          ),
          GoRoute(
            path: AppConstants.applyLeaveRoute,
            builder: (context, state) => const ApplyLeaveScreen(),
          ),
          GoRoute(
            path: AppConstants.tasksRoute,
            builder: (context, state) => const TaskListScreen(),
          ),
          GoRoute(
            path: AppConstants.taskDetailRoute,
            builder: (context, state) {
              final taskId = state.pathParameters['id'];
              if (taskId == null || taskId.isEmpty) {
                return const Scaffold(
                  body: Center(child: Text('Invalid task ID')),
                );
              }
              return TaskDetailScreen(taskId: taskId);
            },
          ),
          GoRoute(
            path: AppConstants.salaryRoute,
            builder: (context, state) => const SalaryListScreen(),
          ),
          GoRoute(
            path: AppConstants.profileRoute,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: AppConstants.changePasswordRoute,
            builder: (context, state) => const ChangePasswordScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
