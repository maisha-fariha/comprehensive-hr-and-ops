import '../../../../core/network/json_codec.dart';

class DirectorySummary {
  final int people;
  final int employees;
  final int family;
  final int withLogin;
  final int withoutLogin;
  final int active;
  final int invited;
  final int inactive;
  final int neverSignedIn;
  final int linkedToStaff;
  final List<RoleCount> byRole;

  const DirectorySummary({
    this.people = 0,
    this.employees = 0,
    this.family = 0,
    this.withLogin = 0,
    this.withoutLogin = 0,
    this.active = 0,
    this.invited = 0,
    this.inactive = 0,
    this.neverSignedIn = 0,
    this.linkedToStaff = 0,
    this.byRole = const [],
  });

  factory DirectorySummary.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const DirectorySummary();
    int n(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final roles = <RoleCount>[];
    final raw = json['byRole'];
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final m = JsonCodec.asMap(item);
        roles.add(
          RoleCount(
            code: JsonCodec.stringOr(m['code'], ''),
            name: JsonCodec.stringOr(m['name'], ''),
            people: n(m['people'] ?? m['count']),
          ),
        );
      }
    }
    return DirectorySummary(
      // Directory meta.summary uses `users`; some payloads still send `people`.
      people: n(json['people'] ?? json['users']),
      employees: n(json['employees']),
      family: n(json['family']),
      withLogin: n(json['withLogin']),
      withoutLogin: n(json['withoutLogin']),
      active: n(json['active']),
      invited: n(json['invited']),
      inactive: n(json['inactive']),
      neverSignedIn: n(json['neverSignedIn']),
      linkedToStaff: n(json['linkedToStaff']),
      byRole: roles,
    );
  }
}

class RoleCount {
  final String code;
  final String name;
  final int people;

  const RoleCount({
    required this.code,
    required this.name,
    required this.people,
  });
}

class DirectoryPerson {
  final String id;
  final String staffId;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String userType;
  final String status;
  final String accountStatus;
  final bool hasLogin;
  final DateTime? lastLoginAt;
  final String certificationStatus;
  final String employeeCode;
  final List<String> roleNames;
  final List<String> roleCodes;
  final List<String> roleIds;
  final List<String> residenceNames;
  final List<String> linkedClientNames;
  final String? photoUrl;

  const DirectoryPerson({
    required this.id,
    required this.staffId,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    required this.status,
    required this.accountStatus,
    required this.hasLogin,
    required this.lastLoginAt,
    required this.certificationStatus,
    required this.employeeCode,
    required this.roleNames,
    required this.roleCodes,
    required this.roleIds,
    required this.residenceNames,
    required this.linkedClientNames,
    this.photoUrl,
  });

  bool get isEmployee => userType.toLowerCase() == 'employee';
  bool get isFamily => userType.toLowerCase() == 'family';
  bool get isActive =>
      status.toLowerCase() == 'active' ||
      accountStatus.toLowerCase() == 'active';
  bool get isDeactivated =>
      status.toLowerCase() == 'inactive' ||
      accountStatus.toLowerCase() == 'inactive' ||
      status.toLowerCase() == 'deactivated';

  String get typeLabel {
    if (isEmployee) return 'Employee';
    if (isFamily) return 'Family';
    return userType.isEmpty ? 'Person' : userType;
  }

  String get roleLabel =>
      roleNames.isEmpty ? '—' : roleNames.join(', ');

  String get residenceLabel {
    if (residenceNames.isNotEmpty) {
      final first = residenceNames.first;
      final extra = residenceNames.length - 1;
      return extra > 0 ? '$first +$extra' : first;
    }
    if (linkedClientNames.isNotEmpty) {
      return linkedClientNames.join(', ');
    }
    return '—';
  }

  String get loginLabel {
    if (!hasLogin) return 'No login';
    final at = lastLoginAt;
    if (at == null) return 'Never signed in';
    final now = DateTime.now();
    final local = at.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    if (day == today) return 'Today · last seen';
    final days = today.difference(day).inDays;
    if (days == 1) return 'Yesterday · last seen';
    if (days < 14) return '${days}d ago · last seen';
    return '${local.day}/${local.month}/${local.year} · last seen';
  }

