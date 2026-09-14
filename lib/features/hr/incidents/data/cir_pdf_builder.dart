import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/entities/incident_investigation_summary.dart';
import 'cir_answer_formatter.dart';

/// Builds an Alberta CFS Critical Incident Report PDF matching the CIR template.
class CirPdfBuilder {
  CirPdfBuilder._();

  static const _navy = PdfColor.fromInt(0xFF1B3A5F);
  static const _labelGray = PdfColor.fromInt(0xFF4A5568);
  static const _rowLine = PdfColor.fromInt(0xFFD0D5DD);
  static const _headerBg = PdfColor.fromInt(0xFFF2F4F7);
  static const _helpBlue = PdfColor.fromInt(0xFF2F567C);

  static const _partyRows = <(String key, String label)>[
    ('child_intervention_practitioner', 'Child Intervention Practitioner'),
    (
      'intake_and_response_team',
      'Child Intervention Intake and Response Team',
    ),
    ('childs_family', "Child's Family"),
    ('childs_legal_guardian', "Child's Legal Guardian"),
    ('agency_director_manager', 'Agency Director/Manager'),
    ('agency_on_call', 'Agency On Call'),
    ('licensing_officer', 'Licensing Officer'),
    ('police_rcmp', 'Police / RCMP'),
    ('medical_services', 'Medical Services'),
    ('therapist_clinician', 'Therapist / Clinician'),
    ('probation', 'Probation'),
    ('other', 'Other'),
  ];

