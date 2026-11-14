import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../widgets/role_form_sheets.dart';
import '../widgets/role_holders_sheet.dart';
import 'role_permissions_page.dart';

/// Web `/dashboard/users` ("Users & Access") — users directory plus roles
/// with create / rename / holders / permissions (`roles:write`).
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
  String _userQuery = '';
  bool _creatingRole = false;

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
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    _refresh();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool get _onRolesTab {
    if (!_canRoles) return false;
    if (!_canUsers) return true;
    return _tabs.index == 1;
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

  Future<void> _createRole() async {
    if (!_canWriteRoles || _creatingRole) return;
    setState(() => _creatingRole = true);
    final created = await showNewRoleSheet(context, api: _api);
    if (!mounted) return;
    setState(() => _creatingRole = false);
    if (created == null) return;
    await _loadRoles();
    final id = JsonCodec.stringOr(created['id'], '');
    final name = JsonCodec.stringOr(
      created['name'],
      JsonCodec.stringOr(created['code'], 'Role'),
    );
    if (id.isEmpty || !_canWriteRoles) return;
    final open = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grant permissions?'),
        content: Text(
          '"$name" starts with no permissions. Open the Permissions editor now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
            ),
            child: const Text('Permissions'),
          ),
        ],
      ),
    );
    if (open == true && mounted) {
      await _openPermissions(
        _AccessRole(
          id: id,
          name: name,
          code: JsonCodec.stringOr(created['code'], ''),
          description: JsonCodec.stringOr(created['description'], ''),
          permissionCount: 0,
          userCount: 0,
          builtIn: false,
          permissions: const [],
        ),
      );
    }
  }

  Future<void> _renameRole(_AccessRole role) async {
    if (!_canWriteRoles || role.id.isEmpty) return;
    final updated = await showRenameRoleSheet(
      context,
      api: _api,
      roleId: role.id,
      name: role.name,
      description: role.description,
    );
    if (!mounted || updated == null) return;
    setState(() {
      _roles = [
        for (final r in _roles)
          if (r.id == role.id)
            r.copyWith(
              name: JsonCodec.stringOr(updated['name'], r.name),
              description:
                  JsonCodec.stringOr(updated['description'], r.description),
            )
          else
            r,
      ]..sort((a, b) => a.name.compareTo(b.name));
    });
  }

  Future<void> _showHolders(_AccessRole role) async {
    if (role.id.isEmpty) return;
    await showRoleHoldersSheet(
      context,
      api: _api,
      roleId: role.id,
      roleName: role.name,
    );
  }

  Future<void> _deleteRole(_AccessRole role) async {
    if (!_canWriteRoles || role.id.isEmpty || role.builtIn) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete role?'),
        content: Text(
          'Delete "${role.name}" (${role.code})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.criticalRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final result = await _api.delete(ApiEndpoints.roleById(role.id));
    if (!mounted) return;
    result.when(
      success: (_) {
        setState(() {
          _roles = [for (final r in _roles) if (r.id != role.id) r];
        });
        AppSnackbar.show('Role deleted', role.name, force: true);
      },
      failure: (error) {
        AppSnackbar.show('Could not delete', error.message, force: true);
      },
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
      floatingActionButton: _canWriteRoles && _onRolesTab
          ? FloatingActionButton.extended(
              onPressed: _creatingRole ? null : _createRole,
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(_creatingRole ? 'Creating…' : 'New role'),
            )
          : null,
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
    final q = _userQuery.trim().toLowerCase();
    final users = q.isEmpty
        ? _users
        : [
            for (final user in _users)
              if (user.name.toLowerCase().contains(q) ||
                  user.email.toLowerCase().contains(q) ||
                  user.roleLabels.any((r) => r.toLowerCase().contains(q)) ||
                  user.status.toLowerCase().contains(q))
                user,
          ];
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: users.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return TextField(
            onChanged: (v) => setState(() => _userQuery = v),
            decoration: const InputDecoration(
              hintText: 'Search by name, email, or role',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          );
        }
        final user = users[index - 1];
        return SurfaceCard.card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (user.status.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.filterButtonBackground,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      user.status,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
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
            onRename: _canWriteRoles ? () => _renameRole(roles[i]) : null,
            onHolders: () => _showHolders(roles[i]),
            onDelete: _canWriteRoles && !roles[i].builtIn
                ? () => _deleteRole(roles[i])
                : null,
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
  final VoidCallback? onRename;
  final VoidCallback? onHolders;
  final VoidCallback? onDelete;

  const _RoleCard({
    required this.role,
    required this.canOpenPermissions,
    required this.canWrite,
    required this.onPermissions,
    this.onRename,
    this.onHolders,
    this.onDelete,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (role.code.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          role.code,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
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
              const SizedBox(height: 6),
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
            if (canOpenPermissions ||
                onRename != null ||
                onHolders != null ||
                onDelete != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (onRename != null)
                    OutlinedButton(
                      onPressed: onRename,
                      child: const Text('Rename'),
                    ),
                  if (onHolders != null)
                    OutlinedButton(
                      onPressed: onHolders,
                      child: const Text('Holders'),
                    ),
                  if (onDelete != null)
                    OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.criticalRed,
                      ),
                      child: const Text('Delete'),
                    ),
                  if (canOpenPermissions)
                    FilledButton.tonal(
                      onPressed: onPermissions,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                      ),
                      child:
                          Text(canWrite ? 'Permissions' : 'View permissions'),
                    ),
                ],
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
  final String status;
  final List<String> roleLabels;

  const _AccessUser({
    required this.name,
    required this.email,
    required this.status,
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
      status: JsonCodec.stringOr(json['status'], ''),
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
    String? name,
    String? description,
    List<String>? permissions,
    int? permissionCount,
    int? userCount,
  }) {
    return _AccessRole(
      id: id,
      name: name ?? this.name,
      code: code,
      description: description ?? this.description,
      permissionCount: permissionCount ?? this.permissionCount,
      userCount: userCount ?? this.userCount,
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
      builtIn: JsonCodec.boolean(json['isSystem']) ??
          JsonCodec.boolean(json['builtIn'] ?? json['isBuiltIn']) ??
          JsonCodec.boolean(json['system']) ??
          false,
      permissions: permissions,
    );
  }
}
