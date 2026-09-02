import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/network/tenant_store.dart';
import '../../../../core/roles/user_session.dart';
import '../../../../core/routing/app_routes.dart';
import '../../domain/entities/mobile_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final AuthRepository repository;

  AuthController({required this.repository});

  final RxBool isBusy = false.obs;
  final RxString errorMessage = ''.obs;

  String get savedWorkspaceCode =>
      GetIt.instance<TenantStore>().subdomain ?? '';

  Future<bool> signInWithPassword({
    required String workspaceCode,
    required String email,
    required String password,
  }) async {
    return _run(() async {
      if (email.trim().isEmpty || password.isEmpty) {
        errorMessage.value = 'Enter your email and password.';
        return false;
      }
      final tenant = await repository.lookupTenant(workspaceCode);
      if (tenant.isFailure) {
        errorMessage.value = tenant.error?.message ?? 'Workspace not found.';
        return false;
      }
      final result = await repository.login(email: email, password: password);
      return _completeSignIn(result.value, result.error?.message);
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _run(() async {
      if (email.trim().isEmpty) {
        errorMessage.value = 'Enter the email on your account.';
        return false;
      }
      if (!await _ensureTenant()) return false;
      final result = await repository.requestPasswordReset(email);
      if (result.isFailure) {
        errorMessage.value = result.error?.message ?? 'Could not send reset code.';
        return false;
      }
      return true;
    });
  }

  Future<bool> resendOtp(String email) async {
    return _run(() async {
      if (!await _ensureTenant()) return false;
      final result = await repository.requestOtp(email);
      if (result.isFailure) {
        errorMessage.value = result.error?.message ?? 'Could not resend the code.';
        return false;
      }
      return true;
    });
  }

  Future<bool> verifyOtpLogin({
    required String email,
    required String code,
  }) async {
    return _run(() async {
      if (code.length < 6) {
        errorMessage.value = 'Enter the 6-digit code.';
        return false;
      }
      if (!await _ensureTenant()) return false;
      final result = await repository.verifyOtp(email: email, code: code);
      return _completeSignIn(result.value, result.error?.message);
    });
  }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return _run(() async {
      if (code.length < 6) {
        errorMessage.value = 'Enter the 6-digit code.';
        return false;
      }
      if (newPassword.length < 8) {
        errorMessage.value = 'Use a new password with at least 8 characters.';
        return false;
      }
      if (!await _ensureTenant()) return false;
      final result = await repository.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (result.isFailure) {
        errorMessage.value =
            result.error?.message ?? 'Could not reset the password.';
        return false;
      }
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Password updated',
        'Sign in with your new password.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
      );
      return true;
    });
  }

  Future<bool> _ensureTenant() async {
    final code = savedWorkspaceCode;
    if (code.isEmpty) {
      errorMessage.value =
          'Enter your workspace code on the sign-in screen first.';
      return false;
    }
    final tenant = await repository.lookupTenant(code);
    if (tenant.isFailure) {
      errorMessage.value = tenant.error?.message ?? 'Workspace not found.';
      return false;
    }
    return true;
  }

  Future<bool> _completeSignIn(MobileProfile? profile, String? error) async {
    if (profile == null) {
      errorMessage.value = error ?? 'Sign-in failed.';
      return false;
    }
    Get.find<UserSession>().applyProfile(profile);
    Get.offAllNamed(profile.role.portalRoute);
    return true;
  }

  Future<bool> _run(Future<bool> Function() action) async {
    if (isBusy.value) return false;
    isBusy.value = true;
    errorMessage.value = '';
    try {
      return await action();
    } finally {
      isBusy.value = false;
    }
  }
}
