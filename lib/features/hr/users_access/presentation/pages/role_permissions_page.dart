import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/roles/app_permissions.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../../../core/widgets/app_refresh_indicator.dart';

/// Web Users & Access → Roles → Permissions modal.
///
/// Saving `PUT /roles/:id/permissions` with `{ permissionCodes: [...] }`
/// replaces the whole grant set (unticked keys are revoked).
class RolePermissionsPage extends StatefulWidget {
  final String roleId;
  final String roleName;
  final List<String> initialPermissions;

  const RolePermissionsPage({
    super.key,
    required this.roleId,
    required this.roleName,
    this.initialPermissions = const [],
  });

  @override
  State<RolePermissionsPage> createState() => _RolePermissionsPageState();
}

class _RolePermissionsPageState extends State<RolePermissionsPage> {
  late final AppApiClient _api;
  late final UserSession _session;
  late final Set<String> _selected;
  late final Map<String, List<String>> _groups;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _canWrite => _session.can('roles:write');

  @override
  void initState() {
    super.initState();
    _api = GetIt.instance<AppApiClient>();
    _session = Get.find<UserSession>();
    _groups = AppPermissions.catalogByGroup;
    _selected = {
      for (final key in widget.initialPermissions)
        if (AppPermissions.catalog.contains(key)) key,
    };
    if (widget.initialPermissions.isEmpty) {
      _reload();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _api.get(
      ApiEndpoints.roleById(widget.roleId),
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final map = JsonCodec.unwrapMap(body);
        final raw = JsonCodec.listAt(map, 'permissions');
        final keys = <String>{};
        for (final item in raw) {
          if (item is String && item.isNotEmpty) {
            keys.add(item);
          } else if (item is Map) {
            final m = JsonCodec.asMap(item);
            final key = JsonCodec.string(m['key']) ??
                JsonCodec.string(m['name']) ??
                '';
            if (key.isNotEmpty) keys.add(key);
          }
        }
        setState(() {
          _selected
            ..clear()
            ..addAll(keys.where(AppPermissions.catalog.contains));
          _loading = false;
        });
      },
      failure: (error) {
        // Fall back to list payload when GET /roles/:id is unavailable.
        setState(() {
          _loading = false;
          if (_selected.isEmpty) _error = error.message;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!_canWrite || _saving) return;
    setState(() => _saving = true);
    final keys = AppPermissions.catalog
        .where(_selected.contains)
        .toList(growable: false);
    // Web contract: PUT /roles/:id/permissions with permissionCodes (not
    // PATCH /roles/:id — that DTO rejects `permissions` as "No fields to update").
    final put = await _api.put(
      ApiEndpoints.rolePermissions(widget.roleId),
      data: {'permissionCodes': keys},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    put.when(
      success: (_) {
        AppSnackbar.show(
          'Permissions saved',
          '${keys.length} permission${keys.length == 1 ? '' : 's'} on ${widget.roleName}.',
          force: true,
        );
        Get.back(result: keys);
      },
      failure: (error) {
        AppSnackbar.show(
          'Could not save',
          error.message,
          force: true,
        );
      },
    );
  }

  void _toggleGroup(String group, List<String> keys, bool selectAll) {
    if (!_canWrite) return;
    setState(() {
      if (selectAll) {
        _selected.addAll(keys);
      } else {
        _selected.removeAll(keys);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        title: Text(
          'Permissions — ${widget.roleName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 17),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          Material(
            color: AppColors.surfaceWhite,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                _canWrite
                    ? 'Saving replaces the whole set; anything unticked is revoked.'
                    : 'You can view these grants. Updating them needs roles:write.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 13),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: AppRefreshIndicator(
              onRefresh: _reload,
              child: _loading && _selected.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _error != null && _selected.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(_error!)),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          children: [
                            for (final entry in _groups.entries) ...[
                              _PermissionGroupCard(
                                title: entry.key,
                                keys: entry.value,
                                selected: _selected,
                                canWrite: _canWrite,
                                onToggleKey: (key, on) => setState(() {
                                  if (on) {
                                    _selected.add(key);
                                  } else {
                                    _selected.remove(key);
                                  }
                                }),
                                onToggleGroup: (all) =>
                                    _toggleGroup(entry.key, entry.value, all),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
            ),
          ),
          if (_canWrite)
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                        ),
                        child: Text(
                          _saving
                              ? 'Saving…'
                              : 'Save $count permission${count == 1 ? '' : 's'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionGroupCard extends StatelessWidget {
  final String title;
  final List<String> keys;
  final Set<String> selected;
  final bool canWrite;
  final void Function(String key, bool on) onToggleKey;
  final ValueChanged<bool> onToggleGroup;

  const _PermissionGroupCard({
    required this.title,
    required this.keys,
    required this.selected,
    required this.canWrite,
    required this.onToggleKey,
    required this.onToggleGroup,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = keys.where(selected.contains).length;
    final allOn = enabled == keys.length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$title ($enabled of ${keys.length} enabled)',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (canWrite)
                  TextButton(
                    onPressed: () => onToggleGroup(!allOn),
                    child: Text(allOn ? 'Clear all' : 'Select all'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (final key in keys)
            CheckboxListTile(
              value: selected.contains(key),
              onChanged: canWrite
                  ? (v) => onToggleKey(key, v ?? false)
                  : null,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                AppPermissions.actionLabel(key),
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                AppPermissions.codeLabel(key),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
