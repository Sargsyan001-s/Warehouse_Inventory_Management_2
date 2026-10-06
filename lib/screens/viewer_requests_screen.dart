import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/auth_api.dart';

class ViewerRequestsScreen extends StatelessWidget {
  const ViewerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои заявки')),
      body: FutureBuilder(
        future: context.read<AuthApi>().viewerRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Заявок нет'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              return ListTile(
                title: Text('${e['title']}'),
                subtitle: Text('${e['status']} · ${e['createdAt']}'),
              );
            },
          );
        },
      ),
    );
  }
}
