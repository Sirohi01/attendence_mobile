import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/leave_provider.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});
  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'casual';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _isHalfDay = false;
  bool _loading = false;

  final _leaveTypes = ['casual', 'sick', 'earned', 'unpaid'];
  final _fmt = DateFormat('MMM d, yyyy');

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context, initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End date must be after start date'), backgroundColor: AppColors.error));
      return;
    }
    setState(() => _loading = true);
    final error = await ref.read(leaveListProvider.notifier).applyLeave({
      'leaveType': _leaveType,
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate.toIso8601String(),
      'reason': _reasonCtrl.text.trim(),
      'isHalfDay': _isHalfDay,
    });
    setState(() => _loading = false);
    if (mounted) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppColors.error));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave applied successfully!'), backgroundColor: AppColors.success));
        context.go(AppConstants.leaveRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply Leave')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildLabel('Leave Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _leaveType,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
              items: _leaveTypes.map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()))).toList(),
              onChanged: (v) => setState(() => _leaveType = v!),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLabel('Start Date'),
                const SizedBox(height: 8),
                _DatePickerField(date: _startDate, label: _fmt.format(_startDate), onTap: () => _pickDate(true)),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildLabel('End Date'),
                const SizedBox(height: 8),
                _DatePickerField(date: _endDate, label: _fmt.format(_endDate), onTap: () => _pickDate(false)),
              ])),
            ]),
            const SizedBox(height: 16),
            SwitchListTile(
              value: _isHalfDay,
              onChanged: (v) => setState(() => _isHalfDay = v),
              title: const Text('Half Day', style: TextStyle(fontWeight: FontWeight.w600)),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            _buildLabel('Reason'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the reason for leave...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));
}

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final String label;
  final VoidCallback onTap;
  const _DatePickerField({required this.date, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(14), color: AppColors.background),
      child: Row(children: [
        const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
