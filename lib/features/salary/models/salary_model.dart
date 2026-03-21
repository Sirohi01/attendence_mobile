class SalaryModel {
  final String id;
  final int month;
  final int year;
  final int totalWorkingDays;
  final int presentDays;
  final int absentDays;
  final int halfDays;
  final int lateDays;
  final int leaveDays;
  final double totalOvertimeHours;
  final double basicSalary;
  final double dailyRate;
  final double effectiveDays;
  final double earnedBasic;
  final double overtimePay;
  final double bonus;
  final Map<String, double> allowances;
  final double grossEarnings;
  final Map<String, double> deductions;
  final double totalDeductions;
  final double netSalary;
  final String status;
  final DateTime? processedAt;
  final DateTime? paidAt;
  final String? paymentRef;
  final String? remarks;

  SalaryModel({
    required this.id,
    required this.month,
    required this.year,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.absentDays,
    required this.halfDays,
    required this.lateDays,
    required this.leaveDays,
    required this.totalOvertimeHours,
    required this.basicSalary,
    required this.dailyRate,
    required this.effectiveDays,
    required this.earnedBasic,
    required this.overtimePay,
    required this.bonus,
    required this.allowances,
    required this.grossEarnings,
    required this.deductions,
    required this.totalDeductions,
    required this.netSalary,
    required this.status,
    this.processedAt,
    this.paidAt,
    this.paymentRef,
    this.remarks,
  });

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String get payPeriod => '$monthName $year';

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      id: json['_id'] ?? '',
      month: json['month'] ?? 1,
      year: json['year'] ?? DateTime.now().year,
      totalWorkingDays: json['totalWorkingDays'] ?? 0,
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      halfDays: json['halfDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      leaveDays: json['leaveDays'] ?? 0,
      totalOvertimeHours: (json['totalOvertimeHours'] ?? 0).toDouble(),
      basicSalary: (json['basicSalary'] ?? 0).toDouble(),
      dailyRate: (json['dailyRate'] ?? 0).toDouble(),
      effectiveDays: (json['effectiveDays'] ?? 0).toDouble(),
      earnedBasic: (json['earnedBasic'] ?? 0).toDouble(),
      overtimePay: (json['overtimePay'] ?? 0).toDouble(),
      bonus: (json['bonus'] ?? 0).toDouble(),
      allowances: json['allowances'] != null 
          ? Map<String, double>.from(json['allowances'].map((k, v) => MapEntry(k, (v ?? 0).toDouble())))
          : {},
      grossEarnings: (json['grossEarnings'] ?? 0).toDouble(),
      deductions: json['deductions'] != null 
          ? Map<String, double>.from(json['deductions'].map((k, v) => MapEntry(k, (v ?? 0).toDouble())))
          : {},
      totalDeductions: (json['totalDeductions'] ?? 0).toDouble(),
      netSalary: (json['netSalary'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      processedAt: json['processedAt'] != null ? DateTime.tryParse(json['processedAt']) : null,
      paidAt: json['paidAt'] != null ? DateTime.tryParse(json['paidAt']) : null,
      paymentRef: json['paymentRef'],
      remarks: json['remarks'],
    );
  }
}