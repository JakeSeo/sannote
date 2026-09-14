import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

/// v1 인증 = Supabase 익명 로그인. 소셜 로그인은 v2 "계정 연동"에서 이 익명 계정에 연결한다.
class AuthService {
  const AuthService(this._client);

  final SupabaseClient _client;

  String? get userId => _client.auth.currentUser?.id;

  /// 세션이 없으면 익명 로그인. 실패해도 앱은 동작해야 하므로 null 반환 (기록은 로컬에 남고 전송만 대기).
  Future<String?> ensureSession() async {
    final existing = _client.auth.currentUser;
    if (existing != null) return existing.id;
    try {
      final res = await _client.auth.signInAnonymously();
      debugPrint('[auth] 익명 로그인 완료: ${res.user?.id}');
      return res.user?.id;
    } on AuthException catch (e) {
      // 대시보드 > Authentication > Providers > Anonymous 가 꺼져 있으면 여기로 온다
      debugPrint('[auth] 익명 로그인 실패 (${e.code ?? e.statusCode}): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[auth] 익명 로그인 오류: $e');
      return null;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(supabaseClientProvider)));
