import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../../communication/domain/entities/hr_message_contact.dart';
import '../../../communication/domain/repositories/communication_repository.dart';
import '../../domain/entities/missed_medication.dart';

/// Contact Staff flow for a missed administration:
/// `GET /conversations/contacts` → pick contact → `POST /conversations`.
Future<void> showContactStaffSheet(
  BuildContext context, {
  required MissedMedication medication,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ContactStaffSheet(medication: medication),
  );
}

class _ContactStaffSheet extends StatefulWidget {
  final MissedMedication medication;

  const _ContactStaffSheet({required this.medication});

  @override
  State<_ContactStaffSheet> createState() => _ContactStaffSheetState();
}

class _ContactStaffSheetState extends State<_ContactStaffSheet> {
  late final CommunicationRepository _repo;
  List<HrMessageContact> _contacts = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _repo = GetIt.instance<CommunicationRepository>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getContacts();
    if (!mounted) return;
    result.when(
      success: (contacts) {
        final preferred = widget.medication.assigneeUserId?.trim();
        setState(() {
          _contacts = contacts;
          _loading = false;
          if (preferred != null &&
              preferred.isNotEmpty &&
              contacts.any((c) => c.id == preferred)) {
            _selectedId = preferred;
          }
        });
      },
      failure: (error) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      },
    );
  }

  Future<void> _start() async {
    final selected = _selectedId?.trim();
    if (selected == null || selected.isEmpty) {
      AppSnackbar.show('Select a contact', 'Choose a staff member to message.');
      return;
    }

    setState(() => _submitting = true);
    final med = widget.medication;
    final title =
        'Missed med: ${med.medicationName} — ${med.residentName}'.trim();
    final result = await _repo.startConversation(
      title: title,
      memberUserIds: [selected],
      clientId: med.clientId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    result.when(
      success: (_) {
        Navigator.of(context).pop();
        AppSnackbar.show(
          'Conversation started',
          'You can continue messaging from Communication.',
        );
      },
      failure: (error) {
        AppSnackbar.show('Could not start conversation', error.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.68;
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
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Container(
              width: ResponsiveHelper.getResponsiveWidth(context, 40),
              height: ResponsiveHelper.getResponsiveHeight(context, 4),
              decoration: BoxDecoration(
                color: AppColors.dividerLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                top: 14,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Contact Staff',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          17,
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
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 16,
                bottom: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Missed ${widget.medication.medicationName} for '
                  '${widget.medication.residentName}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w500,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      13,
                    ),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            Expanded(child: _body(context)),
            SafeArea(
              top: false,
              child: Padding(
                padding: ResponsiveHelper.getResponsivePadding(
                  context,
                  horizontal: 16,
                  top: 8,
                  bottom: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting || _loading ? null : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryTeal,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text(
                      _submitting ? 'Starting…' : 'Start conversation',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w600,
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

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.secondaryTeal),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: ResponsiveHelper.getResponsivePadding(context, all: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
              TextButton(
                onPressed: _load,
                child: const Text('Retry', style: TextStyle(fontFamily: 'Outfit')),
              ),
            ],
          ),
        ),
      );
    }
    if (_contacts.isEmpty) {
      return const Center(
        child: Text(
          'No contacts available.',
          style: TextStyle(
            fontFamily: 'Outfit',
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: ResponsiveHelper.getResponsivePadding(
        context,
        horizontal: 8,
        vertical: 4,
      ),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final selected = contact.id == _selectedId;
        return ListTile(
          onTap: () => setState(() => _selectedId = contact.id),
          leading: CircleAvatar(
            backgroundColor: AppColors.secondaryTeal.withValues(alpha: 0.12),
            child: Text(
              contact.name.isEmpty
                  ? '?'
                  : contact.name[0].toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
                color: AppColors.secondaryTeal,
              ),
            ),
          ),
          title: Text(
            contact.name,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            contact.roleLabel,
            style: const TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.secondaryTeal : AppColors.textSecondary,
          ),
        );
      },
    );
  }
}
