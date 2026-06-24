import 'package:shared_preferences/shared_preferences.dart';

/// Configura SharedPreferences para usar implementação em memória nos testes.
Future<SharedPreferences> fakePrefs([Map<String, Object>? values]) async {
  SharedPreferences.setMockInitialValues(values ?? {});
  return SharedPreferences.getInstance();
}
