import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/integrations/graphql_client.dart';

/// 演示通过可复用的 [GraphQLClient] 进行查询和变更操作，
/// 针对两个公共的演示 GraphQL API（无需认证）：
/// - `countries.trevorblades.com` 用于只读的查询标签页。
/// - `graphqlzero.almansi.me` 用于变更标签页（一个为这类演示而创建的、可变的 JSONPlaceholder 风格的 API）。
///
/// 将 `core/network/integrations/graphql_client.dart` 复制到真实的功能模块中，
/// 并将 `endpoint` 指向你自己的服务器以复用此模式。
class GraphQLExampleScreen extends StatelessWidget {
  const GraphQLExampleScreen({super.key});

  static const _countriesEndpoint = 'https://countries.trevorblades.com/';
  static const _mutableDemoEndpoint = 'https://graphqlzero.almansi.me/api';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GraphQL example'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Query'),
              Tab(text: 'Mutation'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ContinentsQueryTab(), _CreatePostMutationTab()],
        ),
      ),
    );
  }
}

const _continentsQuery = r'''
  query Continents {
    continents {
      code
      name
      countries {
        code
        name
        emoji
      }
    }
  }
''';

class _ContinentsQueryTab extends ConsumerWidget {
  const _ContinentsQueryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(
      graphQLClientProvider(GraphQLExampleScreen._countriesEndpoint),
    );

    return FutureBuilder<Map<String, dynamic>>(
      future: client.query(_continentsQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(error: snapshot.error!);
        }

        final continents =
            (snapshot.data?['continents'] as List<dynamic>?) ?? const [];
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: continents.length,
          itemBuilder: (context, index) {
            final continent = continents[index] as Map<String, dynamic>;
            final countries =
                (continent['countries'] as List<dynamic>?) ?? const [];
            return ExpansionTile(
              title: Text('${continent['name']} (${continent['code']})'),
              children: countries
                  .cast<Map<String, dynamic>>()
                  .map(
                    (country) => ListTile(
                      dense: true,
                      leading: Text(
                        '${country['emoji'] ?? ''}',
                        style: const TextStyle(fontSize: 20),
                      ),
                      title: Text('${country['name']}'),
                      trailing: Text('${country['code']}'),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }
}

const _createPostMutation = r'''
  mutation CreatePost($input: CreatePostInput!) {
    createPost(input: $input) {
      id
      title
      body
    }
  }
''';

class _CreatePostMutationTab extends ConsumerStatefulWidget {
  const _CreatePostMutationTab();

  @override
  ConsumerState<_CreatePostMutationTab> createState() =>
      _CreatePostMutationTabState();
}

class _CreatePostMutationTabState
    extends ConsumerState<_CreatePostMutationTab> {
  final _titleController = TextEditingController(text: 'Hello GraphQL');
  final _bodyController = TextEditingController(
    text: 'Created from the Flutter template.',
  );
  Object? _error;
  Map<String, dynamic>? _created;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final client = ref.read(
      graphQLClientProvider(GraphQLExampleScreen._mutableDemoEndpoint),
    );
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await client.mutate(
        _createPostMutation,
        variables: {
          'input': {
            'title': _titleController.text,
            'body': _bodyController.text,
          },
        },
      );
      setState(() => _created = data['createPost'] as Map<String, dynamic>?);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Body',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _loading ? null : _createPost,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: const Text('Run createPost mutation'),
        ),
        const SizedBox(height: 16),
        if (_error != null) _ErrorView(error: _error!),
        if (_created != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text('${_created!['title']}'),
              subtitle: Text('id: ${_created!['id']}'),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        'Request failed: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
