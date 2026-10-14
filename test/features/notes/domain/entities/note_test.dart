import 'package:flutter_test/flutter_test.dart';
import 'package:mynote/features/notes/domain/entities/note.dart';
import 'package:mynote/features/notes/domain/entities/note_background.dart';

void main() {
  final base = Note(
    id: 'n1',
    folderId: 'f1',
    createdAt: DateTime(2026, 10, 3),
    updatedAt: DateTime(2026, 10, 3),
  );

  test('copyWith 显式置 null 会把 folderId 清空（哨兵语义）', () {
    final moved = base.copyWith(folderId: null);
    expect(moved.folderId, isNull);
    expect(moved.id, 'n1');
  });

  test('copyWith 不传 folderId 时保留原值', () {
    final renamed = base.copyWith(title: '新标题');
    expect(renamed.folderId, 'f1');
    expect(renamed.title, '新标题');
  });

  test('Equatable 相等性覆盖全部字段', () {
    expect(base, isNot(base.copyWith(folderId: null)));
    expect(base, isNot(base.copyWith(content: 'x')));
    expect(base, isNot(base.copyWith(updatedAt: DateTime(2026, 10, 4))));
  });

  test('background 也是哨兵字段：不传保留，显式 null 清空', () {
    final paper = base.copyWith(background: NoteBackground.paper);
    expect(paper.background, NoteBackground.paper);
    expect(paper.copyWith(title: '改标题').background, NoteBackground.paper);
    expect(paper.copyWith(background: null).background, isNull);
    expect(paper, isNot(base));
  });

  test('NoteBackground.fromId 未知值与 null 都降级为无背景', () {
    expect(NoteBackground.fromId('mint'), NoteBackground.mint);
    expect(NoteBackground.fromId(null), isNull);
    expect(NoteBackground.fromId('不存在的背景'), isNull);
  });
}
