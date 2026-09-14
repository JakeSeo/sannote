import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env/env.dart';

/// 앱 시작 시 1회 호출. 스키마는 이미 Supabase에 존재하므로 연결만 한다.
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
  );
}

/// Supabase 클라이언트 프로바이더. 레포지토리들은 이걸 주입받아 사용한다.
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);
