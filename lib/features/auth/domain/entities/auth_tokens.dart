class AuthTokens {
  final String accessToken;
  final String? refreshToken;

  /// When the access token stops being valid. Parsed from `expiresIn`
  /// (seconds) or the JWT `exp` claim.
  final DateTime? accessExpiresAt;

  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.accessExpiresAt,
  });
}
