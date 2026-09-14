import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 지도에서 현재 포커스된 산군 (mountain_group). null = 전체 개요.
class SelectedMountainNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? mountainGroup) {
    if (state != mountainGroup) state = mountainGroup;
  }
}

final selectedMountainProvider =
    NotifierProvider<SelectedMountainNotifier, String?>(SelectedMountainNotifier.new);
