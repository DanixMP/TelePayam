enum UserRole {
  student,
  professor,
  staff,
  moderator,
  admin,
  superAdmin,
  unknown;

  bool get isAdmin => this == admin || this == superAdmin;
  bool get canChat => this == student || this == professor;
  String get wireValue => this == superAdmin ? 'super_admin' : name;

  static UserRole fromJson(String value) => UserRole.values.firstWhere(
    (role) => role.wireValue == value,
    orElse: () => UserRole.unknown,
  );
}

enum AccountStatus {
  pendingProfile('pending_profile'),
  pendingApproval('pending_approval'),
  active('active'),
  suspended('suspended'),
  banned('banned'),
  rejected('rejected');

  const AccountStatus(this.wireValue);

  final String wireValue;

  static AccountStatus fromJson(String value) =>
      AccountStatus.values.firstWhere(
        (status) => status.wireValue == value,
        orElse: () => AccountStatus.pendingProfile,
      );
}

class Account {
  const Account({
    required this.id,
    required this.phone,
    required this.role,
    required this.status,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.handle,
    this.avatarId,
    this.bio,
    this.correctionNote,
  });

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: json['id'].toString(),
    phone: json['phone'].toString(),
    role: UserRole.fromJson(json['role'].toString()),
    status: AccountStatus.fromJson(json['status'].toString()),
    createdAt:
        DateTime.tryParse(json['created_at']?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    firstName: json['first_name']?.toString(),
    lastName: json['last_name']?.toString(),
    handle: json['handle']?.toString(),
    avatarId: json['avatar_id']?.toString(),
    bio: json['bio']?.toString(),
    correctionNote: json['correction_note']?.toString(),
  );

  final String id;
  final String phone;
  final UserRole role;
  final AccountStatus status;
  final DateTime createdAt;
  final String? firstName;
  final String? lastName;
  final String? handle;
  final String? avatarId;
  final String? bio;
  final String? correctionNote;

  String get displayName => [
    firstName,
    lastName,
  ].whereType<String>().where((part) => part.isNotEmpty).join(' ');

  Account copyWith({
    AccountStatus? status,
    String? firstName,
    String? lastName,
    String? correctionNote,
  }) => Account(
    id: id,
    phone: phone,
    role: role,
    status: status ?? this.status,
    createdAt: createdAt,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    handle: handle,
    avatarId: avatarId,
    bio: bio,
    correctionNote: correctionNote,
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.account,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['access_token'].toString(),
    refreshToken: json['refresh_token'].toString(),
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 900,
    account: Account.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Account account;
}

class OtpChallenge {
  const OtpChallenge({required this.retryAfter, this.developmentCode});

  final int retryAfter;
  final String? developmentCode;
}

class StudentProfileDraft {
  const StudentProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.nationalId,
    required this.degree,
    required this.department,
    required this.universityId,
  });

  final String firstName;
  final String lastName;
  final String nationalId;
  final String degree;
  final String department;
  final String universityId;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'national_id': nationalId,
    'degree': degree,
    'department': department,
    'university_id': universityId,
  };
}

class ProfessorProfileDraft {
  const ProfessorProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.department,
    required this.title,
  });

  final String firstName;
  final String lastName;
  final String department;
  final String title;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'department': department,
    'title': title,
  };
}
