import 'package:mynote/core/error/failures.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 底部浮层提示，3 秒自动消失。
///
/// 反馈色取自 `context.colors.feedbackSuccess` / `feedbackDanger` —— 此前是本
/// 文件的局部常量（注释写「只有这两页用，进 token 是浪费」）。文件夹管理的删除
/// 菜单也要它，而 notes 不能 import backup（跨 feature），理由已不成立。
void showFeedbackSnack(BuildContext context, String text, {required bool ok}) {
  final colors = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: context.textStyles.rowTitle.copyWith(
            color: ok ? colors.feedbackSuccess : colors.feedbackDanger,
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
