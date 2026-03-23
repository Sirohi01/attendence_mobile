import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/salary_model.dart';

class SalaryDetailScreen extends StatelessWidget {
  final SalaryModel salary;

  const SalaryDetailScreen({super.key, required this.salary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(salary.payPeriod),
        actions: [
          if (salary.status == 'paid')
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download feature coming soon')),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 20),
            
            // Attendance Summary
            _buildAttendanceCard(),
            const SizedBox(height: 20),
            
            // Earnings Breakdown
            _buildEarningsCard(),
            const SizedBox(height: 20),
            
            // Deductions Breakdown
            _buildDeductionsCard(),
            const SizedBox(height: 20),
            
            // Net Salary
            _buildNetSalaryCard(),
            const SizedBox(height: 20),
            
            // Payment Info
            if (salary.paidAt != null) _buildPaymentInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (salary.status) {
      case 'paid':
        statusColor = AppColors.success;
        statusText = 'PAID';
        statusIcon = Icons.check_circle;
        break;
      case 'processed':
        statusColor = AppColors.primary;
        statusText = 'PROCESSED';
        statusIcon = Icons.schedule;
        break;
      case 'draft':
        statusColor = AppColors.warning;
        statusText = 'DRAFT';
        statusIcon = Icons.edit;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = 'UNKNOWN';
        statusIcon = Icons.help;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(statusIcon, size: 40, color: statusColor),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            salary.payPeriod,
            style: TextStyle(
              fontSize: 14,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return _buildCard(
      'Attendance Summary',
      Icons.calendar_today,
      [
        _buildDetailRow('Total Working Days', '${salary.totalWorkingDays}'),
        _buildDetailRow('Present Days', '${salary.presentDays}'),
        _buildDetailRow('Absent Days', '${salary.absentDays}'),
        _buildDetailRow('Half Days', '${salary.halfDays}'),
        _buildDetailRow('Late Days', '${salary.lateDays}'),
        _buildDetailRow('Leave Days', '${salary.leaveDays}'),
        _buildDetailRow('Overtime Hours', '${salary.totalOvertimeHours}'),
      ],
    );
  }

  Widget _buildEarningsCard() {
    return _buildCard(
      'Earnings Breakdown',
      Icons.trending_up,
      [
        _buildDetailRow('Basic Salary', '₹${NumberFormat('#,##,###').format(salary.basicSalary)}'),
        _buildDetailRow('Daily Rate', '₹${NumberFormat('#,##,###').format(salary.dailyRate)}'),
        _buildDetailRow('Effective Days', '${salary.effectiveDays}'),
        _buildDetailRow('Earned Basic', '₹${NumberFormat('#,##,###').format(salary.earnedBasic)}'),
        _buildDetailRow('Overtime Pay', '₹${NumberFormat('#,##,###').format(salary.overtimePay)}'),
        _buildDetailRow('Bonus', '₹${NumberFormat('#,##,###').format(salary.bonus)}'),
        
        // Allowances
        if (salary.allowances.isNotEmpty) ...[
          const Divider(height: 20),
          const Text('Allowances', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ...salary.allowances.entries.map((e) => 
            _buildDetailRow(e.key.toUpperCase(), '₹${NumberFormat('#,##,###').format(e.value)}')),
        ],
        
        const Divider(height: 20),
        _buildDetailRow('Gross Earnings', '₹${NumberFormat('#,##,###').format(salary.grossEarnings)}', 
                       isTotal: true, color: AppColors.success),
      ],
    );
  }

  Widget _buildDeductionsCard() {
    return _buildCard(
      'Deductions Breakdown',
      Icons.trending_down,
      [
        if (salary.deductions.isNotEmpty) ...[
          ...salary.deductions.entries.map((e) => 
            _buildDetailRow(e.key.toUpperCase(), '₹${NumberFormat('#,##,###').format(e.value)}')),
          const Divider(height: 20),
        ],
        _buildDetailRow('Total Deductions', '₹${NumberFormat('#,##,###').format(salary.totalDeductions)}', 
                       isTotal: true, color: AppColors.error),
      ],
    );
  }

  Widget _buildNetSalaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Net Salary',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(salary.netSalary)}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return _buildCard(
      'Payment Information',
      Icons.payment,
      [
        _buildDetailRow('Payment Date', DateFormat('MMM dd, yyyy').format(salary.paidAt!)),
        if (salary.paymentRef != null) 
          _buildDetailRow('Payment Reference', salary.paymentRef!),
        if (salary.remarks != null) 
          _buildDetailRow('Remarks', salary.remarks!),
      ],
    );
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: color ?? AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}