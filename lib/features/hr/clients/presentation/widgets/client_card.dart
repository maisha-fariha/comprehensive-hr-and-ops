import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../../../../core/constants/app_text_styles.dart';
import '../../../../../core/widgets/surface_card.dart';
import '../../../profile_settings/presentation/widgets/hr_initials_avatar.dart';
import '../../domain/entities/client_summary.dart';
import '../clients_labels.dart';
import 'clients_common.dart';

enum ClientRowAction { view, edit, move, delete }

/// One row of the web client table: name and ID, residence and room, care
/// level, DOB, status, and the row actions menu.
class ClientCard extends StatelessWidget {
  final ClientSummary client;
  final String? residenceName;
  final VoidCallback? onTap;
  final bool canUpdate;
  final bool canDelete;
  final ValueChanged<ClientRowAction>? onAction;

  const ClientCard({
    super.key,
    required this.client,
    this.residenceName,
    this.onTap,
    this.canUpdate = false,
    this.canDelete = false,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = client;
    final muted = AppTextStyles.base(
      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12),
      fontWeight: AppFontWeight.regular,
      color: AppColors.textSecondary,
    );
    final avatar = ClientsLabels.avatarColor(c.id);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SurfaceCard.card(
        padding: ResponsiveHelper.getResponsivePadding(
          context,
          horizontal: AppDimens.cardPaddingHorizontal,
          vertical: 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HrInitialsAvatar(
              initials: c.initials,
              imageUrl: c.photoUrl,
              size: 44,
              background: avatar,
              foreground: AppColors.surfaceWhite,
            ),
            SizedBox(width: ResponsiveHelper.getResponsiveWidth(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14.5),
                      fontWeight: AppFontWeight.semiBold,
                      color: AppColors.textHeading,
                    ),
                  ),
                  Text(
                    'ID: #${c.shortId}',
                    style: AppTextStyles.base(
                      fontSize: ResponsiveHelper.getResponsiveFontSize(context, 11.5),
                      fontWeight: AppFontWeight.regular,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 4)),
                  Text(
                    [
                      residenceName ?? c.residenceName ?? '—',
                      c.room != null && c.room!.toLowerCase().startsWith('room')
                          ? c.room!
                          : 'Room ${c.room ?? '—'}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 8)),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (c.careLevel != null && c.careLevel!.isNotEmpty)
                        ClientPill(label: c.careLevel!, tone: ClientTone.info)
                      else
                        Text('—', style: muted),
                      ClientPill(
                        label: ClientsLabels.humanise(c.status),
                        tone: ClientToneColors.forStatus(c.status),
                      ),
                      Text('DOB ${ClientsLabels.date(c.dateOfBirth)}', style: muted),
                    ],
                  ),
                ],
              ),
            ),
            if (onAction != null)
              PopupMenuButton<ClientRowAction>(
                key: ValueKey('client-actions-${c.id}'),
                tooltip: 'Actions',
                icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
                color: AppColors.surfaceWhite,
                onSelected: onAction,
                itemBuilder: (_) => [
                  _item(ClientRowAction.view, 'View', Icons.visibility_outlined),
                  if (canUpdate) ...[
                    _item(ClientRowAction.edit, 'Edit', Icons.edit_outlined),
                    _item(ClientRowAction.move, 'Move to another home', Icons.swap_horiz_rounded),
                  ],
                  if (canDelete)
                    _item(
                      ClientRowAction.delete,
                      'Delete',
                      Icons.delete_outline_rounded,
                      color: AppColors.criticalRed,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<ClientRowAction> _item(
    ClientRowAction action,
    String label,
    IconData icon, {
    Color color = AppColors.textHeading,
  }) =>
      PopupMenuItem(
        value: action,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );
}