  static Future<Uint8List> build({
    required IncidentInvestigationSummary summary,
    required String generatedForName,
    DateTime? generatedAt,
  }) async {
    final now = (generatedAt ?? DateTime.now()).toUtc();
    final generatedLine =
        'Generated ${_stampUtc(now)} for ${_dash(generatedForName)}';
    final payload = summary.cirPayload;
    final optionsByKey = _optionsByKey(summary.templateSnapshot);

    String v(String key, {String? type}) => CirAnswerFormatter.fromPayload(
          key: key,
          payload: payload,
          type: type,
          options: optionsByKey[key],
        );

    final doc = pw.Document();
    const margin = pw.EdgeInsets.fromLTRB(40, 36, 40, 40);
    final pageFormat = PdfPageFormat.a4.copyWith(
      marginLeft: margin.left,
      marginRight: margin.right,
      marginTop: margin.top,
      marginBottom: margin.bottom,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: margin,
        build: (context) => [
          pw.Text(
            'Critical Incident Report',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _navy,
            ),
          ),
          pw.SizedBox(height: 10),
          _kvTable([
            ('Incident', _dash(summary.title)),
            ('Reported', _dash(summary.reportedAtUtcLabel)),
            ('Severity', _dash(summary.severityLabel)),
            (
              'Status',
              summary.statusRaw.trim().isEmpty
                  ? CirAnswerFormatter.empty
                  : summary.statusRaw.trim(),
            ),
          ]),
          pw.SizedBox(height: 18),
          _section(
            "Section 1: Child or Youth's Information",
            rows: [
              ('Last Name of Child or Youth', v('childLastName')),
              ('First Name', v('childFirstName')),
              ('Date of Birth', v('childDateOfBirth')),
              ("Child's I.D. Number", v('childIdNumber')),
              (
                'Child Intervention Practitioner (CIP)',
                v('childInterventionPractitioner'),
              ),
              ('CIP Office', v('cipOffice')),
              ('CFS Status', v('cfsStatus')),
            ],
          ),
          pw.SizedBox(height: 16),
          _section(
            'Section 2: Facility Information',
            rows: [
              (
                'Name of Agency / Program / Foster Caregivers / Kinship Caregivers',
                v('agencyName'),
              ),
              (
                'License # / Caregiver ID (if applicable)',
                v('licenseNumber'),
              ),
              ('Type of Facility', v('facilityType')),
              (
                'Facility / Caregiver Address (include street address)',
                v('facilityAddress'),
              ),
              ('City or Town', v('facilityCity')),
              ('Province', v('facilityProvince')),
              ('Postal Code', v('facilityPostalCode')),
            ],
          ),
          pw.SizedBox(height: 16),
          _section(
            'Section 3: Incident Background',
            rows: [
              (
                'Last Name of Person Completing Report',
                v('reporterLastName'),
              ),
              ('First Name', v('reporterFirstName')),
              ('Title / Position / Role', v('reporterTitle')),
              ('Date of Incident', v('incidentDate')),
              ('Time of Incident', v('incidentTime')),
              ('End / Return Time', v('endReturnTime')),
              ('Time of Incident Occurrence', v('timeOfOccurrence')),
              (
                'Description of who was involved in the incident including any witness(es)',
                v('personsInvolved'),
              ),
              (
                'Description of Incident Location',
                v('incidentLocationDescription'),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _section(
            'Section 4: Type of Incident',
            subtitle:
                'Identify the type of incident (select as many categories as apply to the incident that has occurred)',
            rows: [
              ('Type of incident', v('incidentTypes')),
              if (v('incidentTypeOther') != CirAnswerFormatter.empty)
                ('Please specify', v('incidentTypeOther')),
            ],
          ),
          pw.SizedBox(height: 16),
          _section(
            'Section 5: Incident Details',
            subtitle:
                'Incidents with use of Intrusive Measures and Restrictive Procedures. Identify the type of response (select as many apply) to the incident.',
            rows: [
              ('Use of Intrusive Measures', v('intrusiveMeasures')),
              ('Use of Restrictive Procedure', v('restrictiveProcedures')),
              ('Preceding Events', v('precedingEvents')),
              ('Contributing Factors', v('contributingFactors')),
              ('Incident Description', v('incidentDescription')),
              ('Mitigation Approaches', v('mitigationApproaches')),
              ('Safety Plan', v('safetyPlan')),
              ('Continuous Improvement', v('continuousImprovement')),
            ],
          ),
          pw.SizedBox(height: 16),
          _section(
            'Section 6: Restrictive Procedures',
            rows: [
              (
                'Was a debrief completed with the child?',
                v('debriefCompleted'),
              ),
              (
                'If yes, provide details of the debrief.',
                v('debriefDetails'),
              ),
              (
                'During the debrief, was the child informed of their rights, available grievance procedures & access to the OCYA?',
                v('childInformedOfRights'),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Section 7: Notification'),
          pw.SizedBox(height: 4),
          pw.Text(
            "Children and Family Services (CFS) must be notified within 24 hours of any incidents. When an incident meets the threshold of a 'serious incident', CFS must be notified immediately.",
            style: const pw.TextStyle(fontSize: 9, color: _helpBlue),
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 2, color: _navy),
          pw.SizedBox(height: 10),
          pw.Text(
            'Parties Notified',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 6),
          _partiesTable(payload),
          pw.SizedBox(height: 8),
          _kvTable([
            (
              'Other, please describe',
              v('partiesNotifiedOtherDescription'),
            ),
          ]),
          pw.SizedBox(height: 16),
          _section(
            'Section 8: Signatures',
            rows: [
              (
                'Name of Program Staff / Foster Caregiver / Kinship Caregiver',
                v('staffSignature', type: 'signature'),
              ),
              (
                'Name of Program Manager/Director (Agency or CFS)',
                v('managerSignature', type: 'signature'),
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            generatedLine,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _section(
    String title, {
    String? subtitle,
    required List<(String, String)> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 9, color: _helpBlue),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.Container(height: 2, color: _navy),
        pw.SizedBox(height: 2),
        _kvTable(rows),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _navy,
      ),
    );
  }

  static pw.Widget _kvTable(List<(String, String)> rows) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1.15),
        1: const pw.FlexColumnWidth(1.35),
      },
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _rowLine, width: 0.6),
        bottom: pw.BorderSide(color: _rowLine, width: 0.6),
      ),
      children: [
        for (final row in rows)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 2,
                ),
                child: pw.Text(
                  row.$1,
                  style: const pw.TextStyle(fontSize: 10, color: _labelGray),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 2,
                ),
                child: pw.Text(
                  row.$2,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static pw.Widget _partiesTable(Map<String, dynamic> payload) {
    final parties = CirAnswerFormatter.partiesTable(payload);
    final bodyRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _headerBg),
        children: [
          _partyHeader('Party'),
          _partyHeader('Notified'),
          _partyHeader('Name of Person Contacted (if applicable)'),
          _partyHeader('Date Notified'),
        ],
      ),
    ];

    for (final party in _partyRows) {
      final answer = parties[party.$1] ?? const <String, dynamic>{};
      final notified = CirAnswerFormatter.display(
        answer['notified'],
        options: const [
          {'value': 'yes', 'label': 'Yes'},
          {'value': 'no', 'label': 'No'},
        ],
      );
      final contact = CirAnswerFormatter.display(answer['contactName']);
      final date = CirAnswerFormatter.display(answer['dateNotified']);
      bodyRows.add(
        pw.TableRow(
          children: [
            _partyCell(party.$2, bold: false),
            _partyCell(notified),
            _partyCell(contact),
            _partyCell(date),
          ],
        ),
      );
    }

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(0.8),
        2: const pw.FlexColumnWidth(1.6),
        3: const pw.FlexColumnWidth(1.1),
      },
      border: pw.TableBorder.all(color: _rowLine, width: 0.6),
      children: bodyRows,
    );
  }

  static pw.Widget _partyHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _partyCell(String text, {bool bold = true}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Map<String, List<dynamic>> _optionsByKey(
    Map<String, dynamic>? snapshot,
  ) {
    final out = <String, List<dynamic>>{
      for (final entry in _fallbackOptions.entries) entry.key: entry.value,
    };
    if (snapshot == null) return out;
    final sections = snapshot['fields'];
    if (sections is! List) return out;
    for (final section in sections) {
      if (section is! Map) continue;
      final fields = section['fields'];
      if (fields is! List) continue;
      for (final field in fields) {
        if (field is! Map) continue;
        final key = field['key']?.toString();
        final options = field['options'];
        if (key == null || key.isEmpty || options is! List) continue;
        out[key] = options;
      }
    }
    return out;
  }

  /// Used when `templateSnapshotJson` is missing or incomplete.
  static const _fallbackOptions = <String, List<Map<String, String>>>{
    'facilityType': [
      {'value': 'foster_care', 'label': 'Foster Care'},
      {
        'value': 'ministry_campus_treatment',
        'label': 'Ministry Campus-based Treatment Centre',
      },
      {'value': 'kinship_care', 'label': 'Kinship Care'},
      {
        'value': 'personalized_community_care',
        'label': 'Personalized Community Care',
      },
      {'value': 'ils_sil_tsil', 'label': 'ILS / SIL / TSIL'},
      {
        'value': 'secure_services_pseca',
        'label': 'Secure Services / PSECA Confinement',
      },
      {'value': 'community_group_care', 'label': 'Community Group Care'},
      {'value': 'pseca_voluntary', 'label': 'PSECA (Voluntary)'},
      {
        'value': 'agency_campus_treatment',
        'label': 'Agency Campus-based Treatment Centre',
      },
      {'value': 'other', 'label': 'Other'},
    ],
    'incidentTypes': [
      {'value': 'accident', 'label': 'Accident'},
      {
        'value': 'allegation_abuse_neglect',
        'label': 'Allegation of Abuse/Neglect',
      },
      {
        'value': 'absent_from_care',
        'label': 'Absent from Care / Unauthorized Absence',
      },
      {
        'value': 'child_criminal_activity',
        'label': 'Child Criminal Activity/Charges/Offences (or potential of)',
      },
      {'value': 'death_of_child', 'label': 'Death of the Child'},
      {'value': 'destruction', 'label': 'Destruction'},
      {'value': 'fire', 'label': 'Fire'},
      {'value': 'infectious_disease', 'label': 'Infectious Disease'},
      {'value': 'injury_to_child', 'label': 'Injury to Child'},
      {
        'value': 'medication_error',
        'label': 'Medication Error / Medication Concern',
      },
      {
        'value': 'medical_attention_required',
        'label': 'Medical Attention Required',
      },
      {'value': 'placement_disruption', 'label': 'Placement Disruption'},
      {'value': 'self_harm', 'label': 'Self-harm / Self-injury'},
      {
        'value': 'sexually_problematic_behaviours',
        'label': 'Sexually Problematic Behaviours',
      },
      {
        'value': 'suicide_attempt_ideation',
        'label': 'Suicide Attempt / Suicidal Ideation',
      },
      {'value': 'substance_use', 'label': 'Substance Use/Abuse'},
      {
        'value': 'criminal_activity_child_witness',
        'label': 'Criminal Activity (child witness)',
      },
      {
        'value': 'staff_criminal_activity',
        'label':
            'Staff/Caregiver Criminal Activity/Charges/Offences (or potential of)',
      },
      {'value': 'weapons', 'label': 'Weapons'},
      {'value': 'violence_aggression', 'label': 'Violence / Aggression'},
      {'value': 'victimization', 'label': 'Victimization'},
      {'value': 'injury_to_staff', 'label': 'Injury to Staff/Caregiver'},
      {
        'value': 'other',
        'label':
            "'Other' occurrence that may seriously affect the health or safety of the child",
      },
    ],
    'intrusiveMeasures': [
      {
        'value': 'monitoring_private_communication',
        'label':
            'Use of monitoring and/or restricting private communication',
      },
      {'value': 'surveillance', 'label': 'Surveillance'},
      {'value': 'room_search', 'label': 'Room search'},
      {'value': 'personal_search', 'label': 'Personal search'},
      {'value': 'voluntary_surrender', 'label': 'Voluntary surrender'},
      {
        'value': 'restricting_personal_property',
        'label':
            'Restricting access to or confiscating personal property',
      },
    ],
    'restrictiveProcedures': [
      {
        'value': 'physical_restraint',
        'label':
            'Physical restraint (physical escort, seated, supine, standing, and/or floor restraint)',
      },
      {
        'value': 'isolation_room',
        'label': 'Isolation room (locked confinement)',
      },
      {'value': 'inclusionary_time_out', 'label': 'Inclusionary time out'},
      {'value': 'exclusionary_time_out', 'label': 'Exclusionary time out'},
      {
        'value': 'prohibited_practice',
        'label': 'Use of a Prohibited Practice(s)',
      },
    ],
    'debriefCompleted': [
      {'value': 'yes', 'label': 'Yes'},
      {'value': 'no', 'label': 'No'},
    ],
    'childInformedOfRights': [
      {'value': 'yes', 'label': 'Yes'},
      {'value': 'no', 'label': 'No'},
    ],
    'cfsStatus': [
      {'value': 'cag', 'label': 'CAG'},
      {'value': 'cay', 'label': 'CAY'},
      {'value': 'ico', 'label': 'ICO'},
      {'value': 'tgo', 'label': 'TGO'},
      {'value': 'pgo', 'label': 'PGO'},
      {'value': 'sfp', 'label': 'SFP'},
    ],
  };

  static String _stampUtc(DateTime utc) {
    final y = utc.year.toString().padLeft(4, '0');
    final m = utc.month.toString().padLeft(2, '0');
    final d = utc.day.toString().padLeft(2, '0');
    final hh = utc.hour.toString().padLeft(2, '0');
    final mm = utc.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm UTC';
  }

  static String _dash(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty || trimmed == '—') return CirAnswerFormatter.empty;
    return trimmed;
  }
}
