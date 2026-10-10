import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/features/backup/domain/entities/webdav_config.dart';
import 'package:mynote/features/backup/presentation/providers/webdav_config_provider.dart';
import 'package:mynote/features/backup/presentation/widgets/backup_feedback.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// WebDAV 服务器配置页（`/settings/webdav`）。
///
/// 四个字段 + 一次探活 + 保存。与设置 / 主题页同形态（root 层二级页）。
///
/// ⚠️ 表单状态用 `TextEditingController` 而不是塞进 Riverpod：这是**一屏内的
/// 草稿**，离开即弃；为它建一个 Notifier 等于把「还没保存的文本」变成 App 级状态。
class WebDavConfigScreen extends ConsumerStatefulWidget {
  const WebDavConfigScreen({super.key});

  @override
  ConsumerState<WebDavConfigScreen> createState() => _WebDavConfigScreenState();
}

class _WebDavConfigScreenState extends ConsumerState<WebDavConfigScreen> {
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _remoteFile;

  /// 已落盘的那一份。与当前表单值比较得出「有没有改动」。
  late WebDavConfig _saved;

  var _obscure = true;
  var _testing = false;
  bool? _testOk;

  @override
  void initState() {
    super.initState();
    _saved = ref.read(webDavConfigProvider);
    _url = TextEditingController(text: _saved.url)..addListener(_onEdit);
    _username = TextEditingController(text: _saved.username)..addListener(_onEdit);
    _password = TextEditingController(text: _saved.password)..addListener(_onEdit);
    _remoteFile = TextEditingController(text: _saved.remoteFile)
      ..addListener(_onEdit);
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    _remoteFile.dispose();
    super.dispose();
  }

  /// 输入变化只影响「保存按钮亮不亮」与「上次测试结果是否还有效」。
  void _onEdit() {
    if (!mounted) return;
    // 改了地址 / 账号，上一次的「连接成功」就不再作数。
    setState(() => _testOk = null);
  }

  WebDavConfig get _current => _saved.copyWith(
    url: _url.text.trim(),
    username: _username.text,
    password: _password.text,
    remoteFile: _remoteFile.text.trim().isEmpty
        ? WebDavConfig.kDefaultRemoteFile
        : _remoteFile.text.trim(),
  );

  bool get _dirty => _current != _saved;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.settings),
              ),
              centerTitle: Text(
                l10n.webDavTitle,
                style: context.textStyles.topBarTitle,
              ),
              actions: <Widget>[
                // 没改动时置灰：让用户看得见「点保存会发生什么」。
                TextButton(
                  onPressed: _dirty ? _save : null,
                  child: Text(
                    l10n.webDavSave,
                    style: context.textStyles.rowTitle.copyWith(
                      color: _dirty ? colors.accent : colors.textTertiary,
                    ),
                  ),
                ),
              ],
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    title: l10n.webDavGroupAccount,
                    children: <Widget>[
                      _field(
                        context,
                        label: l10n.webDavUrl,
                        controller: _url,
                        hint: 'https://dav.example.com/notes/',
                        keyboardType: TextInputType.url,
                      ),
                      _field(
                        context,
                        label: l10n.webDavUsername,
                        controller: _username,
                        dividerBefore: true,
                      ),
                      _field(
                        context,
                        label: l10n.webDavPassword,
                        controller: _password,
                        dividerBefore: true,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                            size: _kSuffixIconSize,
                          ),
                          tooltip: l10n.webDavPasswordToggle,
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                      _field(
                        context,
                        label: l10n.webDavRemoteFile,
                        controller: _remoteFile,
                        hint: WebDavConfig.kDefaultRemoteFile,
                        dividerBefore: true,
                      ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.webDavGroupAction,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('webdav_test'),
                        title: l10n.webDavTest,
                        trailing: _testTrailing(context, l10n),
                        onTap: _testing ? null : _test,
                      ),
                      AppListTile(
                        key: const Key('webdav_history'),
                        title: l10n.webDavHistory,
                        trailing: _chevron(context),
                        dividerBefore: true,
                        onTap: () => context.push(AppRoutes.webDavHistory),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.rowPadH,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l10n.webDavNote,
                      style: context.textStyles.meta.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _testTrailing(BuildContext context, AppLocalizations l10n) {
    if (_testing) {
      return SizedBox(
        width: _kSuffixIconSize,
        height: _kSuffixIconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: context.colors.textSecondary,
        ),
      );
    }
    if (_testOk == null) return const SizedBox.shrink();
    final colors = context.colors;
    return Text(
      _testOk! ? l10n.webDavTestOk : l10n.webDavTestFailed,
      style: context.textStyles.value.copyWith(
        color: _testOk! ? colors.feedbackSuccess : colors.feedbackDanger,
      ),
    );
  }

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _testOk = null;
    });
    final result = await ref.read(webDavConfigProvider.notifier).test(_current);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = result.isRight();
    });
  }

  Future<void> _save() async {
    final next = _current;
    final result = await ref.read(webDavConfigProvider.notifier).save(next);
    if (!mounted) return;
    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: false),
      (_) {
        setState(() => _saved = next);
        showFeedbackSnack(context, AppLocalizations.of(context).webDavSaved, ok: true);
      },
    );
  }

  /// 一行「标签 + 输入框」。标签定宽，输入框占满剩余。
  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    bool dividerBefore = false,
  }) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (dividerBefore) AppDivider(indent: AppSpacing.rowPadH),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.rowPadH),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: _kLabelWidth,
                child: Text(
                  label,
                  style: context.textStyles.rowTitle.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  // 地址行不自动首字母大写：URL 大小写敏感。
                  autocorrect: false,
                  enableSuggestions: false,
                  style: context.textStyles.rowTitle,
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: context.textStyles.rowTitle.copyWith(
                      color: colors.textTertiary,
                    ),
                    suffixIcon: suffix,
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: _kSuffixIconSize,
                      minHeight: _kSuffixIconSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 标签定宽：四个字段的输入框左边界对齐。
const double _kLabelWidth = 96;

const double _kSuffixIconSize = 20;

/// 行尾 chevron。与 `DataManagementScreen._chevron` 同规格（20dp、
/// `textSecondary`）—— 两个 screen 各写一个是因为它是**私有**的，上提到
/// `core/ui` 只为一个调用点不值得。
AppIcon _chevron(BuildContext context) => AppIcon(
  icon: AppIcons.chevronRight,
  size: _kSuffixIconSize,
  color: context.colors.textSecondary,
);
