import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/utils/validators.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class StudentProfileScreen extends ConsumerStatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  ConsumerState<StudentProfileScreen> createState() =>
      _StudentProfileScreenState();
}

class _StudentProfileScreenState extends ConsumerState<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _nationalId;
  late final TextEditingController _department;
  late final TextEditingController _universityId;
  String _degree = 'BSc';

  @override
  void initState() {
    super.initState();
    final state = ref.read(authControllerProvider).state;
    final account = state.account;
    final draft = state.studentDraft;
    _firstName = TextEditingController(
      text: draft?.firstName ?? account?.firstName,
    );
    _lastName = TextEditingController(
      text: draft?.lastName ?? account?.lastName,
    );
    _nationalId = TextEditingController(text: draft?.nationalId);
    _department = TextEditingController(text: draft?.department);
    _universityId = TextEditingController(text: draft?.universityId);
    _degree = draft?.degree ?? 'BSc';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _nationalId.dispose();
    _department.dispose();
    _universityId.dispose();
    super.dispose();
  }

  void _review() {
    if (!_formKey.currentState!.validate()) return;
    ref
        .read(authControllerProvider)
        .stageStudentProfile(
          StudentProfileDraft(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            nationalId: _nationalId.text,
            degree: _degree,
            department: _department.text.trim(),
            universityId: _universityId.text.trim(),
          ),
        );
    context.go('/register/student/review');
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? context.l10n.requiredField
      : null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider).state;
    final correcting = state.account?.correctionNote?.isNotEmpty ?? false;
    return AuthScaffold(
      title: correcting ? l10n.correctionTitle : l10n.studentProfileTitle,
      description: correcting ? l10n.correctionBody : l10n.studentProfileBody,
      steps: authSteps(l10n),
      currentStep: 2,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (correcting) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(state.account!.correctionNote!),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.firstName),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastName,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l10n.lastName),
                    validator: _required,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _nationalId,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: l10n.nationalId,
                  hintText: l10n.nationalIdHint,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
                validator: (value) => isValidIranianNationalId(value ?? '')
                    ? null
                    : l10n.invalidNationalId,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _degree,
              decoration: InputDecoration(
                labelText: l10n.degree,
                prefixIcon: const Icon(Icons.school_outlined),
              ),
              items: const ['BSc', 'MSc', 'PhD', 'other']
                  .map(
                    (degree) =>
                        DropdownMenuItem(value: degree, child: Text(degree)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _degree = value ?? _degree),
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
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _universityId,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: l10n.universityId,
                  prefixIcon: const Icon(Icons.numbers_rounded),
                ),
                validator: _required,
                onFieldSubmitted: (_) => _review(),
              ),
            ),
            const SizedBox(height: 22),
            AsyncPrimaryButton(label: l10n.next, onPressed: _review),
          ],
        ),
      ),
    );
  }
}
