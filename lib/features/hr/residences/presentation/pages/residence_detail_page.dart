import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/roles/user_session.dart';
import '../../../clients/presentation/pages/clients_page.dart';
import '../../../presentation/widgets/hr_directory_widgets.dart';
import '../../domain/entities/residence_summary.dart';
import '../controllers/residences_controller.dart';
import '../widgets/residence_card.dart';

class ResidenceDetailPage extends StatefulWidget {
  final ResidenceSummary residence;

  const ResidenceDetailPage({super.key, required this.residence});

  @override
  State<ResidenceDetailPage> createState() => _ResidenceDetailPageState();
}

class _ResidenceDetailPageState extends State<ResidenceDetailPage> {
  late Future<List<ResidenceRoom>?> _rooms;

  ResidencesController get _controller {
    try {
      return Get.find<ResidencesController>();
    } catch (_) {
      return Get.put(GetIt.instance<ResidencesController>());
    }
  }

  @override
  void initState() {
    super.initState();
    _rooms = _controller.loadRooms(widget.residence.id);
  }

  bool get _canSeeClients {
    try {
      return Get.find<UserSession>().canAccessClients;
    } catch (_) {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.residence;
    final gap = ResponsiveHelper.getResponsiveHeight(context, 12);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: hrSubPageAppBar(context, r.name),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: ResponsiveHelper.getResponsivePadding(
            context,
            horizontal: AppDimens.screenPaddingHorizontal,
            vertical: 16,
          ),
          children: [
            ResidenceCard(residence: r),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Details',
              child: Column(
                children: [
                  HrInfoRow(label: 'Type', value: hrHumanize(r.residenceType)),
                  HrInfoRow(label: 'Status', value: r.statusLabel),
                  HrInfoRow(
                    label: 'Capacity',
                    value: '${r.residents}/${r.bedCapacity} beds · '
                        '${r.bedsFree} free',
                  ),
                  HrInfoRow(label: 'Phone', value: r.phone ?? '—'),
                  HrInfoRow(label: 'Email', value: r.email ?? '—'),
                  HrInfoRow(label: 'Timezone', value: r.timezone ?? '—'),
                  HrInfoRow(
                    label: 'GPS radius',
                    value: r.gpsRadiusMeters == null
                        ? '—'
                        : '${r.gpsRadiusMeters} m',
                  ),
                  if (r.latitude != null && r.longitude != null)
                    HrInfoRow(
                      label: 'Coordinates',
                      value: '${r.latitude!.toStringAsFixed(5)}, '
                          '${r.longitude!.toStringAsFixed(5)}',
                    ),
                  if (r.notes != null) HrInfoRow(label: 'Notes', value: r.notes!),
                ],
              ),
            ),
            SizedBox(height: gap),
            HrSectionCard(
              title: 'Rooms',
              child: FutureBuilder<List<ResidenceRoom>?>(
                future: _rooms,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.secondaryTeal,
                        ),
                      ),
                    );
                  }
                  final rooms = snapshot.data;
                  if (rooms == null) {
                    return _muted(context, 'Rooms could not be loaded.');
                  }
                  if (rooms.isEmpty) {
                    return _muted(context, 'No rooms set up for this home.');
                  }
                  return Column(
                    children: [
                      for (final room in rooms) _RoomRow(room: room),
                    ],
                  );
                },
              ),
            ),
            if (_canSeeClients) ...[
              SizedBox(height: gap),
              SizedBox(
                height: ResponsiveHelper.getResponsiveHeight(context, 48),
                child: OutlinedButton.icon(
                  onPressed: () => Get.to(
                    () => ClientsPage(initialResidenceId: r.id),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondaryTeal,
                    side: const BorderSide(color: AppColors.secondaryTeal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.people_outline_rounded),
                  label: const Text('View clients in this home'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _muted(BuildContext context, String text) => Text(
        text,
        style: AppTextStyles.base(
          fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
          fontWeight: AppFontWeight.regular,
          color: AppColors.textMuted,
        ),
      );
}

class _RoomRow extends StatelessWidget {
  final ResidenceRoom room;

  const _RoomRow({required this.room});

  @override
  Widget build(BuildContext context) {
    final location = [room.floor, room.wing, hrHumanize(room.roomType)]
        .whereType<String>()
        .where((s) => s != '—')
        .join(' · ');
    final full = room.available == 0;
    return Padding(
      padding: ResponsiveHelper.getResponsivePadding(context, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveHelper.getResponsiveSize(context, 36),
            height: ResponsiveHelper.getResponsiveSize(context, 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              room.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.base(
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                fontWeight: AppFontWeight.bold,
                color: AppColors.infoBlue,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.isEmpty ? 'Room ${room.name}' : location,
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
                    fontWeight: AppFontWeight.semiBold,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  room.residentNames.isEmpty
                      ? 'Vacant'
                      : room.residentNames.join(', '),
                  style: AppTextStyles.base(
                    fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
                    fontWeight: AppFontWeight.regular,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${room.occupied}/${room.capacity}',
            style: AppTextStyles.base(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              fontWeight: AppFontWeight.semiBold,
              color: full ? AppColors.urgentAmber : AppColors.activeGreen,
            ),
          ),
        ],
      ),
    );
  }
}
