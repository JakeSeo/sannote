import 'package:flutter/foundation.dart';

/// 실기기 검증용 테스트 데이터 규약. tools/insert_test_route.py 가 만든 산군은 이름이 "[테스트]"로 시작한다.
/// 릴리즈 빌드에서는 이 산군(구간·입구·코스 포함)을 전부 숨긴다.
abstract final class TestData {
  static const prefix = '[테스트]';

  static bool isTestGroup(String mountainGroup) => mountainGroup.startsWith(prefix);

  /// 디버그에서만 노출
  static bool get visible => kDebugMode;

  static bool show(String mountainGroup) => visible || !isTestGroup(mountainGroup);
}
