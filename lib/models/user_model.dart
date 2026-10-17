class UserModel {
  final String uid;
  final String name;
  final String role; // 'faculty' or 'hod'
  final String department;
  final String fcmToken;

  UserModel({
    required this.uid,
    required this.name,
    required this.role,
    required this.department,
    required this.fcmToken,
  });

  // Converts Firebase document data into a Dart object
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      role: map['role'] ?? 'faculty',
      department: map['department'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
    );
  }

  // Converts a Dart object into JSON data for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'department': department,
      'fcmToken': fcmToken,
    };
  }
}