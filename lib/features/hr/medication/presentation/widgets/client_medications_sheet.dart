import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';
import 'package:get_it/get_it.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/errors/app_snackbar.dart';
import '../../domain/entities/client_medication_item.dart';
import '../../domain/entities/schedule_dose.dart';
import '../../domain/repositories/medication_repository.dart';

/// Opens client medication + PRN lists
/// (`GET /medications?clientId=` + `GET /prn-medications?clientId=`).
Future<void> showClientMedicationsSheet(
  BuildContext context, {
  required ScheduleDose dose,
}) {
  final clientId = dose.clientId?.trim();
  if (clientId == null || clientId.isEmpty) {
    AppSnackbar.show(
      'Client unavailable',
      'This dose does not include a client id for the medication list.',
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ClientMedicationsSheet(
      clientId: clientId,
      clientName: dose.residentName,
    ),
  );
}

class _ClientMedicationsSheet extends StatefulWidget {
  final String clientId;
  final String clientName;

  const _ClientMedicationsSheet({
    required this.clientId,
    required this.clientName,
  });

  @override
  State<_ClientMedicationsSheet> createState() =>
      _ClientMedicationsSheetState();
}

class _ClientMedicationsSheetState extends State<_ClientMedicationsSheet> {
  late final ClientMedicationsLoad _load;

  @override
  void initState() {
    super.initState();
    _load = ClientMedicationsLoad(GetIt.instance<MedicationRepository>());
    _load.fetch(widget.clientId);
  }

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
            SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 10)),
            Container(
              width: ResponsiveHelper.getResponsiveWidth(context, 40),
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.searchBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 20,
                top: 16,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medications',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w700,
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              18,
                            ),
                            color: AppColors.textHeading,
                          ),
                        ),
                        Text(
                          widget.clientName,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context,
                              13,
                            ),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _load,
                builder: (context, _) {
                  if (_load.loading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondaryTeal,
                      ),
                    );
                  }
                  if (_load.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _load.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _load.fetch(widget.clientId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: ResponsiveHelper.getResponsivePadding(
                      context,
                      horizontal: 20,
                      bottom: 24,
                    ),
                    children: [
                      _Section(
                        title: 'Prescribed',
                        items: _load.prescribed,
                      ),
                      SizedBox(
                        height: ResponsiveHelper.getResponsiveHeight(context, 16),
                      ),
                      _Section(
                        title: 'PRN',
                        items: _load.prn,
                      ),
                    ],
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

class ClientMedicationsLoad extends ChangeNotifier {
  final MedicationRepository repository;
  bool loading = true;
  String? error;
  List<ClientMedicationItem> prescribed = const [];
  List<ClientMedicationItem> prn = const [];

  ClientMedicationsLoad(this.repository);

  Future<void> fetch(String clientId) async {
    loading = true;
    error = null;
    notifyListeners();

    final results = await Future.wait([
      repository.getClientMedications(clientId),
      repository.getClientPrnMedications(clientId),
    ]);

    final meds = results[0];
    final prns = results[1];
    if (meds.isFailure && prns.isFailure) {
      error = meds.error?.message ??
          prns.error?.message ??
          'Could not load medications.';
      loading = false;
      notifyListeners();
      return;
    }

    prescribed = meds.isSuccess ? meds.value! : const [];
    prn = prns.isSuccess ? prns.value! : const [];
    loading = false;
    notifyListeners();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ClientMedicationItem> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w700,
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
            color: AppColors.textHeading,
          ),
        ),
        SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
        if (items.isEmpty)
          Text(
            'No medications listed.',
            style: TextStyle(
              fontFamily: 'Outfit',
              color: AppColors.textMuted,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
            ),
          )
        else
          for (final item in items) ...[
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(
                bottom: ResponsiveHelper.getResponsiveHeight(context, 8),
              ),
              padding: ResponsiveHelper.getResponsivePadding(
                context,
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.searchBorder),
                borderRadius: BorderRadius.circular(
                  ResponsiveHelper.getResponsiveRadius(context, 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                      fontSize:
                          ResponsiveHelper.getResponsiveFontSize(context, 14),
                      color: AppColors.textHeading,
                    ),
                  ),
                  if (item.dose.isNotEmpty)
                    Text(
                      item.dose,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12.5,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (item.scheduleLabel != null &&
                      item.scheduleLabel!.isNotEmpty)
                    Text(
                      item.scheduleLabel!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                  if (item.instructions != null &&
                      item.instructions!.isNotEmpty)
                    Text(
                      item.instructions!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: ResponsiveHelper.getResponsiveFontSize(
                          context,
                          12,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
