import 'dart:io';

import 'package:accounting_app/app/data/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory storageDirectory;
  setUpAll(() async => storageDirectory = await initTestStorage());
  tearDownAll(() => disposeTestStorage(storageDirectory));

  test('a rate-limited token refresh keeps the local session', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/refresh')) {
        return http.Response('{"message":"Try again later"}', 429);
      }
      return http.Response('{}', 401);
    });
    final api = ApiClient(client: client);
    await api.saveSession(access: 'old-access', refresh: 'valid-refresh');

    await expectLater(
      api.get('accounting/report'),
      throwsA(isA<ApiException>().having(
        (error) => error.failure,
        'failure',
        ApiFailure.rateLimited,
      )),
    );
    expect(api.accessToken, 'old-access');
    expect(api.refreshToken, 'valid-refresh');
    client.close();
  });

  test('a rejected refresh credential clears the local session', () async {
    final client = MockClient((request) async => http.Response('{}', 401));
    final api = ApiClient(client: client);
    await api.saveSession(access: 'expired-access', refresh: 'invalid-refresh');

    await expectLater(
      api.get('accounting/report'),
      throwsA(isA<ApiException>().having(
        (error) => error.failure,
        'failure',
        ApiFailure.unauthorized,
      )),
    );
    expect(api.hasSession, isFalse);
    expect(api.refreshToken, isNull);
    client.close();
  });
}
