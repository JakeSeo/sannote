import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/env/env.dart';
import 'core/map/naver_map_init.dart';
import 'core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Env.load();
  await initSupabase();
  await initNaverMap();

  runApp(const ProviderScope(child: SannoteApp()));
}
