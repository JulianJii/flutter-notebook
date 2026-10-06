/// 路由路径常量。唯一 Source of Truth。
///
/// 背景：路径常量此前散落在 `AppConstants`（26 个，与 Hive box 名、
/// SharedPreferences key、动画时长混在一起），新增笔记路由会加剧混乱。
/// 见 `specs/docs/DEVELOPMENT-GUIDELINES.md` §13 路由规则。
///
/// ⚠️ 命名与路径的对应关系以本文件注释为准，不要按名字反推：
/// `notes` = `/notes`（P1 笔记列表），而 `AppConstants.homeRoute` = `/home`
/// （模板首页，Phase 0 内被本文件取代）。
abstract final class AppRoutes {
  /// 初始路由。P1 笔记列表。
  /// 取代 `AppConstants.initialRoute`（`/`）+ `AppConstants.homeRoute`（`/home`）。
  static const String initial = '/notes';

  /// P1 笔记列表。Shell branch 0 的根路由。
  static const String notes = '/notes';

  /// 新建笔记。与 `/notes/:id` 区分，避免「新建」和「编辑已有」共用一条路径。
  /// 见 `ARCHITECTURE-DESIGN.md` §8.2。
  ///
  /// ⚠️ 注册顺序：`/notes/new` **必须**注册在 `/notes/:id` 之前，
  /// 否则 `new` 会被当成笔记 id 吃掉。
  static const String noteNew = '/notes/new';

  /// P4 文件夹管理。`/notes` branch 的子路由，返回键回到 P1。
  static const String noteFolders = '/notes/folders';

  /// 「最近删除」回收站。`/notes` branch 的子路由（P5 设置进入）。
  ///
  /// ⚠️ 与 `folders` / `new` 同理，**必须**注册在 `/notes/:id` 之前。
  static const String noteTrash = '/notes/trash';

  /// P3 笔记详情 / 编辑。`/notes` branch 的子路由。路径参数：`id`。
  static const String noteDetail = '/notes/:id';

  /// [noteDetail] 的具体路径。`:id` 是路径参数，拼 URL 时从这里过 ——
  /// 调用点不写裸字符串，路径只有这一处定义。
  static String noteDetailPath(String id) =>
      '/notes/${Uri.encodeComponent(id)}';

  /// P2 待办。Shell branch 1 的根路由。
  static const String todos = '/todos';

  /// P5 设置。从 P1 或 P2 push 进入，返回目标为 P1。
  static const String settings = '/settings';

  /// 主题。明暗（浅色 / 深色 / 跟随系统）+ 配色方案两个独立维度，从 P5 进入。
  ///
  /// ⚠️ 路径前缀是 `/settings`，与隐私政策 / 用户协议同层（root navigator）。
  static const String theme = '/settings/theme';

  /// 数据与同步（导出 / 导入 / WebDAV）。`/settings` 的兄弟路由。
  static const String dataManagement = '/settings/data';

  /// WebDAV 服务器配置。从 [dataManagement] 进入。
  static const String webDav = '/settings/webdav';

  /// 隐私政策。`/settings` 的兄弟路由（root navigator，整页覆盖）。
  static const String privacyPolicy = '/settings/privacy-policy';

  /// 用户协议。`/settings` 的兄弟路由（root navigator，整页覆盖）。
  static const String userAgreement = '/settings/user-agreement';

  /// 文件夹筛选的 query 参数名。`/notes?folder=<id>`。
  ///
  /// D4 点文件夹行与 D1 的筛选 chip 共用这一个参数，
  /// 使 Q12 / Q18 无论答案是什么，架构都不用改。见 `ARCHITECTURE-DESIGN.md` §8.2。
  static const String folderQueryKey = 'folder';
}

/// `?folder=` 的「未分类」哨兵值。`/notes?folder=uncategorized`。
///
/// ⚠️ 它**不是** `AppRoutes` 的路径，故不放进那个类；但它与 [AppRoutes.folderQueryKey]
/// 是同一套 URL 词汇，调用方一律引用常量、不写裸字符串。
/// 真实文件夹 id 是 uuid，与该字面量不可能碰撞。
const String kFolderFilterUncategorized = 'uncategorized';
