import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/auth_storage.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('stores, reads, and clears an auth token', () async {
    final storage = AuthStorage();

    expect(await storage.readToken(), isNull);

    await storage.saveToken('jwt-test-token');
    expect(await storage.readToken(), 'jwt-test-token');

    await storage.clearToken();
    expect(await storage.readToken(), isNull);
  });
}
