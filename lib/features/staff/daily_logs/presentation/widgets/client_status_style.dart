import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_daily_logs_enums.dart';

/// Label/color styling for a [ClientLogStatus], shared by every client
/// row/card across the 3 Daily Logs tabs.
class ClientStatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const ClientStatusStyle({required this.label, required this.background, required this.foreground});
}

const Map<ClientLogStatus, ClientStatusStyle> clientStatusStyles = {
  ClientLogStatus.pending: ClientStatusStyle(
    label: 'Pending',
    background: AppColors.urgentBackground,
    foreground: AppColors.urgentAmber,
  ),
  ClientLogStatus.inProgress: ClientStatusStyle(
    label: 'In Progress',
    background: AppColors.infoBackground,
    foreground: AppColors.infoBlue,
  ),
  ClientLogStatus.submitted: ClientStatusStyle(
    label: 'Submitted',
    background: AppColors.activeBackground,
    foreground: AppColors.activeGreen,
  ),
};
