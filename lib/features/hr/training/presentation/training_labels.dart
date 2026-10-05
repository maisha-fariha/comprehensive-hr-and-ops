/// Option lists, tab ids and formatting from the web training constants.
abstract final class TrainingLabels {
  static const List<(String, String)> tabs = [
    ('overview', 'Overview'),
    ('content', 'Content'),
    ('quiz', 'Quiz'),
    ('assignments', 'Assignments'),
    ('sittings', 'Sittings'),
    ('completions', 'Completions'),
    ('certificates', 'Certificates'),
    ('history', 'History'),
  ];

  static const List<String> categories = [
    'Compliance',
    'Medication MAR',
    'Safeguarding',
    'Health & Safety',
    'Clinical',
  ];

  static const List<String> types = ['Course', 'Document', 'Video'];

  static const List<(String, String)> expiryPeriods = [
    ('No Expiry', 'Never expires'),
    ('1 Year', 'Annual renewal'),
    ('2 Years', 'Biennial renewal'),
    ('Custom', 'Set your own'),
  ];

  static const List<String> durationUnits = ['Months', 'Years'];

  static const List<(String, String)> assignTo = [
    ('All Staff', 'Everyone across all residences'),
    ('Specific Roles', 'RN, Support, Med Aide'),
    ('Specific Residence', 'One or more locations'),
    ('Individual Staff', 'Hand-pick people'),
  ];

  static const List<String> formQuestionTypes = ['Multiple Choice', 'True / False'];

  /// The quiz tab's own question types (`PUT /questions` values).
  static const List<(String, String)> quizQuestionTypes = [
    ('single_choice', 'One correct answer'),
    ('multi_choice', 'Several correct answers'),
    ('true_false', 'True or false'),
  ];

  static const List<(String, String)> certificateFilter = [
    ('all', 'All Certificate'),
    ('issued', 'Certificate Issued'),
    ('none', 'No Certificate'),
  ];

  static const List<(String, String, String)> wizardSteps = [
    ('trainingInformation', 'Training Information', 'Basic details'),
    ('contentUpload', 'Content Upload', 'Materials added'),
    ('quizSetup', 'Quiz Setup', 'Assessment built'),
    ('assignmentRules', 'Assignment Rules', 'Staff assigned'),
    ('reviewPublish', 'Review & Publish', 'Ready to launch'),
  ];

  static const Map<String, String> wizardTips = {
    'trainingInformation':
        'Nothing is saved until the last step — there is no draft to come back to.',
    'contentUpload':
        'One material per course: upload a file, or link to where it already lives.',
    'quizSetup':
        'Clearing the quiz removes the pass mark, and sittings then refuse with NO_QUIZ.',
    'assignmentRules':
        'Estimated reach is counted from the staff directory — it is how many assignments this will create.',
    'reviewPublish':
        'Publishing writes the course, its questions and one assignment per person named.',
  };

  static const List<String> afterPublishing = [
    'Each person named gets an assignment, with its due date',
    'Their progress is read from those assignments, not entered by hand',
    'A quiz pass is scored against the questions saved here',
    'A pass issues a certificate; a course marked \u201cneeds a certificate\u201d waits for one to be approved',
    'Compliance counts anybody still unfinished as incomplete training',
  ];

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// Web `formatDate` (tenant default `DD/MM/YYYY`).
  static String date(DateTime? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final l = value.toLocal();
    return '${_two(l.day)}/${_two(l.month)}/${l.year}';
  }

  /// Web `formatDateTime` (`DD/MM/YYYY HH:mm`).
  static String dateTime(DateTime? value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final l = value.toLocal();
    return '${date(l)} ${_two(l.hour)}:${_two(l.minute)}';
  }

  /// A `type="date"` value sent through `new Date(v).toISOString()` is UTC midnight.
  static String dateOnlyIso(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day).toIso8601String();
}
