import 'package:flutter/material.dart';

/// Заглушка на время отложенной загрузки раздела (deferred import).
class DeferredScreen extends StatefulWidget {
  final Future<Widget> Function() loader;

  const DeferredScreen({super.key, required this.loader});

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late final Future<Widget> _future = widget.loader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Не удалось загрузить раздел: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return snapshot.data!;
      },
    );
  }
}
