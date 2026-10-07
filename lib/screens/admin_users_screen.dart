import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/auth.dart';
import '../repositories/auth_api.dart';
import '../state/auth_notifier.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<AppUser>? _users;
  Object? _error;
  bool _loading = true;
  String? _savingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<AuthApi>().listUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _changeRole(AppUser user, Role role) async {
    if (role == user.role || _savingId != null) return;

    final auth = context.read<AuthNotifier>();
    final api = context.read<AuthApi>();
    final isSelf = auth.user?.id == user.id;

    setState(() => _savingId = user.id);
    try {
      final updated = await api.setRole(user.id, role);
      if (!mounted) return;

      setState(() {
        _users = [
          for (final u in _users ?? const <AppUser>[])
            if (u.id == updated.id) updated else u,
        ];
        _savingId = null;
      });

      if (isSelf) {
        await auth.applyUser(updated);
        try {
          await auth.refreshTokens();
        } catch (_) {
          // Роль в UI уже обновлена; токен подтянется при следующем 401.
        }
        if (!mounted) return;
        if (updated.role != Role.admin) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ваша роль изменена на «${updated.role.title}»'),
            ),
          );
          context.go('/');
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${updated.displayName}: роль «${updated.role.title}»'),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось сменить роль: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _users == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _users == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      );
    }

    final users = _users ?? [];
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: users.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Пользователи',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            );
          }
          final u = users[i - 1];
          final busy = _savingId == u.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(u.displayName),
            subtitle: Text('${u.username} · ${u.role.title}'),
            trailing: busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<Role>(
                      value: u.role,
                      borderRadius: BorderRadius.circular(8),
                      items: Role.values
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.title),
                            ),
                          )
                          .toList(),
                      onChanged: _savingId != null
                          ? null
                          : (r) {
                              if (r != null) _changeRole(u, r);
                            },
                    ),
                  ),
          );
        },
      ),
    );
  }
}
