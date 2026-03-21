class UserModel {
  final String id;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String? department;
  final String? designation;
  final String? avatar;
  final double basicSalary;
  final bool isActive;
  final Map<String, dynamic> leaveBalance;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.department,
    this.designation,
    this.avatar,
    this.basicSalary = 0,
    this.isActive = true,
    this.leaveBalance = const {},
  });

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}'.toUpperCase();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      employeeId: json['employeeId'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'employee',
      department: json['department'],
      designation: json['designation'],
      avatar: json['avatar'],
      basicSalary: (json['basicSalary'] ?? 0).toDouble(),
      isActive: json['isActive'] ?? true,
      leaveBalance: Map<String, dynamic>.from(json['leaveBalance'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'employeeId': employeeId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'role': role,
        'department': department,
        'designation': designation,
        'avatar': avatar,
        'basicSalary': basicSalary,
        'isActive': isActive,
        'leaveBalance': leaveBalance,
      };
}
