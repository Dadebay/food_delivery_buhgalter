import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import '../constants/constants.dart';

/// What went wrong, in the terms the spec uses.
///
/// The four documented codes are kept apart because the screen does something
/// different with each: a bad parameter is our bug, an expired session sends
/// the user back to the login, a missing right is permanent for this account,
/// and a missing order is a dead link rather than a failure.
enum ApiFailure { badRequest, unauthorized, forbidden, notFound, conflict, network, server }

class ApiException implements Exception {
  ApiException(this.failure, {this.statusCode, this.serverMessage});

  final ApiFailure failure;
  final int? statusCode;

  /// The server's own wording. On a 409 the spec is explicit that this is
  /// what to show — the client must not invent its own story about what
  /// conflicted.
  final String? serverMessage;

  @override
  String toString() => serverMessage ?? 'API error ${statusCode ?? ''} ($failure)';
}

/// Bearer-authenticated JSON client for the accounting endpoints.
///
/// One access token, refreshed through the same `auth/refresh` the other
/// staff apps use; there is no separate accounting token.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _storage = GetStorage();

  static const _accessKey = 'accessToken';
  static const _refreshKey = 'refreshToken';

  static const Duration timeout = Duration(seconds: 30);

  String? get accessToken => _storage.read<String>(_accessKey);
  String? get refreshToken => _storage.read<String>(_refreshKey);
  bool get hasSession => (accessToken ?? '').isNotEmpty;

  Future<void> saveSession({required String access, String? refresh}) async {
    await _storage.write(_accessKey, access);
    if (refresh != null) await _storage.write(_refreshKey, refresh);
  }

  Future<void> clearSession() async {
    await _storage.remove(_accessKey);
    await _storage.remove(_refreshKey);
  }

  Map<String, String> _headers({bool json = false}) => {
        if (hasSession) 'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
        if (json) 'Content-Type': 'application/json',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final cleaned = <String, String>{};
    query?.forEach((key, value) {
      // A null parameter is one the caller chose not to send — `shiftKey` and
      // `fromDate`/`toDate` are alternatives, never both.
      if (value == null) return;
      cleaned[key] = '$value';
    });
    return Uri.parse('$serverURL/$path').replace(
      queryParameters: cleaned.isEmpty ? null : cleaned,
    );
  }

  /// A GET that refreshes once on a 401 and retries, so a session that
  /// expired mid-session does not throw the accountant back to the login for
  /// no reason.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    var response = await _send(() => _client.get(_uri(path, query), headers: _headers()));
    if (response.statusCode == 401 && await _refreshSession()) {
      response = await _send(() => _client.get(_uri(path, query), headers: _headers()));
    }
    return _decode(response);
  }

  Future<dynamic> patch(String path, {Object? body}) async {
    send() => _client.patch(
          _uri(path),
          headers: _headers(json: true),
          body: body == null ? null : jsonEncode(body),
        );
    var response = await _send(send);
    if (response.statusCode == 401 && await _refreshSession()) {
      response = await _send(send);
    }
    return _decode(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    send() => _client.post(
          _uri(path),
          headers: _headers(json: true),
          body: body == null ? null : jsonEncode(body),
        );
    var response = await _send(send);
    if (response.statusCode == 401 && await _refreshSession()) {
      response = await _send(send);
    }
    return _decode(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeout);
      if (kDebugMode) {
        debugPrint('[API] ${response.statusCode} ${response.request?.url}');
      }
      return response;
    } on TimeoutException {
      throw ApiException(ApiFailure.network);
    } catch (error) {
      if (kDebugMode) debugPrint('[API] transport failure: $error');
      throw ApiException(ApiFailure.network);
    }
  }

  /// Refreshes once. A failure clears the session rather than looping: the
  /// caller's 401 then surfaces and the shell sends the user to the login.
  Future<bool> _refreshSession() async {
    final token = refreshToken;
    if (token == null || token.isEmpty) return false;
    try {
      final response = await _client
          .post(
            _uri('auth/refresh'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'refreshToken': token}),
          )
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearSession();
        return false;
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map) return false;
      final access = data['accessToken'] as String?;
      if (access == null || access.isEmpty) return false;
      await saveSession(access: access, refresh: data['refreshToken'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  dynamic _decode(http.Response response) {
    final code = response.statusCode;
    dynamic body;
    if (response.bodyBytes.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        body = null;
      }
    }
    if (code >= 200 && code < 300) return body;

    throw ApiException(
      switch (code) {
        400 => ApiFailure.badRequest,
        401 => ApiFailure.unauthorized,
        403 => ApiFailure.forbidden,
        404 => ApiFailure.notFound,
        409 => ApiFailure.conflict,
        _ => ApiFailure.server,
      },
      statusCode: code,
      serverMessage: _message(body),
    );
  }

  /// NestJS error bodies carry `message` as a string or a list of strings.
  static String? _message(dynamic body) {
    if (body is! Map) return null;
    final message = body['message'];
    if (message is String) return message;
    if (message is List) return message.whereType<String>().join(', ');
    return null;
  }
}
