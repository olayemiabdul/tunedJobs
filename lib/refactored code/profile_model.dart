class UserProfile {
  final String? firstName;
  final String? lastName;
  final String? location;
  final String? phone;
  final String? customImageUrl;
  final String? currentJob;
  final String? preferredJob;

  UserProfile({
    this.firstName,
    this.lastName,
    this.location,
    this.phone,
    this.customImageUrl,
    this.currentJob,
    this.preferredJob,
  });

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? location,
    String? phone,
    String? customImageUrl,
    String? currentJob,
    String? preferredJob,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      customImageUrl: customImageUrl ?? this.customImageUrl,
      currentJob: currentJob ?? this.currentJob,
      preferredJob: preferredJob ?? this.preferredJob,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'location': location,
      'phone': phone,
      'customImageUrl': customImageUrl,
      'currentJob': currentJob,
      'preferredJob': preferredJob,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      firstName: map['firstName'],
      lastName: map['lastName'],
      location: map['location'],
      phone: map['phone'],
      customImageUrl: map['customImageUrl'],
      currentJob: map['currentJob'],
      preferredJob: map['preferredJob'],
    );
  }
}