import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsState {
  final String apiKey;
  final String model;
  final String baseUrl;
  final bool isDarkMode;

  const SettingsState({
    this.apiKey = '',
    this.model = 'qwen-plus',
    this.baseUrl = 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    this.isDarkMode = true,
  });

  SettingsState copyWith({
    String? apiKey,
    String? model,
    String? baseUrl,
    bool? isDarkMode,
  }) =>
      SettingsState(
        apiKey: apiKey ?? this.apiKey,
        model: model ?? this.model,
        baseUrl: baseUrl ?? this.baseUrl,
        isDarkMode: isDarkMode ?? this.isDarkMode,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyApiKey = 'qwen_api_key';
  static const _keyModel = 'qwen_model';
  static const _keyBaseUrl = 'qwen_base_url';
  static const _keyDarkMode = 'dark_mode';

  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final apiKey = await _storage.read(key: _keyApiKey) ?? '';
    final model = await _storage.read(key: _keyModel) ?? 'qwen-plus';
    final baseUrl = await _storage.read(key: _keyBaseUrl) ??
        'https://dashscope.aliyuncs.com/compatible-mode/v1';
    final darkStr = await _storage.read(key: _keyDarkMode);
    final isDark = darkStr != 'false';
    state = SettingsState(
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      isDarkMode: isDark,
    );
  }

  Future<void> save({
    String? apiKey,
    String? model,
    String? baseUrl,
    bool? isDarkMode,
  }) async {
    state = state.copyWith(
      apiKey: apiKey,
      model: model,
      baseUrl: baseUrl,
      isDarkMode: isDarkMode,
    );
    if (apiKey != null) await _storage.write(key: _keyApiKey, value: apiKey);
    if (model != null) await _storage.write(key: _keyModel, value: model);
    if (baseUrl != null) await _storage.write(key: _keyBaseUrl, value: baseUrl);
    if (isDarkMode != null) {
      await _storage.write(key: _keyDarkMode, value: isDarkMode.toString());
    }
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
