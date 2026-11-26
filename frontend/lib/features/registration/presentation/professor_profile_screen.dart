import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class ProfessorProfileScreen extends ConsumerStatefulWidget {
  const ProfessorProfileScreen({super.key});

  @override
  ConsumerState<ProfessorProfileScreen> createState() =>
      _ProfessorProfileScreenState();
}

class _ProfessorProfileScreenState
    extends ConsumerState<ProfessorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _department;
  late final TextEditingController _title;

  @override
  void initState() {
    super.initState();
    final state = ref.read(authControllerProvider).state;
    final account = state.account;
    final draft = state.professorDraft;
    _firstName = TextEditingController(
      text: draft?.firstName ?? account?.firstName,
    );
    _lastName = TextEditingController(
      text: draft?.lastName ?? account?.lastName,
    );
    _department = TextEditingController(text: draft?.department);
    _title = TextEditingController(text: draft?.title ?? 'Professor');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _department.dispose();
    _title.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? context.l10n.requiredField
      : null;

  void _review() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider)
        .stageProfessorProfile(
          ProfessorProfileDraft(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            department: _department.text.trim(),
            title: _title.text.trim(),
          ),
        );
    context.go('/register/professor/review');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.professorProfileTitle,
      description: l10n.professorProfileBody,
      steps: authSteps(l10n),
      currentStep: 2,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.firstName),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(labelText: l10n.lastName),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _department,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.department,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.academicTitle,
                prefixIcon: const Icon(Icons.workspace_premium_outlined),
              ),
              validator: _required,
              onFieldSubmitted: (_) => _review(),
            ),
            const SizedBox(height: 22),
            AsyncPrimaryButton(label: l10n.next, onPressed: _review),
          ],
        ),
      ),
    );
  }
}
