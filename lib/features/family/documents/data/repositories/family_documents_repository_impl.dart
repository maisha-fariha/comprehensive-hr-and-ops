import 'package:gems_core/gems_core.dart';

import '../../domain/entities/family_document.dart';
import '../../domain/entities/family_document_enums.dart';
import '../../domain/entities/family_documents_overview.dart';
import '../../domain/repositories/family_documents_repository.dart';

/// Local implementation of [FamilyDocumentsRepository].
///
/// There is no backend endpoint for shared documents yet, so this returns
/// the exact static content shown in the reference screenshot. Replace the
/// body of [getOverview] with a real `ApiService`/`BaseRepository` call once
/// an API contract exists — the domain layer and every widget above it will
/// keep working unchanged.
class FamilyDocumentsRepositoryImpl implements FamilyDocumentsRepository {
  @override
  Future<Result<FamilyDocumentsOverview>> getOverview() async {
    return Result.success(
      const FamilyDocumentsOverview(
        captionText: 'Only approved documents are shared.',
        documents: [
          FamilyDocument(
            id: 'care-plan-summary',
            title: 'Care Plan Summary',
            dateLabel: 'Updated May 10, 2025',
            fileType: FamilyDocumentFileType.pdf,
          ),
          FamilyDocument(
            id: 'recent-appointment-summary',
            title: 'Recent Appointment Summary',
            dateLabel: 'Updated May 9, 2025',
            fileType: FamilyDocumentFileType.pdf,
          ),
          FamilyDocument(
            id: 'visit-policy-guidelines',
            title: 'Visit Policy & Guidelines',
            dateLabel: 'Updated Apr 15, 2025',
            fileType: FamilyDocumentFileType.pdf,
          ),
          FamilyDocument(
            id: 'emergency-contacts',
            title: 'Emergency Contacts',
            dateLabel: 'Updated Apr 10, 2025',
            fileType: FamilyDocumentFileType.pdf,
          ),
          FamilyDocument(
            id: 'activities-calendar',
            title: 'Activities Calendar',
            dateLabel: 'May 2025',
            fileType: FamilyDocumentFileType.pdf,
          ),
          FamilyDocument(
            id: 'birthday-celebration-flyer',
            title: 'Birthday Celebration Flyer',
            dateLabel: 'May 2025',
            fileType: FamilyDocumentFileType.jpg,
          ),
        ],
      ),
    );
  }
}
