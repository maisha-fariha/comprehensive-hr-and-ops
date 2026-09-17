import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/family_notification_preference.dart';
import '../controllers/family_profile_settings_controller.dart';
import '../widgets/family_profile_settings_header.dart';

/// Full-screen notification prefs: GET prefs + events, PUT …/bulk on save.
class FamilyNotificationPreferencesPage extends StatefulWidget {
  const FamilyNotificationPreferencesPage({super.key});

  @override
  State<FamilyNotificationPreferencesPage> createState() =>
      _FamilyNotificationPreferencesPageState();
}

class _FamilyNotificationPreferencesPageState
    extends State<FamilyNotificationPreferencesPage> {
  late final FamilyProfileSettingsController _controller;
  List<FamilyNotificationPreference> _prefs = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<FamilyProfileSettingsController>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await _controller.loadNotificationPreferences();
    if (!mounted) return;
    if (prefs == null) {
      setState(() {
        _loading = false;
        _error = 'Could not load notification preferences.';
        _prefs = const [];
      });
      return;
    }
    setState(() {
      _loading = false;
      _prefs = List<FamilyNotificationPreference>.from(prefs);
      if (_prefs.isEmpty) {
        _error = 'No configurable notification settings for this account yet.';
      }
    });
  }

  Future<void> _save() async {
    if (_saving || _prefs.isEmpty) return;
    setState(() => _saving = true);
    final ok = await _controller.saveNotificationPreferences(_prefs);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.surfaceWhite,
              child: FamilyProfileSettingsHeader(
                onBackTap: () => Navigator.maybePop(context),
                initials: _controller.overview?.profile.initials ?? '',
                title: 'Notification Preferences',
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    )
                  : _prefs.isEmpty
                      ? Center(
                          child: Padding(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              all: 24,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error ??
                                      'No configurable notification settings.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                SizedBox(
                                  height: ResponsiveHelper.getResponsiveHeight(
                                    context,
                                    12,
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _load,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.secondaryTeal,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.secondaryTeal,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: ResponsiveHelper.getResponsivePadding(
                              context,
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _prefs.length,
                            separatorBuilder: (_, _) => SizedBox(
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                8,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final pref = _prefs[index];
                              return Material(
                                color: AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(
                                  ResponsiveHelper.getResponsiveRadius(
                                    context,
                                    14,
                                  ),
                                ),
                                child: SwitchListTile(
                                  contentPadding:
                                      ResponsiveHelper.getResponsivePadding(
                                    context,
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  title: Text(
                                    pref.label,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w600,
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(context, 14),
                                      color: const Color(0xFF1A2B48),
                                    ),
                                  ),
                                  subtitle: Text(
                                    pref.channelLabel,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w500,
                                      fontSize: ResponsiveHelper
                                          .getResponsiveFontSize(context, 12),
                                      color: const Color(0xFF71839B),
                                    ),
                                  ),
                                  value: pref.enabled,
                                  activeThumbColor: AppColors.secondaryTeal,
                                  onChanged: _saving
                                      ? null
                                      : (value) => setState(() {
                                            _prefs[index] =
                                                pref.copyWith(enabled: value);
                                          }),
                                ),
                              );
                            },
                          ),
                        ),
            ),
            if (_prefs.isNotEmpty)
              SafeArea(
                top: false,
                child: Padding(
                  padding: ResponsiveHelper.getResponsivePadding(
                    context,
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryTeal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveHelper.getResponsiveHeight(
                            context,
                            14,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveHelper.getResponsiveRadius(context, 12),
                          ),
                        ),
                      ),
                      child: _saving
                          ? SizedBox(
                              width: ResponsiveHelper.getResponsiveWidth(
                                context,
                                18,
                              ),
                              height: ResponsiveHelper.getResponsiveHeight(
                                context,
                                18,
                              ),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save preferences',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                                fontSize: ResponsiveHelper.getResponsiveFontSize(
                                  context,
                                  15,
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
