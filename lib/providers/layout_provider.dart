import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/persistence_service.dart';

class LayoutState {
  final double leftWidth;
  final double rightWidth;
  final bool leftVisible;
  final bool rightVisible;

  static const defaultLeftWidth = 240.0;
  static const defaultRightWidth = 320.0;
  static const minLeftWidth = 160.0;
  static const maxLeftWidth = 400.0;
  static const minRightWidth = 260.0;
  static const maxRightWidth = 480.0;

  const LayoutState({
    this.leftWidth = defaultLeftWidth,
    this.rightWidth = defaultRightWidth,
    this.leftVisible = true,
    this.rightVisible = true,
  });

  LayoutState copyWith({
    double? leftWidth,
    double? rightWidth,
    bool? leftVisible,
    bool? rightVisible,
  }) =>
      LayoutState(
        leftWidth: leftWidth ?? this.leftWidth,
        rightWidth: rightWidth ?? this.rightWidth,
        leftVisible: leftVisible ?? this.leftVisible,
        rightVisible: rightVisible ?? this.rightVisible,
      );

  Map<String, dynamic> toJson() => {
        'leftWidth': leftWidth,
        'rightWidth': rightWidth,
        'leftVisible': leftVisible,
        'rightVisible': rightVisible,
      };

  factory LayoutState.fromJson(Map<String, dynamic> json) => LayoutState(
        leftWidth: (json['leftWidth'] as num?)?.toDouble() ?? defaultLeftWidth,
        rightWidth:
            (json['rightWidth'] as num?)?.toDouble() ?? defaultRightWidth,
        leftVisible: json['leftVisible'] as bool? ?? true,
        rightVisible: json['rightVisible'] as bool? ?? true,
      );
}

class LayoutNotifier extends Notifier<LayoutState> {
  @override
  LayoutState build() {
    final saved = PersistenceService.instance.loadLayout();
    if (saved != null) {
      return LayoutState.fromJson(saved);
    }
    return const LayoutState();
  }

  void _persist() {
    PersistenceService.instance.saveLayout(state.toJson());
  }

  void toggleLeft() {
    state = state.copyWith(leftVisible: !state.leftVisible);
    _persist();
  }

  void toggleRight() {
    state = state.copyWith(rightVisible: !state.rightVisible);
    _persist();
  }

  void resizeLeft(double delta) {
    final newWidth = (state.leftWidth + delta).clamp(
      LayoutState.minLeftWidth,
      LayoutState.maxLeftWidth,
    );
    state = state.copyWith(leftWidth: newWidth);
    _persist();
  }

  void resizeRight(double delta) {
    final newWidth = (state.rightWidth - delta).clamp(
      LayoutState.minRightWidth,
      LayoutState.maxRightWidth,
    );
    state = state.copyWith(rightWidth: newWidth);
    _persist();
  }
}

final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(
  LayoutNotifier.new,
);
