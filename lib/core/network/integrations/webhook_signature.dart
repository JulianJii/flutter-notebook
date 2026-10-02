import 'dart:convert';

import 'package:crypto/crypto.dart';

/// HMAC-SHA256 请求签名，这是 webhook 提供商
///（Stripe、GitHub、Shopify……）使用的事实标准，
/// 允许接收方证明负载确实来自发送方且在传输过程中未被篡改。
abstract class WebhookSignature {
  /// 使用 [secret] 对 [payload]（精确的原始请求主体，因为字节很重要）进行签名，
  /// 生成适合 header 的十六进制编码摘要，例如
  /// `X-Webhook-Signature: sha256=<digest>`。
  static String sign({required String secret, required String payload}) {
    final hmac = Hmac(sha256, utf8.encode(secret));
    return hmac.convert(utf8.encode(payload)).toString();
  }

  /// 使用 [secret] 重新计算 [payload] 的签名，并将其与 [signature] 进行比较
  ///（接受裸十六进制摘要或 `sha256=...` 前缀值，
  /// 符合常见提供商的约定）。
  ///
  /// 使用常量时间比较，以便验证时间不会向攻击者泄露
  /// 签名中有多少前导字节是正确的。
  static bool verify({
    required String secret,
    required String payload,
    required String signature,
  }) {
    final expected = sign(secret: secret, payload: payload);
    final provided = signature.startsWith('sha256=')
        ? signature.substring('sha256='.length)
        : signature;
    return _constantTimeEquals(expected, provided);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
