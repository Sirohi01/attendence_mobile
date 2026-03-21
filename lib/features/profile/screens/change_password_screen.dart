import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(apiClientProvider).put('/auth/change-password', data: {
        'currentPassword': _currentCtrl.text,
        'newPassword': _newCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppColors.success));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Change Password')),
    body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(20), children: [
      const SizedBox(height: 12),
      _buildField('Current Password', _currentCtrl),
      const SizedBox(height: 16),
      _buildField('New Password', _newCtrl),
      const SizedBox(height: 16),
      _buildField('Confirm New Password', _confirmCtrl, validator: (v) => v != _newCtrl.text ? 'Passwords do not match' : null),
      const SizedBox(height: 32),
      ElevatedButton(onPressed: _loading ? null : _submit, child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Password')),
    ])),
  );

  Widget _buildField(String label, TextEditingController ctrl, {String? Function(String?)? validator}) =>
      TextFormField(controller: ctrl, obscureText: true,
        decoration: InputDecoration(labelText: label),
        validator: validator ?? (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null);
}
