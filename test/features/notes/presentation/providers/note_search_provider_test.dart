import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:init/features/notes/presentation/providers/note_search_provider.dart';

void main() {
  test('默认空串；set 覆盖状态', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(noteSearchProvider), isEmpty);

    container.read(noteSearchProvider.notifier).set('花');
    expect(container.read(noteSearchProvider), '花');

    container.read(noteSearchProvider.notifier).set('');
    expect(container.read(noteSearchProvider), isEmpty, reason: '清空回初始态');
  });
}