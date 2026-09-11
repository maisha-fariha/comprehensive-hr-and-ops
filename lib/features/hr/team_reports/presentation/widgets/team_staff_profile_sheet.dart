import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/team_staff_member.dart';
import '../../domain/entities/team_staff_profile.dart';
import '../../domain/repositories/team_reports_repository.dart';

Future<void> showTeamStaffListSheet(
  BuildContext context, {
  required List<TeamStaffMember> staff,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TeamStaffListSheet(staff: staff),
  );
}

Future<void> showTeamStaffProfileSheet(
  BuildContext context, {
  required String staffId,
  String? fallbackName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TeamStaffProfileSheet(
      staffId: staffId,
      fallbackName: fallbackName,
    ),
  );
}

class _TeamStaffListSheet extends StatelessWidget {
  final List<TeamStaffMember> staff;

  const _TeamStaffListSheet({required this.staff});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 20),
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Team roster',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          16,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: staff.isEmpty
                  ? const Center(child: Text('No staff found.'))
                  : ListView.separated(
                      padding: ResponsiveHelper.getResponsivePadding(
                        context,
                        horizontal: 8,
                        vertical: 8,
                      ),
                      itemCount: staff.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final member = staff[index];
                        return ListTile(
                          title: Text(
                            member.name,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: member.role == null
                              ? null
                              : Text(
                                  member.role!,
                                  style: const TextStyle(fontFamily: 'Outfit'),
                                ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).pop();
                            showTeamStaffProfileSheet(
                              context,
                              staffId: member.id,
                              fallbackName: member.name,
                            );
                          },
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

class _TeamStaffProfileSheet extends StatefulWidget {
  final String staffId;
  final String? fallbackName;

  const _TeamStaffProfileSheet({
    required this.staffId,
    this.fallbackName,
  });

  @override
  State<_TeamStaffProfileSheet> createState() => _TeamStaffProfileSheetState();
}

class _TeamStaffProfileSheetState extends State<_TeamStaffProfileSheet> {
  final _repository = GetIt.instance<TeamReportsRepository>();
  bool _loading = true;
  String _error = '';
  TeamStaffProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    // Profile endpoint loads detail; documents are fetched in the same call.
    final result = await _repository.getStaffProfile(widget.staffId);
    if (!mounted) return;
    result.when(
      success: (profile) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      },
      failure: (error) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
        AppSnackbar.show('Could not load profile', error.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final profile = _profile;
    final title = profile?.name ?? widget.fallbackName ?? 'Staff profile';

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              ResponsiveHelper.getResponsiveRadius(context, 20),
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          16,
                        ),
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    )
                  : _error.isNotEmpty && profile == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'Outfit'),
                            ),
                          ),
                        )
                      : ListView(
                          padding: ResponsiveHelper.getResponsivePadding(
                            context,
                            all: 16,
                          ),
                          children: [
                            if (profile != null) ...[
                              if (profile.role != null)
                                _InfoRow(label: 'Role', value: profile.role!),
                              if (profile.email != null)
                                _InfoRow(label: 'Email', value: profile.email!),
                              if (profile.phone != null)
                                _InfoRow(label: 'Phone', value: profile.phone!),
                              if (profile.residenceName != null)
                                _InfoRow(
                                  label: 'Residence',
                                  value: profile.residenceName!,
                                ),
                              SizedBox(
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  16,
                                ),
                              ),
                              Text(
                                'Documents',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontWeight: FontWeight.w700,
                                  fontSize:
                                      ResponsiveHelper.getResponsiveFontSize(
                                    context,
                                    14.5,
                                  ),
                                  color: AppColors.textHeading,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveHelper.getResponsiveHeight(
                                  context,
                                  8,
                                ),
                              ),
                              if (profile.documents.isEmpty)
                                Text(
                                  'No documents on file.',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: AppColors.textSecondary,
                                    fontSize:
                                        ResponsiveHelper.getResponsiveFontSize(
                                      context,
                                      13,
                                    ),
                                  ),
                                )
                              else
                                for (final doc in profile.documents)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      doc.title,
                                      style: const TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: doc.updatedLabel == null
                                        ? null
                                        : Text(
                                            doc.updatedLabel!,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                  ),
                            ],
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.getResponsiveWidth(context, 90),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13.5),
                color: AppColors.textHeading,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
