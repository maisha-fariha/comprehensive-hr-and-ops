import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/surface_card.dart';

/// Web `/dashboard/users` ("Users & Access") — read-only directory of
/// accounts and roles for callers with `users:read` / `roles:read`.
class UsersAccessPage extends StatefulWidget {
  const UsersAccessPage({super.key});

  @override
  State<UsersAccessPage> createState() => _UsersAccessPageState();
}

class _UsersAccessPageState extends State<UsersAccessPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final UserSession _session;
  late final AppApiClient _api;

  List<_AccessUser> _users = const [];
  List<_AccessRole> _roles = const [];
  bool _loadingUsers = false;
  bool _loadingRoles = false;
  String? _usersError;
  String? _rolesError;

  bool get _canUsers => _session.can('users:read');
  bool get _canRoles => _session.can('roles:read');

  @override
  void initState() {
    super.initState();
    _session = Get.find<UserSession>();
    _api = GetIt.instance<AppApiClient>();
    final tabCount = (_canUsers ? 1 : 0) + (_canRoles ? 1 : 0);
    _tabs = TabController(length: tabCount < 1 ? 1 : tabCount, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      if (_canUsers) _loadUsers(),
      if (_canRoles) _loadRoles(),
    ]);
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    final result = await _api.get(
      ApiEndpoints.users,
      query: const {'page': 1, 'limit': 100},
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        setState(() {
          _users = [
            for (final row in rows)
              _AccessUser.fromJson(JsonCodec.asMap(row)),
          ];
          _loadingUsers = false;
        });
      },
      failure: (error) => setState(() {
        _loadingUsers = false;
        _usersError = error.message;
      }),
    );
  }

  Future<void> _loadRoles() async {
    setState(() {
      _loadingRoles = true;
      _rolesError = null;
    });
    final result = await _api.get(ApiEndpoints.roles, silent: true);
    if (!mounted) return;
    result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        setState(() {
          _roles = [
            for (final row in rows)
              _AccessRole.fromJson(JsonCodec.asMap(row)),
          ]..sort((a, b) => a.name.compareTo(b.name));
          _loadingRoles = false;
        });
      },
      failure: (error) => setState(() {
        _loadingRoles = false;
        _rolesError = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titles = <String>[
      if (_canUsers) 'Users',
      if (_canRoles) 'Roles',
    ];
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Users & Access',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: titles.length > 1
            ? TabBar(
                controller: _tabs,
                labelColor: AppColors.secondaryTeal,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.secondaryTeal,
                tabs: [for (final t in titles) Tab(text: t)],
              )
            : null,
      ),
      body: AppRefreshIndicator(
        onRefresh: _refresh,
        child: titles.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      'Users & Access is not available for your account.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              )
            : TabBarView(
                controller: _tabs,
                children: [
                  if (_canUsers) _usersPane(),
                  if (_canRoles) _rolesPane(),
                ],
              ),
      ),
    );
  }

  Widget _usersPane() {
    if (_loadingUsers && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_usersError != null && _users.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_usersError!)),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _users.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = _users[index];
        return SurfaceCard.card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              user.name,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              [
                if (user.email.isNotEmpty) user.email,
                if (user.roleLabels.isNotEmpty) user.roleLabels.join(', '),
              ].join('\n'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            isThreeLine: user.roleLabels.isNotEmpty && user.email.isNotEmpty,
          ),
        );
      },
    );
  }

  Widget _rolesPane() {
    if (_loadingRoles && _roles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_rolesError != null && _roles.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(child: Text(_rolesError!)),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _roles.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final role = _roles[index];
        return SurfaceCard.card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Text(
              role.name,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              [
                if (role.description.isNotEmpty) role.description,
                '${role.permissionCount} permissions'
                    '${role.userCount == null ? '' : ' · ${role.userCount} users'}',
              ].where((s) => s.isNotEmpty).join('\n'),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            isThreeLine: role.description.isNotEmpty,
          ),
        );
      },
    );
  }
}

class _AccessUser {
  final String name;
  final String email;
  final List<String> roleLabels;

  const _AccessUser({
    required this.name,
    required this.email,
    required this.roleLabels,
  });

  factory _AccessUser.fromJson(Map<String, dynamic> json) {
    final first = JsonCodec.stringOr(json['firstName'], '');
    final last = JsonCodec.stringOr(json['lastName'], '');
    final name = JsonCodec.stringOr(
      json['name'],
      '$first $last'.trim(),
    );
    final roles = <String>[];
    final raw = json['roles'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final map = JsonCodec.asMap(item);
          final label = JsonCodec.stringOr(
            map['name'],
            JsonCodec.stringOr(map['code'], ''),
          );
          if (label.isNotEmpty) roles.add(label);
        } else if (item is String && item.isNotEmpty) {
          roles.add(item);
        }
      }
    }
    return _AccessUser(
      name: name.isEmpty ? 'User' : name,
      email: JsonCodec.stringOr(json['email'], ''),
      roleLabels: roles,
    );
  }
}

class _AccessRole {
  final String name;
  final String description;
  final int permissionCount;
  final int? userCount;

  const _AccessRole({
    required this.name,
    required this.description,
    required this.permissionCount,
    required this.userCount,
  });

  factory _AccessRole.fromJson(Map<String, dynamic> json) {
    final perms = json['permissions'];
    return _AccessRole(
      name: JsonCodec.stringOr(
        json['name'],
        JsonCodec.stringOr(json['code'], 'Role'),
      ),
      description: JsonCodec.stringOr(json['description'], ''),
      permissionCount: perms is List ? perms.length : 0,
      userCount: () {
        final raw = json['userCount'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse('$raw');
      }(),
    );
  }
}
