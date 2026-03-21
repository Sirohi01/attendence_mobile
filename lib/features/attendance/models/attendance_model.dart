class AttendanceLocation {
  final double latitude;
  final double longitude;
  AttendanceLocation({required this.latitude, required this.longitude});
  factory AttendanceLocation.fromJson(Map<String, dynamic> j) =>
      AttendanceLocation(latitude: (j['latitude'] ?? 0).toDouble(), longitude: (j['longitude'] ?? 0).toDouble());
}

class CheckEvent {
  final DateTime? time;
  final AttendanceLocation? location;
  final String? selfieUrl;
  final bool isWithinGeofence;
  CheckEvent({this.time, this.location, this.selfieUrl, this.isWithinGeofence = false});
  factory CheckEvent.fromJson(Map<String, dynamic> j) => CheckEvent(
        time: j['time'] != null ? DateTime.tryParse(j['time']) : null,
        location: j['location'] != null ? AttendanceLocation.fromJson(j['location']) : null,
        selfieUrl: j['selfieUrl'],
        isWithinGeofence: j['isWithinGeofence'] ?? false,
      );
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final CheckEvent? checkIn;
  final CheckEvent? checkOut;
  final String status;
  final double workingHours;
  final double overtimeHours;
  final int lateMinutes;
  final bool isLate;
  final bool isHalfDay;

  AttendanceRecord({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.workingHours = 0,
    this.overtimeHours = 0,
    this.lateMinutes = 0,
    this.isLate = false,
    this.isHalfDay = false,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: j['_id'] ?? '',
        date: DateTime.tryParse(j['date'] ?? '') ?? DateTime.now(),
        checkIn: j['checkIn'] != null ? CheckEvent.fromJson(j['checkIn']) : null,
        checkOut: j['checkOut'] != null ? CheckEvent.fromJson(j['checkOut']) : null,
        status: j['status'] ?? 'absent',
        workingHours: (j['workingHours'] ?? 0).toDouble(),
        overtimeHours: (j['overtimeHours'] ?? 0).toDouble(),
        lateMinutes: (j['lateMinutes'] ?? 0).toInt(),
        isLate: j['isLate'] ?? false,
        isHalfDay: j['isHalfDay'] ?? false,
      );
}
