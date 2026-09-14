import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_client.dart';

/// Supabase courses 테이블 접근 (읽기 전용. 입력은 tools/insert_course.py).
class CourseService {
  const CourseService(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchAll() =>
      _client.from('courses').select().order('created_at');
}

final courseServiceProvider = Provider<CourseService>(
  (ref) => CourseService(ref.watch(supabaseClientProvider)),
);
