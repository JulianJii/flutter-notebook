import 'package:flutter_test/flutter_test.dart';
import 'package:init/features/notes/domain/entities/note_query.dart';

void main() {
  test('默认值 = 全部 + editedDesc + 无搜索 + 不分页', () {
    const q = NoteQuery();
    expect(q.folder, const AllFolders());
    expect(q.sort, NoteSort.editedDesc);
    expect(q.searchTerm, isNull);
    expect(q.limit, isNull);
    expect(q.offset, 0);
  });

  test('copyWith(searchTerm: null) 真的清掉搜索词', () {
    const q = NoteQuery(searchTerm: '日报');
    expect(q.copyWith(searchTerm: null).searchTerm, isNull);
    expect(q.copyWith(sort: NoteSort.titleAsc).searchTerm, '日报');
  });

  test('三态筛选互不相等（StreamProvider.family 靠这个定位）', () {
    expect(const AllFolders(), isNot(const UncategorizedNotes()));
    expect(const SingleFolder('f1'), isNot(const SingleFolder('f2')));
    expect(NoteQuery.of('f1'), const NoteQuery(folder: SingleFolder('f1')));
    expect(const NoteQuery().hashCode, const NoteQuery().hashCode);
    expect(
      NoteQuery.uncategorized(),
      const NoteQuery(folder: UncategorizedNotes()),
    );
  });
}
