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
import 'role_permissions_page.dart';

/// Web `/dashboard/users` ("Users & Access") — users directory plus roles
/// with the Permissions editor (`roles:write`).
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
  String _roleQuery = '';

  bool get _canUsers => _session.can('users:read');
  bool get _canRoles => _session.can('roles:read');
  bool get _canWriteRoles => _session.can('roles:write');

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

  Future<void> _openPermissions(_AccessRole role) async {
    if (role.id.isEmpty) return;
    final updated = await Get.to<List<String>>(
      () => RolePermissionsPage(
        roleId: role.id,
        roleName: role.name,
        initialPermissions: role.permissions,
      ),
    );
    if (!mounted || updated == null) return;
    setState(() {
      _roles = [
        for (final r in _roles)
          if (r.id == role.id)
            r.copyWith(
              permissions: updated,
              permissionCount: updated.length,
            )
          else
            r,
      ];
    });
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
    final q = _roleQuery.trim().toLowerCase();
    final roles = q.isEmpty
        ? _roles
        : [
            for (final role in _roles)
              if (role.name.toLowerCase().contains(q) ||
                  role.code.toLowerCase().contains(q) ||
                  role.description.toLowerCase().contains(q))
                role,
          ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        TextField(
          onChanged: (v) => setState(() => _roleQuery = v),
          decoration: const InputDecoration(
            hintText: 'Search by role name or code',
            prefixIcon: Icon(Icons.search_rounded),
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < roles.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _RoleCard(
            role: roles[i],
            canOpenPermissions: _canRoles && roles[i].id.isNotEmpty,
            canWrite: _canWriteRoles,
            onPermissions: () => _openPermissions(roles[i]),
          ),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final _AccessRole role;
  final bool canOpenPermissions;
  final bool canWrite;
  final VoidCallback onPermissions;

  const _RoleCard({
    required this.role,
    required this.canOpenPermissions,
    required this.canWrite,
    required this.onPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return SurfaceCard.card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    role.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (role.builtIn)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Built in',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (role.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                role.description,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${role.permissionCount} granted'
              '${role.userCount == null ? '' : ' · ${role.userCount} holders'}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            if (canOpenPermissions) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onPermissions,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(canWrite ? 'Permissions' : 'View permissions'),
                ),
              ),
            ],
          ],
        ),
      ),
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
  final String id;
  final String name;
  final String code;
  final String description;
  final int permissionCount;
  final int? userCount;
  final bool builtIn;
  final List<String> permissions;

  const _AccessRole({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.permissionCount,
    required this.userCount,
    required this.builtIn,
    required this.permissions,
  });

  _AccessRole copyWith({
    List<String>? permissions,
    int? permissionCount,
  }) {
    return _AccessRole(
      id: id,
      name: name,
      code: code,
      description: description,
      permissionCount: permissionCount ?? this.permissionCount,
      userCount: userCount,
      builtIn: builtIn,
      permissions: permissions ?? this.permissions,
    );
  }

  factory _AccessRole.fromJson(Map<String, dynamic> json) {
    final rawPerms = json['permissions'];
    final permissions = <String>[];
    if (rawPerms is List) {
      for (final item in rawPerms) {
        if (item is String && item.isNotEmpty) {
          permissions.add(item);
        } else if (item is Map) {
          final map = JsonCodec.asMap(item);
          final key = JsonCodec.string(map['key']) ??
              JsonCodec.string(map['name']) ??
              '';
          if (key.isNotEmpty) permissions.add(key);
        }
      }
    }
    return _AccessRole(
      id: JsonCodec.stringOr(json['id'], ''),
      name: JsonCodec.stringOr(
        json['name'],
        JsonCodec.stringOr(json['code'], 'Role'),
      ),
      code: JsonCodec.stringOr(json['code'], ''),
      description: JsonCodec.stringOr(json['description'], ''),
      permissionCount: permissions.isNotEmpty
          ? permissions.length
          : () {
              final raw = json['permissionCount'] ?? json['permissionsCount'];
              if (raw is int) return raw;
              if (raw is num) return raw.toInt();
              return int.tryParse('$raw') ?? 0;
            }(),
      userCount: () {
        final raw = json['userCount'] ?? json['holdersCount'];
        if (raw is int) return raw;
        if (raw is num) return raw.toInt();
        return int.tryParse('$raw');
      }(),
      builtIn: JsonCodec.boolean(json['builtIn'] ?? json['isBuiltIn']) ??
          JsonCodec.boolean(json['system']) ??
          false,
      permissions: permissions,
    );
  }
}
