import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          child: Column(children: [
            CircleAvatar(radius: 44, backgroundColor: Colors.white24,
                child: Text(user.initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white))),
            const SizedBox(height: 14),
            Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(user.designation ?? user.role.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 2),
            Text(user.employeeId, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ]),
        ),

        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          _InfoCard(items: [
            _InfoItem(Icons.email_outlined, 'Email', user.email),
            _InfoItem(Icons.phone_outlined, 'Phone', user.phone),
            _InfoItem(Icons.business_outlined, 'Department', user.department ?? 'N/A'),
            _InfoItem(Icons.work_outline, 'Designation', user.designation ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _MenuTile(icon: Icons.lock_outline, label: 'Change Password', onTap: () => context.go(AppConstants.changePasswordRoute)),
          _MenuTile(icon: Icons.notifications_outlined, label: 'Notifications', onTap: () {}),
          _MenuTile(icon: Icons.help_outline, label: 'Help & Support', onTap: () {}),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _showLogoutDialog(context, ref),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(double.infinity, 52)),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ])),
      ]),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () { Navigator.pop(ctx); ref.read(authStateProvider.notifier).logout(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Sign Out'),
        ),
      ],
    ));
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.divider)),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      ListTile(leading: Icon(e.value.icon, color: AppColors.primary, size: 22), title: Text(e.value.label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)), subtitle: Text(e.value.value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      if (e.key < items.length - 1) const Divider(height: 1),
    ])).toList()),
  );
}

class _InfoItem {
  final IconData icon;
  final String label, value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)), trailing: const Icon(Icons.chevron_right, color: AppColors.textHint), onTap: onTap));
}
