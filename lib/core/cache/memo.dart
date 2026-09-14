/// 비동기 결과 1회 메모이즈. 실패하면 캐시를 비워 다음 호출에서 재시도한다.
class AsyncMemo<T> {
  Future<T>? _future;

  Future<T> call(Future<T> Function() load) {
    final existing = _future;
    if (existing != null) return existing;
    final f = load();
    _future = f;
    f.then((_) {}, onError: (Object _) => _future = null);
    return f;
  }

  void invalidate() => _future = null;
}
