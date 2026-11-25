import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';

/// Web "New role" modal — code is permanent; name/description can change later.
Future<Map<String, dynamic>?> showNewRoleSheet(
  BuildContext context, {
  required AppApiClient api,
}) {
  return showAppBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoleFormSheet(api: api, mode: _RoleFormMode.create),
  );
}

/// Web "Rename" — PATCH `/roles/:id` with name + optional description.
Future<Map<String, dynamic>?> showRenameRoleSheet(
  BuildContext context, {
  required AppApiClient api,
  required String roleId,
  required String name,
  required String description,
}) {
  return showAppBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoleFormSheet(
      api: api,
      mode: _RoleFormMode.rename,
      roleId: roleId,
      initialName: name,
      initialDescription: description,
    ),
  );
}

enum _RoleFormMode { create, rename }

class _RoleFormSheet extends StatefulWidget {
  final AppApiClient api;
  final _RoleFormMode mode;
  final String? roleId;
  final String initialName;
  final String initialDescription;

  const _RoleFormSheet({
    required this.api,
    required this.mode,
    this.roleId,
    this.initialName = '',
    this.initialDescription = '',
  });

  @override
  State<_RoleFormSheet> createState() => _RoleFormSheetState();
}

class _RoleFormSheetState extends State<_RoleFormSheet> {
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _saving = false;
  String? _error;
  bool _codeTouched = false;

  bool get _isCreate => widget.mode == _RoleFormMode.create;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController(text: widget.initialName);
    _description = TextEditingController(text: widget.initialDescription);
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  static final _codePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  String _slugify(String raw) {
    final lower = raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return lower.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final description = _description.text.trim();
    final code = _code.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (_isCreate) {
      if (code.isEmpty) {
        setState(() => _error = 'Code is required.');
        return;
      }
      if (!_codePattern.hasMatch(code)) {
        setState(
          () => _error =
              'Code must be lowercase letters, numbers, and underscores (e.g. night_supervisor).',
        );
        return;
      }
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    if (_isCreate) {
      final result = await widget.api.post(
        ApiEndpoints.roles,
        data: {
          'code': code,
          'name': name,
          if (description.isNotEmpty) 'description': description,
        },
      );
      if (!mounted) return;
      result.when(
        success: (body) {
          final map = JsonCodec.unwrapMap(body);
          Navigator.of(context).pop(map.isEmpty ? {'code': code, 'name': name} : map);
          AppSnackbar.show(
            'Role created',
            'Grant permissions from the Permissions button.',
            force: true,
          );
        },
        failure: (error) => setState(() {
          _saving = false;
          _error = error.message;
        }),
      );
      return;
    }

    final result = await widget.api.patch(
      ApiEndpoints.roleById(widget.roleId!),
      data: {
        'name': name,
        'description': description,
      },
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final map = JsonCodec.unwrapMap(body);
        Navigator.of(context).pop({
          'name': name,
          'description': description,
          if (map.isNotEmpty) ...map,
        });
        AppSnackbar.show('Role updated', name, force: true);
      },
      failure: (error) => setState(() {
        _saving = false;
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cardBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, color: AppColors.primaryNavy),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCreate ? 'New role' : 'Rename role',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isCreate
                                ? 'The code is permanent once created; the label can be changed later.'
                                : 'Update the display name and description. The code stays the same.',
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isCreate) ...[
                  const Text(
                    'Code *',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _code,
                    enabled: !_saving,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                    ],
                    onChanged: (_) {
                      _codeTouched = true;
                      if (_error != null) setState(() => _error = null);
                    },
                    decoration: const InputDecoration(
                      hintText: 'e.g. night_supervisor',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  'Name *',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    if (_isCreate && !_codeTouched) {
                      final slug = _slugify(v);
                      if (slug.isNotEmpty && _codePattern.hasMatch(slug)) {
                        _code.text = slug;
                        _code.selection = TextSelection.collapsed(offset: slug.length);
                      }
                    }
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _description,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_isCreate) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'A new role starts with no permissions — grant them from the Permissions button once it exists.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      color: AppColors.criticalRed,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                        ),
                        child: Text(
                          _saving
                              ? (_isCreate ? 'Creating…' : 'Saving…')
                              : (_isCreate ? 'Create role' : 'Save'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
