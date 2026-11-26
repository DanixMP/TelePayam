import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/network/api_exception.dart';
import 'package:university_messenger/core/utils/validators.dart';
import 'package:university_messenger/features/admin/admin_api.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});
  static const path = '/home/admin';

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _phone = TextEditingController();
  String? _phoneError, _approving;
  bool _adding = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _announce(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _approve(StudentRequest student) async {
    if (_approving != null) return;
    setState(() => _approving = student.id);
    try {
      await ref.read(adminApiProvider).approve(student.id);
      if (!mounted) return;
      _announce(context.l10n.studentApproved);
      ref.invalidate(studentRequestsProvider);
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.code == 'approval_not_found') {
        _announce(context.l10n.requestAlreadyReviewed);
        ref.invalidate(studentRequestsProvider);
      } else {
        _announce(context.l10n.genericError);
      }
    } finally {
      if (mounted) setState(() => _approving = null);
    }
  }

  Future<void> _create() async {
    if (_adding) return;
    if (!isValidIranianPhone(_phone.text)) {
      setState(() => _phoneError = context.l10n.invalidPhone);
      return;
    }
    setState(() {
      _adding = true;
      _phoneError = null;
    });
    try {
      await ref
          .read(adminApiProvider)
          .createAdmin(normalizeIranianPhone(_phone.text));
      if (!mounted) return;
      _phone.clear();
      _announce(context.l10n.adminCreated);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(
        () => _phoneError = switch (error.code) {
          'phone_exists' => context.l10n.phoneAlreadyRegistered,
          'invalid_phone' => context.l10n.invalidPhone,
          _ => context.l10n.genericError,
        },
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(authControllerProvider).state.account;
    final l = context.l10n;
    if (account?.status != AccountStatus.active ||
        account?.role.isAdmin != true) {
      return Scaffold(body: Center(child: Text(l.adminAccessRequired)));
    }
    final superAdmin = account!.role == UserRole.superAdmin;
    final queue = ref.watch(studentRequestsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l.chats,
          icon: const Icon(Icons.forum_outlined),
          onPressed: () => context.go('/home'),
        ),
        title: Text(superAdmin ? l.superAdminPanel : l.adminPanel),
        actions: [
          IconButton(
            tooltip: l.refreshRequests,
            icon: const Icon(Icons.refresh),
            onPressed: queue.isLoading
                ? null
                : () => ref.invalidate(studentRequestsProvider),
          ),
          IconButton(
            tooltip: l.logout,
            icon: const Icon(Icons.logout),
            onPressed: ref.read(authControllerProvider).logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CustomScrollView(
              slivers: [
                if (superAdmin)
                  SliverToBoxAdapter(
                    child: ExpansionTile(
                      leading: const Icon(Icons.person_add_alt_1_outlined),
                      title: Text(l.addAdmin),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.newAdminHint),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phone,
                          enabled: !_adding,
                          keyboardType: TextInputType.phone,
                          textDirection: TextDirection.ltr,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: l.phoneLabel,
                            errorText: _phoneError,
                          ),
                          onSubmitted: (_) => _create(),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton(
                            onPressed: _adding ? null : _create,
                            child: Text(l.createAdmin),
                          ),
                        ),
                      ],
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text(
                      l.studentRequests,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                queue.when(
                  skipLoadingOnRefresh: false,
                  loading: () => const SliverToBoxAdapter(
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => SliverToBoxAdapter(
                    child: Column(
                      children: [
                        Text(l.genericError),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(studentRequestsProvider),
                          child: Text(l.retry),
                        ),
                      ],
                    ),
                  ),
                  data: (items) => items.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(l.noStudentRequests),
                          ),
                        )
                      : SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final student = items[index];
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    student.name.isEmpty
                                        ? student.universityId
                                        : student.name,
                                  ),
                                  subtitle: Text(
                                    '${student.degree} · ${student.department}\n${l.universityId}: \u2066${student.universityId}\u2069\n${l.nationalId}: \u2066${student.maskedNationalId}\u2069',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 16,
                                    bottom: 8,
                                  ),
                                  child: Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FilledButton.tonal(
                                      onPressed: _approving == null
                                          ? () => _approve(student)
                                          : null,
                                      child: Text(l.approveStudent),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
