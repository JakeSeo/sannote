import 'package:flutter/foundation.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../env/env.dart';

/// 네이버 지도 SDK 초기화. NaverMap 위젯을 처음 그리기 전에 반드시 호출.
Future<void> initNaverMap() async {
  await FlutterNaverMap().init(
    clientId: Env.naverMapClientId,
    onAuthFailed: (ex) {
      switch (ex) {
        case NQuotaExceededException(:final message):
          debugPrint('[naver_map] 사용량 초과: $message');
        case NUnauthorizedClientException() ||
            NClientUnspecifiedException() ||
            NAnotherAuthFailedException():
          // 패키지명/번들ID가 콘솔 등록값과 다르면 여기로 온다 (지도가 회색으로 표시됨)
          debugPrint('[naver_map] 인증 실패: $ex');
      }
    },
  );
}
