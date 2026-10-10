import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mynote/core/router/app_routes.dart';
import 'package:mynote/core/theme/tokens/app_colors.dart';
import 'package:mynote/core/theme/tokens/app_spacing.dart';
import 'package:mynote/core/theme/tokens/app_text_styles.dart';
import 'package:mynote/core/ui/ui.dart';
import 'package:mynote/core/utils/app_utils.dart';
import 'package:mynote/features/backup/domain/entities/lan_peer.dart';
import 'package:mynote/features/backup/presentation/providers/lan_sync_peers_provider.dart';
import 'package:mynote/features/backup/presentation/widgets/backup_feedback.dart';
import 'package:mynote/features/backup/providers/backup_providers.dart';
import 'package:mynote/gen/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// 局域网同步（`/settings/lan`）。
///
/// 三块：**允许被连接**（开关，本机当服务端）、**发现的设备**（列表，点一下同步）、
/// **手动输入地址**（广播被路由器挡掉时的兜底）。
///
/// 与设置 / 主题页同形态：root 层二级页，整屏盖住 Shell，不渲染 `AppBottomNav`。
///
/// ⚠️ **「允许被连接」离开本页就关** —— 见 [dispose] 的注释。这是有意的：
/// 服务端开着就等于把全部笔记对同网段开放，用户不会期望「关掉这个页面」还继续被连。
class LanSyncScreen extends ConsumerStatefulWidget {
  const LanSyncScreen({super.key});

  @override
  ConsumerState<LanSyncScreen> createState() => _LanSyncScreenState();
}

class _LanSyncScreenState extends ConsumerState<LanSyncScreen> {
  /// 正在与某台设备同步（那台的地址）—— 用于把该行的按钮换成转圈并禁用其余。
  String? _syncingWith;
  bool _hosting = false;

  @override
  void initState() {
    super.initState();
    _hosting = ref.read(lanSyncUseCasesProvider).isHosting;
  }

