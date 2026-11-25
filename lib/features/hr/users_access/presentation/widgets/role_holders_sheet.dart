import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/app_api_client.dart';
import '../../../../../core/network/json_codec.dart';
import '../../../../../core/widgets/app_bottom_sheet.dart';

/// Web Roles → "Holders" — lists users assigned to a role.
Future<void> showRoleHoldersSheet(
  BuildContext context, {
  required AppApiClient api,
  required String roleId,
  required String roleName,
}) {
  return showAppBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RoleHoldersSheet(
      api: api,
      roleId: roleId,
      roleName: roleName,
    ),
  );
}

class _RoleHoldersSheet extends StatefulWidget {
  final AppApiClient api;
  final String roleId;
  final String roleName;

  const _RoleHoldersSheet({
    required this.api,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<_RoleHoldersSheet> createState() => _RoleHoldersSheetState();
}

class _RoleHoldersSheetState extends State<_RoleHoldersSheet> {
  bool _loading = true;
  String? _error;
  List<_Holder> _holders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.api.get(
      ApiEndpoints.roleMembers(widget.roleId),
      silent: true,
    );
    if (!mounted) return;
    result.when(
      success: (body) {
        final rows = JsonCodec.unwrapList(body).whereType<Map>();
        setState(() {
          _holders = [
            for (final row in rows) _Holder.fromJson(JsonCodec.asMap(row)),
          ];
          _loading = false;
        });
      },
      failure: (error) => setState(() {
        _loading = false;
        _error = error.message;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Holders',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.roleName,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _holders.isEmpty
                          ? const Center(
                              child: Text(
                                'No users hold this role yet.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _holders.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final h = _holders[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    h.name,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (h.email.isNotEmpty) h.email,
                                      if (h.status.isNotEmpty) h.status,
                                    ].join(' · '),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Holder {
  final String name;
  final String email;
  final String status;

  const _Holder({
    required this.name,
    required this.email,
    required this.status,
  });

  factory _Holder.fromJson(Map<String, dynamic> json) {
    return _Holder(
      name: JsonCodec.stringOr(json['name'], 'User'),
      email: JsonCodec.stringOr(json['email'], ''),
      status: JsonCodec.stringOr(json['status'], ''),
    );
  }
}
