enum UserRole { customer, provider }

class UserProfile {
  final String uid;
  final String? displayName;
  final String? companyName;
  final String? truckPhotoUrl;
  final String? licenseInfo;
  final double rating;
  final UserRole role;
  final String? fcmToken;

  UserProfile({
    required this.uid,
    required this.role,
    this.displayName,
    this.companyName,
    this.truckPhotoUrl,
    this.licenseInfo,
    this.rating = 0,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'role': role.name,
        'displayName': displayName,
        'companyName': companyName,
        'truckPhotoUrl': truckPhotoUrl,
        'licenseInfo': licenseInfo,
        'rating': rating,
        'fcmToken': fcmToken,
      };

  static UserProfile fromMap(Map<String, dynamic> m) => UserProfile(
        uid: m['uid'],
        role: (m['role'] == 'provider') ? UserRole.provider : UserRole.customer,
        displayName: m['displayName'],
        companyName: m['companyName'],
        truckPhotoUrl: m['truckPhotoUrl'],
        licenseInfo: m['licenseInfo'],
        rating: (m['rating'] ?? 0).toDouble(),
        fcmToken: m['fcmToken'],
      );
}

