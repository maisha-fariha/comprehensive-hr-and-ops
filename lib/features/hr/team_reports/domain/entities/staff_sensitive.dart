import 'package:flutter/foundation.dart';

/// `GET /staff/{id}/sensitive` — SIN and banking, masked unless revealed.
@immutable
class StaffSensitive {
  final bool revealed;
  final bool sinOnFile;
  final String? sinMasked;
  final String? sinValue;
  final bool bankingOnFile;
  final String? accountMasked;
  final String? institutionNumber;
  final String? transitNumber;
  final String? accountNumber;

  const StaffSensitive({
    this.revealed = false,
    this.sinOnFile = false,
    this.sinMasked,
    this.sinValue,
    this.bankingOnFile = false,
    this.accountMasked,
    this.institutionNumber,
    this.transitNumber,
    this.accountNumber,
  });

  bool get anyOnFile => sinOnFile || bankingOnFile;

  String get sinLabel {
    final value = sinValue;
    if (value != null) {
      final match = RegExp(r'^(\d{3})(\d{3})(\d{3})$').firstMatch(value);
      return match == null
          ? value
          : '${match[1]} ${match[2]} ${match[3]}';
    }
    return sinMasked ?? 'Not on file';
  }

  String get institutionLabel =>
      institutionNumber ?? (bankingOnFile ? '•••' : 'Not on file');

  String get transitLabel =>
      transitNumber ?? (bankingOnFile ? '•••••' : 'Not on file');

  String get accountLabel => accountNumber ?? accountMasked ?? 'Not on file';
}
