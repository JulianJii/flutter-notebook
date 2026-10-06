import 'package:init/core/error/failures.dart';
import 'package:init/core/theme/tokens/app_text_styles.dart';
import 'package:init/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 反馈色。成功绿 / 失败红。
///
/// ⛔ 不进 `core/theme/tokens/app_colors.dart`：只有数据与同步这两页用，进 token
/// 会让「功能色」变成一套没人维护的第二语义色板。
const Color feedbackSuccess = Color(0xFF34C759);

const Color feedbackDanger = Color(0xFFFF3B30);

/// 底部浮层提示，3 秒自动消失。
void showFeedbackSnack(BuildContext context, String text, {required bool ok}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: context.textStyles.rowTitle.copyWith(
            color: ok ? feedbackSuccess : feedbackDanger,
          ),
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// 把 Failure 翻成用户能读的一句话。
///
/// ⛔ **不显示 `failure.message`**：那是英文的技术细节，且 WebDAV 的错误消息里
/// 可能带完整 URL（含用户名）。
///
/// [isImport] 用于分流 `ValidationFailure` —— 导入时它是「文件不是快照」，
/// 同步时它是「还没配服务器」。
void showFailureSnack(
  BuildContext context,
  Failure failure, {
  required bool isImport,
}) {
  final l10n = AppLocalizations.of(context);
  final text = switch (failure) {
    NetworkFailure() => l10n.dataErrorNetwork,
    TimeoutFailure() => l10n.dataErrorTimeout,
    AuthFailure() || UnauthorizedFailure() => l10n.dataErrorAuth,
    ServerFailure() => l10n.dataErrorServer,
    ValidationFailure() => isImport
        ? l10n.dataErrorInvalidFile
        : l10n.dataErrorNotConfigured,
    _ => l10n.dataErrorUnknown,
  };
  showFeedbackSnack(context, text, ok: false);
}
