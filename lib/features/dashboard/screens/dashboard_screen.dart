import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../attendance/providers/attendance_provider.dart';
import '../../tasks/providers/task_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(todayAttendanceProvider.notifier).loadToday();
      ref.read(myTasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(todayAttendanceProvider.notifier).loadToday();
            ref.read(myTasksProvider.notifier).loadTasks();
          },
          child: CustomScrollView(
            slivers: [
              // ─── App Bar ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getGreeting(),
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.fullName ?? 'Employee',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            child: Text(
                              user?.initials ?? 'NA',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(now),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── Today's Status ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Attendance", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      _AttendanceStatusCard(attendance: todayAttendance),
                      const SizedBox(height: 24),

                      // Quick Actions
                      const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _QuickActionCard(
                            icon: Icons.fingerprint,
                            label: 'Check In/Out',
                            color: AppColors.primary,
                            onTap: () => context.go(AppConstants.checkInRoute),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _QuickActionCard(
                            icon: Icons.event_note,
                            label: 'Apply Leave',
                            color: AppColors.secondary,
                            onTap: () => context.go(AppConstants.applyLeaveRoute),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _QuickActionCard(
                            icon: Icons.account_balance_wallet,
                            label: 'My Salary',
                            color: AppColors.success,
                            onTap: () => context.go(AppConstants.salaryRoute),
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _QuickActionCard(
                            icon: Icons.history,
                            label: 'History',
                            color: AppColors.accent,
                            onTap: () => context.go(AppConstants.attendanceHistoryRoute),
                          )),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Leave Balance
                      const Text('Leave Balance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      _LeaveBalanceRow(leaveBalance: user?.leaveBalance ?? {}),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }
}

class _AttendanceStatusCard extends StatelessWidget {
  final dynamic attendance;
  const _AttendanceStatusCard({required this.attendance});

  @override
  Widget build(BuildContext context) {
    final hasCheckedIn = attendance?.checkIn?.time != null;
    final hasCheckedOut = attendance?.checkOut?.time != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: hasCheckedIn ? AppColors.presentGreen.withValues(alpha: 0.12) : AppColors.absentRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              hasCheckedIn ? Icons.check_circle_outline : Icons.radio_button_unchecked,
              color: hasCheckedIn ? AppColors.presentGreen : AppColors.absentRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCheckedIn ? (hasCheckedOut ? 'Completed' : 'Checked In') : 'Not Checked In',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                if (hasCheckedIn)
                  Text('In: ${_formatTime(attendance?.checkIn?.time)}${hasCheckedOut ? '  •  Out: ${_formatTime(attendance?.checkOut?.time)}' : ''}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
                else
                  const Text("Tap 'Check In/Out' to mark attendance", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic time) {
    if (time == null) return '--:--';
    final dt = time is DateTime ? time : DateTime.tryParse(time.toString());
    if (dt == null) return '--:--';
    return DateFormat('HH:mm').format(dt);
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _LeaveBalanceRow extends StatelessWidget {
  final Map<String, dynamic> leaveBalance;
  const _LeaveBalanceRow({required this.leaveBalance});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Casual', leaveBalance['casual'] ?? 0, AppColors.primary),
      ('Sick', leaveBalance['sick'] ?? 0, AppColors.error),
      ('Earned', leaveBalance['earned'] ?? 0, AppColors.success),
    ];

    return Row(
      children: items.map((item) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: items.indexOf(item) < 2 ? 10 : 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(item.$2.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: item.$3)),
              const SizedBox(height: 4),
              Text(item.$1, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
