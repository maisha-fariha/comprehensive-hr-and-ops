import 'package:flutter/material.dart';
import 'package:gems_responsive/gems_responsive.dart';

import '../../../../../../core/constants/app_colors.dart';
import '../../domain/entities/staff_document.dart';

class StaffDocumentsRegistry extends StatelessWidget {
  final List<StaffDocument> documents;
  final int totalCount;
  final bool canWrite;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function(StaffDocument doc) onWithdraw;
  final Future<void> Function(StaffDocument doc) onRestore;

  const StaffDocumentsRegistry({
    super.key,
    required this.documents,
    required this.totalCount,
    required this.canWrite,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.onWithdraw,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Document Registry',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w700,
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalCount document${totalCount == 1 ? '' : 's'} matching these filters.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 12.5),
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          if (documents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'No documents match these filters.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  color: AppColors.textMuted,
                ),
              ),
            )
          else
            for (final doc in documents) ...[
              _DocumentCard(
                doc: doc,
                canWrite: canWrite,
                onWithdraw: () => onWithdraw(doc),
                onRestore: () => onRestore(doc),
              ),
              const SizedBox(height: 10),
            ],
          if (totalPages > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                  child: const Text('Prev'),
                ),
                Text(
                  '$page / $totalPages',
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
                TextButton(
                  onPressed:
                      page < totalPages ? () => onPageChanged(page + 1) : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final StaffDocument doc;
  final bool canWrite;
  final VoidCallback onWithdraw;
  final VoidCallback onRestore;

  const _DocumentCard({
    required this.doc,
    required this.canWrite,
    required this.onWithdraw,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.infoBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  doc.name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              if (canWrite)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'withdraw':
                        onWithdraw();
                      case 'restore':
                        onRestore();
                    }
                  },
                  itemBuilder: (_) => [
                    if (!doc.isWithdrawn)
                      const PopupMenuItem(
                        value: 'withdraw',
                        child: Text('Withdraw'),
                      ),
                    if (doc.isWithdrawn)
                      const PopupMenuItem(
                        value: 'restore',
                        child: Text('Restore'),
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Pill(label: doc.ownerTypeLabel, color: AppColors.infoBlue),
              _Meta(label: 'Owner', value: doc.ownerName),
              _Meta(label: 'Category', value: doc.categoryLabel),
              _Meta(label: 'Expiry', value: doc.expiryLabel),
              _Meta(label: 'Visibility', value: doc.visibilityLabel),
              _Meta(label: 'Uploaded', value: doc.uploadedLabel),
              if (doc.isWithdrawn)
                const _Pill(label: 'Withdrawn', color: AppColors.criticalRed),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: color,
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final String label;
  final String value;

  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5,
              color: AppColors.textMuted,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}
