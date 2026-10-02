# 本地化指南

本指南介绍如何在 Flutter Riverpod Clean Architecture 项目中使用和扩展本地化系统。

## 目录

- [概述](#overview)
- [设置](#setup)
- [使用方法](#usage)
  - [基本翻译](#basic-translation)
  - [带参数的翻译](#translation-with-parameters)
  - [复数形式](#pluralization)
  - [日期和货币格式](#date-and-currency-formatting)
- [添加新语言](#adding-new-languages)
- [更新翻译](#updating-translations)
- [UI 组件](#ui-components)
- [语言特定资源](#language-specific-assets)
- [与 Riverpod 集成](#working-with-riverpod)
- [最佳实践](#best-practices)

## 概述

本项目实现了一个完整的国际化 (i18n) 系统，包含：

- 多语言支持
- 参数化消息
- 复数形式
- 日期和货币格式化
- Riverpod 集成的状态管理
- 易于使用的 BuildContext 扩展

该系统结合了基于 ARB 的翻译和内存翻译映射表，提供了灵活性并与 Flutter intl 系统集成。

## 设置

本地化系统使用：

1. **ARB 文件** - 定义每种语言的翻译
2. **Flutter Intl** - 从 ARB 文件生成 Dart 代码
3. **Riverpod providers** - 管理活动区域设置
4. **BuildContext 扩展** - 提供对翻译的便捷访问

### 配置

`l10n.yaml` 文件配置本地化系统：

```yaml
arb-dir: lib/l10n/arb
template-arb-file: intl_zh.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/gen/l10n
nullable-getter: false
preferred-supported-locales: ["zh", "en"]
use-deferred-loading: false
```

## 使用方法

### 基本翻译

在 BuildContext 上使用 `tr` 扩展方法：

```dart
// In a widget build method
Text(context.tr('welcome_message'));

// For static text keys
final buttonLabel = context.tr('login');
```

### 带参数的翻译

使用 `trParams` 扩展方法处理带参数的消息：

```dart
// With named parameters
Text(context.trParams('greeting', {'name': user.displayName}));

// Example message in ARB file: "greeting": "Hello, {name}!"
```

### 复数形式

处理根据数量值变化的消息：

```dart
// With pluralization logic
final itemText = context.tr('itemCount').replaceAll('{count}', items.length.toString());

// ARB definition: 
// "itemCount": "{count, plural, =0{No items} =1{1 item} other{% raw %}{{count}}{% endraw %} items}"
```

### 日期和货币格式

根据用户的区域设置格式化日期和货币：

```dart
// Format date
final formattedDate = context.formatDate(DateTime.now());

// Format time
final formattedTime = context.formatTime(DateTime.now());

// Format date and time together
final formattedDateTime = context.formatDateTime(DateTime.now());

// Format currency
final formattedPrice = context.formatCurrency(19.99);

// Format with custom patterns
final customDate = context.formatDate(DateTime.now(), pattern: 'EEEE, MMMM d, yyyy');
final customTime = context.formatTime(DateTime.now(), pattern: 'HH:mm:ss');
```

### 使用 LocalizationService

对于更高级的用法，或需要在 widget 外部使用本地化时，可以使用 `LocalizationService`：

```dart
// In a Consumer widget or when you have access to a WidgetRef
final service = ref.read(localizationServiceProvider);
final translatedText = service.translate('welcome_message');
final formattedDate = service.formatDate(DateTime.now());

// Change the app locale
await service.setLocale(const Locale('fr'));
await service.resetToSystemLocale();
```

你也可以通过 BuildContext 扩展使用该服务：

```dart
// Get the service through context
final service = context.localization;

// Or use extension methods directly
await context.setLocale(const Locale('es'));
final currentLocale = context.currentLocale;
```

## 添加新语言

添加新的支持语言：

1. 使用提供的生成脚本（推荐）：

   ```bash
   ./generate_language.sh <language_code> "<Language Name>"
   # Example:
   ./generate_language.sh it "Italian"
   ```

   该脚本将：
   - 基于英语模板创建新的 ARB 文件
   - 自动将语言添加到 LocalizationUtils
   - 正确格式化文件

2. 或者在 `lib/l10n/arb` 目录中手动创建名为 `intl_<language_code>.arb` 的新 ARB 文件
   （例如，法语为 `intl_fr.arb`）

3. 为模板 ARB 文件 (`intl_en.arb`) 中定义的所有键添加翻译

4. 确保新区域设置在 `lib/l10n/l10n.dart` 的支持区域设置列表中：

   ```dart
   static const List<Locale> supportedLocales = [
     Locale('zh'),
     Locale('en'),
   ];
   ```

5. 在 `lib/l10n/app_localizations_delegate.dart` 的 `LocalizationUtils.getLocaleName()` 中添加语言名称：

   ```dart
   static String getLocaleName(Locale locale) {
     switch (locale.languageCode) {
       case 'zh': return '中文';
       case 'en': return 'English';
       default: return locale.languageCode;
     }
   }
   ```

## 更新翻译

要更新或添加新的翻译键：

1. 在模板 ARB 文件 (`intl_en.arb`) 中添加新键
2. 在所有其他 ARB 文件中添加该键的翻译
3. 重新构建应用以生成更新的本地化文件

## UI 组件

项目包含用于语言选择的即用型 UI 组件：

- `LanguageSelectorWidget` - 显示可用语言列表的 widget
- `LanguageSelectorDialog` - 用于选择语言的对话框
- `LanguagePopupMenuButton` - 用于选择语言的弹出菜单按钮

使用示例：

```dart
// Show language selector in a dialog
ElevatedButton(
  onPressed: () => LanguageSelectorDialog.show(context),
  child: Text('Select Language'),
);

// Add language button to AppBar
AppBar(
  title: Text('My App'),
  actions: const [
    LanguagePopupMenuButton(),
  ],
);
```

## 语言特定资源

项目支持根据用户选择的语言加载不同的资源：

### 目录结构

资源在 assets 目录中按语言代码组织：

```
assets/
  ├── images/
  │   ├── common_image.png  # Shared across all languages
  │   ├── zh/
  │   │   └── welcome.png  # 中文专属图片
  │   └── en/
  │       └── welcome.png  # English-specific image
  └── fonts/
```

### 使用本地化资源

`LocalizedAssetService` 和 `LocalizedImage` widget 使语言特定资源的使用变得简单：

```dart
// Using the LocalizedImage widget (automatically uses current locale)
LocalizedImage(
  imageName: 'welcome.png',
  width: 200,
  height: 100,
  fit: BoxFit.cover,
)

// For non-localized images in the common directory
LocalizedImage(
  imageName: 'logo.png',
  useCommonPath: true,
)

// Getting image paths directly
String localizedPath = LocalizedAssetService.getLocalizedImagePath(context, 'welcome.png');
String commonPath = LocalizedAssetService.getCommonImagePath('logo.png');
```

### 回退机制

如果当前区域设置中没有可用的图像，系统将尝试加载：

1. 当前区域设置的图像
2. 如果未找到，则加载英语版本（回退）
3. 如果仍未找到，则显示占位符或错误 widget

### 添加新的语言特定资源

为特定语言添加资源：

1. 将文件放在相应的语言目录中（例如，西班牙语为 `assets/images/es/`）
2. 确保文件名在所有语言中保持一致
3. 如果添加新的资源目录，请更新 pubspec.yaml

## 与 Riverpod 集成

系统使用 Riverpod providers 来管理活动区域设置：

```dart
// Watch the current locale
final currentLocale = ref.watch(localeProvider);

// Change the active locale
ref.read(localeProvider.notifier).setLocale(const Locale('es'));

// Access translations based on the current locale
final translations = ref.watch(translationsProvider);
```

## 最佳实践

1. **使用扁平键** - 翻译键使用扁平命名（例如 `login_title`、`welcome_message`），不使用点分隔
2. **添加描述** - 在 ARB 文件中为所有键包含描述
3. **处理缺失翻译** - 如果翻译缺失，系统将回退到英语
4. **使用 context 扩展** - 优先使用 `context.tr()` 而不是直接访问翻译对象
5. **保持 ARB 文件一致性** - 确保所有语言具有相同的键集
6. **使用参数** - 避免字符串拼接，使用参数代替
7. **测试所有语言** - 在所有支持的语言中验证 UI 布局（某些语言可能更长/更短）
8. **更新所有文件** - 添加新键时，更新所有 ARB 文件以避免缺失翻译