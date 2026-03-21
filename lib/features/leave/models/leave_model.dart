class LeaveModel {
  final String id;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final double totalDays;
  final String reason;
  final String status;
  final bool isHalfDay;
  final String? rejectionReason;
  final DateTime createdAt;

  LeaveModel({required this.id, required this.leaveType, required this.startDate,
      required this.endDate, required this.totalDays, required this.reason,
      required this.status, this.isHalfDay = false, this.rejectionReason, required this.createdAt});

  factory LeaveModel.fromJson(Map<String, dynamic> j) => LeaveModel(
      id: j['_id'] ?? '', leaveType: j['leaveType'] ?? '',
      startDate: DateTime.tryParse(j['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(j['endDate'] ?? '') ?? DateTime.now(),
      totalDays: (j['totalDays'] ?? 0).toDouble(),
      reason: j['reason'] ?? '', status: j['status'] ?? 'pending',
      isHalfDay: j['isHalfDay'] ?? false, rejectionReason: j['rejectionReason'],
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now());
}
