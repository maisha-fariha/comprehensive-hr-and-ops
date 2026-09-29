import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimens.dart';
import '../../domain/entities/staff_day_log_entry.dart';

/// Resident day view — chronologic entries for one resident + day.
class StaffResidentDayTabView extends StatelessWidget {
  final bool hasResidence;
  final bool hasResident;
  final String? clientName;
  final String? dateLabel;
  final List<StaffDayLogEntry> entries;
  final VoidCallback? onWriteNote;

  const StaffResidentDayTabView({
    super.key,
    required this.hasResidence,
    required this.hasResident,
    required this.entries,
    this.clientName,
    this.dateLabel,
    this.onWriteNote,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 8),
        ResponsiveHelper.getResponsiveWidth(
          context,
          AppDimens.screenPaddingHorizontal,
        ),
        ResponsiveHelper.getResponsiveHeight(context, 32),
      ),
      children: [
        if (!hasResidence)
          const _EmptyHint(
            title: 'Choose a residence to begin',
            subtitle: 'Daily logs are read one residence at a time.',
          )
        else if (!hasResident)
          const _EmptyHint(
            title: 'Choose a resident',
            subtitle: 'Pick a resident above to open their day log.',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName ?? 'Resident',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontWeight: FontWeight.w700,
                        fontSize:
                            ResponsiveHelper.getResponsiveFontSize(context, 16),
                        color: AppColors.textHeading,
                      ),
                    ),
                    if (dateLabel != null)
                      Text(
                        dateLabel!,
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
              if (onWriteNote != null)
                TextButton(
                  onPressed: onWriteNote,
                  child: const Text('Write note'),
                ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 12)),
          if (entries.isEmpty)
            const _EmptyHint(
              title: 'No entries for this day',
              subtitle: 'Nothing was logged for this resident on the To date.',
            )
          else
            for (final entry in entries) _DayEntryCard(entry: entry),
        ],
      ],
    );
  }
}

class _DayEntryCard extends StatelessWidget {
  final StaffDayLogEntry entry;

  const _DayEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.getResponsiveHeight(context, 10),
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.authorName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                [
                  if (entry.timeLabel.isNotEmpty) entry.timeLabel,
                  if (entry.logType.isNotEmpty) entry.logType,
                ].join(' · '),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize:
                      ResponsiveHelper.getResponsiveFontSize(context, 11),
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.getResponsiveHeight(context, 6)),
          Text(
            entry.body.isEmpty ? '—' : entry.body,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textBody,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyHint({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 13),
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