  @override
  void dispose() {
    // ⚠️ **离开页面就停止服务**。`lanSyncUseCases` 是 keepAlive 的，它的 socket 会
    // 活得比这个 widget 长 —— 不显式关掉，用户早就退出这一页了却还在对同网段
    // 开着一个读写全部笔记的服务。代价是「同步到一半切走会被打断」，那本来就该
    // 中断（合并是幂等的，下次连上继续）。
    ref.read(lanSyncUseCasesProvider).stopHosting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final peers =
        ref.watch(lanSyncPeersProvider).value ?? const <LanPeer>[];

    return Scaffold(
      backgroundColor: context.colors.bg,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            AppTopBar(
              leading: AppIconButton(
                icon: AppIcons.back,
                tooltip: l10n.back,
                color: context.colors.textPrimary,
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.dataManagement),
              ),
              centerTitle: Text(
                l10n.lanTitle,
                style: context.textStyles.topBarTitle,
              ),
              showDivider: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.bottomSafe),
                children: <Widget>[
                  AppSettingsGroup(
                    title: l10n.lanTitle,
                    children: <Widget>[
                      AppSwitchRow(
                        key: const Key('lan_allow_access'),
                        title: l10n.lanAllowAccess,
                        subtitle: l10n.lanAllowAccessDesc,
                        value: _hosting,
                        onChanged: _hosting ? _stopHosting : _startHosting,
                      ),
                      if (_hosting)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.rowPadH,
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            l10n.lanHostingOn,
                            style: context.textStyles.meta.copyWith(
                              color: context.colors.textTertiary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  AppSettingsGroup(
                    title: l10n.dataGroupWebDav,
                    children: <Widget>[
                      AppListTile(
                        key: const Key('lan_manual'),
                        title: l10n.lanManual,
                        trailing: _chevron(context),
                        onTap: _promptManual,
                      ),
                    ],
                  ),
                  if (peers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.pageH,
                        vertical: AppSpacing.lg,
                      ),
                      child: Text(
                        // ⚠️ 只有本机开着服务时才有意义去等别人发现我们；没开时
                        // 说「正在查找」会让人一直等一个不可能的结果。
                        _hosting ? l10n.lanSearching : l10n.lanNoPeers,
                        textAlign: TextAlign.center,
                        style: context.textStyles.subtitle.copyWith(
                          color: context.colors.textTertiary,
                        ),
                      ),
                    )
                  else
                    for (final peer in peers)
                      _PeerRow(
                        peer: peer,
                        busy: _syncingWith == peer.address,
                        onTap: _syncingWith == null
                            ? () => _sync(peer)
                            : null,
                      ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.rowPadH,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      l10n.lanSecurityNote,
                      style: context.textStyles.meta.copyWith(
                        color: context.colors.textTertiary,
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

  Future<void> _startHosting(bool on) async {
    final result = await ref
        .read(lanSyncUseCasesProvider)
        .startHosting(_deviceName());
    if (!mounted) return;
    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: false),
      (_) => setState(() => _hosting = true),
    );
  }

  Future<void> _stopHosting(bool on) async {
    await ref.read(lanSyncUseCasesProvider).stopHosting();
    if (!mounted) return;
    setState(() {
      _hosting = false;
      _syncingWith = null;
    });
  }

  Future<void> _sync(LanPeer peer) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _syncingWith = peer.address);

    final result = await ref.read(lanSyncUseCasesProvider).syncWithPeer(peer);
    if (!mounted) return;
    setState(() => _syncingWith = null);

    result.fold(
      (failure) => showFailureSnack(context, failure, isImport: false),
      (report) {
        showFeedbackSnack(context, l10n.lanSyncDone(report.changed), ok: true);
        // 对时是**顺带**的，值得单独说一句 —— 否则用户不知道刚才还校了时钟。
        if (report.clockOffset.abs() >= const Duration(minutes: 1)) {
          AppUtils.showSnackBar(context, message: l10n.lanClockAligned(peer.name));
        }
      },
    );
  }

  /// 手输 IP + 端口。⚠️ 端口由用户从对方屏幕上抄 —— 双方各自开服务时端口是随机的，
  /// 没有约定值可用（见 `LanServer.start`）。
  Future<void> _promptManual() async {
    final l10n = AppLocalizations.of(context);
    var ip = '';
    var port = '';

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.lanManualTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l10n.lanManualIp),
              onChanged: (v) => ip = v.trim(),
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.lanManualPort),
              onChanged: (v) => port = v.trim(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.lanManualHint,
              style: context.textStyles.meta.copyWith(
                color: context.colors.textTertiary,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.lanManualAdd),
          ),
        ],
      ),
    );

    final parsedPort = int.tryParse(port);
    if (added != true || ip.isEmpty || parsedPort == null) return;

    await ref
        .read(lanSyncUseCasesProvider)
        .addManualPeer(ip, '$ip:$parsedPort');
  }

  /// 信标里的显示名。
  ///
  /// ⚠️ ⛔ **不取「第一台已发现设备的 IP」当自己的名字** —— 那读起来像「我的 IP」，
  /// 实际是别人的，会让对端在列表里看到一台以自己地址命名的设备。
  /// 拿不到设备名就发空串，信标里回落成对方的 IP（见 `LanPeer.fromBeacon`），
  /// 那是对的：显示的一直是**这台设备自己的**地址。
  String _deviceName() => '';
}

/// 设备列表的一行。
class _PeerRow extends StatelessWidget {
  const _PeerRow({required this.peer, required this.busy, required this.onTap});

  final LanPeer peer;

  /// 该行正在同步中（转圈并禁用）。
  final bool busy;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageH,
        0,
        AppSpacing.pageH,
        AppSpacing.sm,
      ),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.rowPadH,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                peer.label,
                style: context.textStyles.rowTitle.copyWith(
                  color: context.colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.chipGap),
            if (busy)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colors.textSecondary,
                ),
              )
            else
              Text(
                l10n.lanSync,
                style: context.textStyles.value.copyWith(
                  color: context.colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

AppIcon _chevron(BuildContext context) => AppIcon(
  icon: AppIcons.chevronRight,
  size: 20,
  color: context.colors.textSecondary,
);