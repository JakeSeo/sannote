import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/env/env.dart';
import 'core/map/naver_map_init.dart';
import 'core/supabase/supabase_client.dart';
import 'features/records/domain/usecases/backfill_moving_time.dart';
import 'features/records/domain/usecases/sync_visits.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load();
  await initSupabase();
  await initNaverMap();

  final container = ProviderContainer();
  // 익명 로그인과 대기 중인 완주 기록 전송은 앱 시작을 막지 않는다 (실패해도 로컬 기록은 유지)
  unawaited(container.read(authServiceProvider).ensureSession().then((_) => container.read(syncVisitsProvider).call()));
  unawaited(container.read(backfillMovingTimeProvider).call());

  runApp(UncontrolledProviderScope(container: container, child: const SannoteApp()));
}
