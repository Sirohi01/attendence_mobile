class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? dueDate;
  final double loggedHours;
  final bool isOverdue;
  final List<dynamic> assignedTo; // Can be List<String> or List<Map<String, dynamic>>
  final Map<String, dynamic>? assignedBy;

  TaskModel({required this.id, required this.title, this.description,
      required this.status, required this.priority, this.dueDate,
      this.loggedHours = 0, this.isOverdue = false,
      this.assignedTo = const [], this.assignedBy});

  factory TaskModel.fromJson(Map<String, dynamic> j) => TaskModel(
      id: j['_id'] ?? '', 
      title: j['title'] ?? '',
      description: j['description'],
      status: j['status'] ?? 'todo', 
      priority: j['priority'] ?? 'medium',
      dueDate: j['dueDate'] != null ? DateTime.tryParse(j['dueDate']) : null,
      loggedHours: (j['loggedHours'] ?? 0).toDouble(),
      isOverdue: j['isOverdue'] ?? false,
      assignedTo: j['assignedTo'] is List 
          ? List<dynamic>.from(j['assignedTo']) 
          : <dynamic>[],
      assignedBy: j['assignedBy'] is Map<String, dynamic> 
          ? j['assignedBy'] 
          : null);
}
