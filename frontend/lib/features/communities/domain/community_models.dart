enum CommunityType {
  group,
  channel;

  static CommunityType fromWire(String value) =>
      CommunityType.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CommunityType.channel,
      );
}

enum CommunityVisibility {
  public,
  private;

  static CommunityVisibility fromWire(String value) =>
      CommunityVisibility.values.firstWhere(
        (item) => item.name == value,
        orElse: () => CommunityVisibility.private,
      );
}

enum CommunityMemberRole {
  owner,
  admin,
  member,
  subscriber,
  banned;

  static CommunityMemberRole? fromWire(String? value) {
    if (value == null) return null;
    return CommunityMemberRole.values.firstWhere(
      (item) => item.name == value,
      orElse: () => CommunityMemberRole.member,
    );
  }
}

class CommunityConversation {
  const CommunityConversation({
    required this.id,
    required this.type,
    required this.visibility,
    required this.title,
    required this.ownerId,
    required this.memberCount,
    required this.lastSequence,
    required this.isProfessorChannel,
    required this.settings,
    required this.createdAt,
    required this.lastReadSequence,
    required this.underReview,
    this.handle,
    this.description,
    this.myRole,
  });

  factory CommunityConversation.fromJson(Map<String, dynamic> json) =>
      CommunityConversation(
        id: json['id'].toString(),
        type: CommunityType.fromWire(json['type']?.toString() ?? ''),
        visibility: CommunityVisibility.fromWire(
          json['visibility']?.toString() ?? '',
        ),
        handle: json['handle']?.toString(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        ownerId: json['owner_id'].toString(),
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        lastSequence: (json['last_seq'] as num?)?.toInt() ?? 0,
        isProfessorChannel: json['is_professor_channel'] == true,
        settings: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
        ),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        myRole: CommunityMemberRole.fromWire(json['my_role']?.toString()),
        lastReadSequence: (json['last_read_seq'] as num?)?.toInt() ?? 0,
        underReview: json['under_review'] == true,
      );

  final String id;
  final CommunityType type;
  final CommunityVisibility visibility;
  final String? handle;
  final String title;
  final String? description;
  final String ownerId;
  final int memberCount;
  final int lastSequence;
  final bool isProfessorChannel;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final CommunityMemberRole? myRole;
  final int lastReadSequence;
  final bool underReview;

  bool get isMember => myRole != null && myRole != CommunityMemberRole.banned;
  bool get canManage =>
      myRole == CommunityMemberRole.owner ||
      myRole == CommunityMemberRole.admin;
  bool get isOwner => myRole == CommunityMemberRole.owner;
}

class CommunityUser {
  const CommunityUser({
    required this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.handle,
    this.avatarId,
    this.bio,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) => CommunityUser(
    id: json['id'].toString(),
    role: json['role']?.toString() ?? '',
    firstName: json['first_name']?.toString(),
    lastName: json['last_name']?.toString(),
    handle: json['handle']?.toString(),
    avatarId: json['avatar_id']?.toString(),
    bio: json['bio']?.toString(),
  );

  final String id;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? handle;
  final String? avatarId;
  final String? bio;

  String get displayName {
    final name = [
      firstName,
      lastName,
    ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
    return name.isNotEmpty ? name : '@${handle ?? id}';
  }
}

class CommunityMember {
  const CommunityMember({
    required this.user,
    required this.role,
    required this.adminRights,
    required this.joinedAt,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) =>
      CommunityMember(
        user: CommunityUser.fromJson(
          Map<String, dynamic>.from(json['user'] as Map),
        ),
        role:
            CommunityMemberRole.fromWire(json['role']?.toString()) ??
            CommunityMemberRole.member,
        adminRights: Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(json['admin_rights'] as Map? ?? const {}),
        ),
        joinedAt:
            DateTime.tryParse(json['joined_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final CommunityUser user;
  final CommunityMemberRole role;
  final Map<String, dynamic> adminRights;
  final DateTime joinedAt;
}

class CommunityInvite {
  const CommunityInvite({
    required this.id,
    required this.uses,
    required this.createdAt,
    this.token,
    this.expiresAt,
    this.maxUses,
    this.revokedAt,
  });

  factory CommunityInvite.fromJson(Map<String, dynamic> json) =>
      CommunityInvite(
        id: json['id'].toString(),
        token: json['token']?.toString(),
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
        uses: (json['uses'] as num?)?.toInt() ?? 0,
        maxUses: (json['max_uses'] as num?)?.toInt(),
        revokedAt: DateTime.tryParse(json['revoked_at']?.toString() ?? ''),
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  final String id;
  final String? token;
  final DateTime? expiresAt;
  final int uses;
  final int? maxUses;
  final DateTime? revokedAt;
  final DateTime createdAt;

  bool get isRevoked => revokedAt != null;
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isExhausted => maxUses != null && uses >= maxUses!;
}
