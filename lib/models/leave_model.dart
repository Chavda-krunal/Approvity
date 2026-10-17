class LeaveModel {
  final String id;
  final String facultyId;
  final String facultyName;
  final String leaveType; // e.g., 'Full Day', 'Half Day'
  final DateTime dateRequested;
  final String status; // 'pending', 'granted', 'not_granted'
  final DateTime appliedOn;
  final String hodId;

  LeaveModel({
    required this.id,
    required this.facultyId,
    required this.facultyName,
    required this.leaveType,
    required this.dateRequested,
    required this.status,
    required this.appliedOn,
    required this.hodId,
  });

  // Converts Firebase document data into a Dart object
  factory LeaveModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LeaveModel(
      id: documentId,
      facultyId: map['facultyId'] ?? '',
      facultyName: map['facultyName'] ?? '',
      leaveType: map['leaveType'] ?? '',
      // Firebase stores dates as Timestamps, so we convert them to Dart DateTimes
      dateRequested: (map['dateRequested'] as dynamic).toDate(),
      status: map['status'] ?? 'pending',
      appliedOn: (map['appliedOn'] as dynamic).toDate(),
      hodId: map['hodId'] ?? '',
    );
  }

  // Converts a Dart object into JSON data for Firebase
  Map<String, dynamic> toMap() {
    return {
      'facultyId': facultyId,
      'facultyName': facultyName,
      'leaveType': leaveType,
      'dateRequested': dateRequested,
      'status': status,
      'appliedOn': appliedOn,
      'hodId': hodId,
    };
  }
}