  String get certificationLabel {
    final c = certificationStatus.trim();
    if (c.isEmpty || c == '—' || c.toLowerCase() == 'none') return 'None';
    return c;
  }

  factory DirectoryPerson.fromJson(Map<String, dynamic> json) {
    final roles = <String>[];
    final codes = <String>[];
    final ids = <String>[];
    final rawRoles = json['roles'];
    if (rawRoles is List) {
      for (final item in rawRoles) {
        if (item is Map) {
          final m = JsonCodec.asMap(item);
          final name = JsonCodec.stringOr(m['name'], '');
          final code = JsonCodec.stringOr(m['code'], '');
          final id = JsonCodec.stringOr(m['id'], '');
          if (name.isNotEmpty) roles.add(name);
          if (code.isNotEmpty) codes.add(code);
          if (id.isNotEmpty) ids.add(id);
        } else if (item is String && item.isNotEmpty) {
          roles.add(item);
          codes.add(item);
        }
      }
    }
    final residences = <String>[];
    final rawRes = json['residences'];
    if (rawRes is List) {
      for (final item in rawRes) {
        if (item is Map) {
          final name = JsonCodec.stringOr(JsonCodec.asMap(item)['name'], '');
          if (name.isNotEmpty) residences.add(name);
        } else if (item is String && item.isNotEmpty) {
          residences.add(item);
        }
      }
    }
    final clients = <String>[];
    final rawClients = json['linkedClients'];
    if (rawClients is List) {
      for (final item in rawClients) {
        if (item is Map) {
          final m = JsonCodec.asMap(item);
          final name = JsonCodec.stringOr(
            m['clientName'] ?? m['name'],
            '',
          );
          if (name.isNotEmpty) clients.add(name);
        }
      }
    }
    return DirectoryPerson(
      id: JsonCodec.stringOr(json['id'], ''),
      staffId: JsonCodec.stringOr(json['staffId'], ''),
      userId: JsonCodec.stringOr(json['userId'], ''),
      name: JsonCodec.stringOr(json['name'], 'Person'),
      email: JsonCodec.stringOr(json['email'], ''),
      phone: JsonCodec.stringOr(json['phone'], ''),
      userType: JsonCodec.stringOr(json['userType'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
      accountStatus: JsonCodec.stringOr(json['accountStatus'], ''),
      hasLogin: JsonCodec.boolean(json['hasLogin']) ?? false,
      lastLoginAt: JsonCodec.dateTime(json['lastLoginAt']),
      certificationStatus: JsonCodec.stringOr(
        json['certificationStatus'] ?? json['trainingStatus'],
        '',
      ),
      employeeCode: JsonCodec.stringOr(json['employeeCode'], ''),
      roleNames: roles,
      roleCodes: codes,
      roleIds: ids,
      residenceNames: residences,
      linkedClientNames: clients,
      photoUrl: _photoUrl(json),
    );
  }

  static String? _photoUrl(Map<String, dynamic> json) {
    final raw =
        json['photoUrl'] ?? json['photo'] ?? json['avatar'] ?? json['avatarUrl'];
    if (raw is Map) {
      return JsonCodec.string(
        raw['fileUrl'] ?? raw['url'] ?? raw['path'],
      );
    }
    return JsonCodec.string(raw);
  }
}

class StaffCategoryItem {
  final String id;
  final String name;
  final String residenceType;
  final bool isActive;

  const StaffCategoryItem({
    required this.id,
    required this.name,
    required this.residenceType,
    required this.isActive,
  });

  factory StaffCategoryItem.fromJson(Map<String, dynamic> json) {
    return StaffCategoryItem(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(json['name'], ''),
      residenceType: JsonCodec.stringOr(json['residenceType'], ''),
      isActive: JsonCodec.boolean(json['isActive']) ?? true,
    );
  }
}

class DirectoryPage {
  final List<DirectoryPerson> people;
  final DirectorySummary summary;
  final int total;

  const DirectoryPage({
    required this.people,
    required this.summary,
    required this.total,
  });
}
