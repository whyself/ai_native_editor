import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../services/qwen_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class SettingsSheet extends ConsumerStatefulWidget {
  const SettingsSheet({super.key});

  @override
  ConsumerState<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<SettingsSheet> {
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _baseUrlCtrl;
  late String _selectedModel;
  bool _obscureKey = true;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyCtrl = TextEditingController(text: settings.apiKey);
    _baseUrlCtrl = TextEditingController(text: settings.baseUrl);
    _selectedModel = kAvailableModels.contains(settings.model)
        ? settings.model
        : kAvailableModels.first;
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ref.read(settingsProvider.notifier).save(
          apiKey: _apiKeyCtrl.text.trim(),
          model: _selectedModel,
          baseUrl: _baseUrlCtrl.text.trim(),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.darkSurface1 : AppColors.lightSurface1;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final surface3 = isDark ? AppColors.darkSurface3 : AppColors.lightSurface3;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final borderSubtle =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.sp24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppTheme.sp20),
                  decoration: BoxDecoration(
                    color: borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'AI 设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.sp20),

              // API Key
              _label('API Key', textSecondary),
              const SizedBox(height: AppTheme.sp8),
              _textField(
                controller: _apiKeyCtrl,
                hint: '输入 Qwen API Key',
                obscure: _obscureKey,
                surface3: surface3,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                suffix: IconButton(
                  icon: Icon(
                    _obscureKey ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: textSecondary,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKey = !_obscureKey),
                ),
              ),

              const SizedBox(height: AppTheme.sp16),

              // Model
              _label('模型', textSecondary),
              const SizedBox(height: AppTheme.sp8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: surface3,
                  borderRadius: BorderRadius.circular(AppTheme.radius8),
                  border: Border.all(color: border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    dropdownColor: surface2,
                    style: TextStyle(fontSize: 14, color: textPrimary),
                    items: kAvailableModels
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m,
                                style: TextStyle(
                                    fontSize: 14, color: textPrimary)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedModel = v);
                    },
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.sp16),

              // Base URL
              _label('Base URL（可选）', textSecondary),
              const SizedBox(height: AppTheme.sp8),
              _textField(
                controller: _baseUrlCtrl,
                hint: 'https://...',
                surface3: surface3,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),

              const SizedBox(height: AppTheme.sp24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radius8),
                    ),
                  ),
                  child: const Text(
                    '保存',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.4),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required Color surface3,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface3,
        borderRadius: BorderRadius.circular(AppTheme.radius8),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(fontSize: 14, color: textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: textSecondary),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
