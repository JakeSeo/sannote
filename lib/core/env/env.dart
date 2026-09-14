import 'package:flutter_dotenv/flutter_dotenv.dart';

/// .env 값 접근용 래퍼. 키가 비어 있으면 앱 시작 시점에 바로 알 수 있도록 예외를 던진다.
abstract final class Env {
  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabasePublishableKey => _require('SUPABASE_PUBLISHABLE_KEY');
  static String get naverMapClientId => _require('NAVER_MAP_CLIENT_ID');

  static String _require(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('.env에 $key 값이 없습니다. .env.example을 참고해 채워주세요.');
    }
    return value;
  }
}
