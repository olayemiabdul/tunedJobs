class JobAlert {
  final String id;
  final String userId;
  final String userEmail;  // Add this field
  final String jobTitle;
  final String location;
  final bool emailNotification;
  final bool appNotification;
  final String frequency;

  JobAlert({
    required this.id,
    required this.userId,
    required this.userEmail,  // Add this
    required this.jobTitle,
    required this.location,
    required this.emailNotification,
    required this.appNotification,
    required this.frequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,  // Add this
      'jobTitle': jobTitle,
      'location': location,
      'emailNotification': emailNotification,
      'appNotification': appNotification,
      'frequency': frequency,
    };
  }
}