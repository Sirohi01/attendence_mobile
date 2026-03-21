import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/salary_model.dart';
import '../providers/salary_provider.dart';
import 'salary_detail_screen.dart';

class SalaryListScreen extends ConsumerStatefulWidget {
  const SalaryListScreen({super.key});

  @override
  ConsumerState<SalaryListScreen> createState() => _SalaryListScreenState();
}

class _SalaryListScreenState extends ConsumerState<SalaryListScreen> {
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mySalariesProvider.notifier).loadSalaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final salariesAsync = ref.watch(mySalariesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Salary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          salariesAsync.when(
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
            data: (salaries) => _buildSummaryCards(salaries),
          ),
          
          // Salary List
          Expanded(
            child: salariesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('Error: $error', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.read(mySalariesProvider.notifier).loadSalaries(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (salaries) {
                if (salaries.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('No salary records found', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () => ref.read(mySalariesProvider.notifier).loadSalaries(
                    month: _selectedMonth,
                    year: _selectedYear,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: salaries.length,
                    itemBuilder: (context, index) => _SalaryCard(salary: salaries[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSummaryCards(List<SalaryModel> salaries) {
    if (salaries.isEmpty) return const SizedBox();
    
    final totalEarned = salaries.fold<double>(0, (sum, s) => sum + s.netSalary);
    final paidRecords = salaries.where((s) => s.status == 'paid').length;
    final pendingRecords = salaries.where((s) => s.status == 'processed').length;
    
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final thisMonthSalary = salaries.firstWhere(
      (s) => s.month == currentMonth && s.year == currentYear,
      orElse: () => SalaryModel(
        id: '', month: currentMonth, year: currentYear, totalWorkingDays: 0,
        presentDays: 0, absentDays: 0, halfDays: 0, lateDays: 0, leaveDays: 0,
        totalOvertimeHours: 0, basicSalary: 0, dailyRate: 0, effectiveDays: 0,
        earnedBasic: 0, overtimePay: 0, bonus: 0, allowances: {}, grossEarnings: 0,
        deductions: {}, totalDeductions: 0, netSalary: 0, status: 'draft',
      ),
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: _SummaryCard('Total Earned', '₹${NumberFormat('#,##,###').format(totalEarned)}', AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard('This Month', '₹${NumberFormat('#,##,###').format(thisMonthSalary.netSalary)}', AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard('Paid', '$paidRecords', AppColors.success)),
          const SizedBox(width: 12),
          Expanded(child: _SummaryCard('Pending', '$pendingRecords', AppColors.warning)),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Salary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _selectedYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: List.generate(5, (i) => DateTime.now().year - i)
                  .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                  .toList(),
              onChanged: (value) => setState(() => _selectedYear = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedMonth,
              decoration: const InputDecoration(labelText: 'Month'),
              items: List.generate(12, (i) => i + 1)
                  .map((month) => DropdownMenuItem(
                        value: month,
                        child: Text(DateFormat('MMMM').format(DateTime(2024, month))),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedMonth = value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedYear = null;
                _selectedMonth = null;
              });
              Navigator.pop(context);
              ref.read(mySalariesProvider.notifier).loadSalaries();
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(mySalariesProvider.notifier).loadSalaries(
                month: _selectedMonth,
                year: _selectedYear,
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SalaryCard extends StatelessWidget {
  final SalaryModel salary;

  const _SalaryCard({required this.salary});

  Color get _statusColor {
    switch (salary.status) {
      case 'paid':
        return AppColors.success;
      case 'processed':
        return AppColors.primary;
      case 'draft':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SalaryDetailScreen(salary: salary),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  salary.payPeriod,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    salary.status.toUpperCase(),
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Net Salary',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,###').format(salary.netSalary)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${salary.presentDays}/${salary.totalWorkingDays} days',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (salary.paidAt != null)
                      Text(
                        'Paid ${DateFormat('MMM d').format(salary.paidAt!)}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}