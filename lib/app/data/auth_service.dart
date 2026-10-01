import 'package:get_storage/get_storage.dart';

import 'api_client.dart';

/// Who is allowed into this app.
///
/// The new journal is open to active `ACCOUNTANT` and `SUPER_ADMIN` only.
/// Handing the `ACCOUNTING` page to some other role does not by itself open
/// it — the server enforces that, and this app refuses the same set so a
/// wrong account is told why at the login instead of at every request.
enum StaffRole { accountant, superAdmin, other }

extension StaffRoleAccess on StaffRole {
  bool get canViewAccounting =>
      this == StaffRole.accountant || this == StaffRole.superAdmin;

  /// Creating a money packet is an owner/administrator action. The
  /// accountant confirms an existing one and never sees the create button.
  bool get canCreateHandoff => this == StaffRole.superAdmin;

  /// Editing the shift schedule is the owner's alone.
  bool get canEditSettings => this == StaffRole.superAdmin;

  /// Marking an order's cash as returned is normally the courier's own
  /// action; the API also allows an administrator override, which here means
  /// the owner only — the accountant stays view-only on orders.
  bool get canReturnCash => this == StaffRole.superAdmin;
}

StaffRole roleFromApi(String? value) => switch ((value ?? '').toUpperCase()) {
      'ACCOUNTANT' => StaffRole.accountant,
      'SUPER_ADMIN' => StaffRole.superAdmin,
      _ => StaffRole.other,
    };

/// The phone + OTP sign-in the other staff apps use. There is no separate
/// accounting token; this is the app's ordinary session.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  final _storage = GetStorage();

  static const _roleKey = 'role';
  static const _nameKey = 'displayName';
  static const _phoneKey = 'phone';

  bool get isSignedIn => _api.hasSession && role.canViewAccounting;

  StaffRole get role => roleFromApi(_storage.read<String>(_roleKey));
  String? get displayName => _storage.read<String>(_nameKey);
  String? get phone => _storage.read<String>(_phoneKey);

  Future<void> requestCode(String phone) =>
      _api.post('auth/otp/request', body: {'phone': phone});

  /// Signs in, or throws [WrongRoleException] when the account is real but
  /// has no business in this app. The two are worth telling apart: a wrong
  /// code is a typo, a wrong role is a conversation with the owner.
  Future<StaffRole> verifyCode(String phone, String code) async {
    final payload =
        await _api.post('auth/otp/verify', body: {'phone': phone, 'code': code});
    if (payload is! Map<String, dynamic>) {
      throw ApiException(ApiFailure.server);
    }
    final user = payload['user'] as Map<String, dynamic>?;
    final role = roleFromApi(user?['role'] as String?);
    if (!role.canViewAccounting) throw const WrongRoleException();

    final access = payload['accessToken'] as String?;
    if (access == null || access.isEmpty) throw ApiException(ApiFailure.server);

    await _api.saveSession(
      access: access,
      refresh: payload['refreshToken'] as String?,
    );
    await _storage.write(_roleKey, (user?['role'] as String?) ?? '');
    await _storage.write(_phoneKey, phone);
    final name = [user?['firstName'], user?['lastName']]
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .join(' ');
    await _storage.write(_nameKey, name);
    return role;
  }

  Future<void> signOut() async {
    try {
      await _api.post('auth/logout');
    } catch (_) {
      // Losing the round trip does not keep the accountant signed in on this
      // phone; the local session goes either way.
    }
    await _api.clearSession();
    await _storage.remove(_roleKey);
    await _storage.remove(_nameKey);
  }
}

class WrongRoleException implements Exception {
  const WrongRoleException();
}
