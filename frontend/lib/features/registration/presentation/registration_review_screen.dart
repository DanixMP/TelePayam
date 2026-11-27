import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/utils/validators.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/core/widgets/inline_error.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class RegistrationReviewScreen extends ConsumerWidget {
  const RegistrationReviewScreen({required this.role, super.key});

  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(authControllerProvider);
    final state = controller.state;
    final isStudent = role == UserRole.student;
    final student = state.studentDraft;
    final professor = state.professorDraft;
    final validDraft = isStudent ? student != null : professor != null;
    final editPath = isStudent ? '/register/student' : '/register/professor';

    return AuthScaffold(
      title: l10n.reviewTitle,
      description: isStudent
          ? l10n.studentReviewBody
          : l10n.professorReviewBody,
      steps: authSteps(l10n),
      currentStep: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (validDraft) ...[
            _ReviewRow(
              label: l10n.firstName,
              value: isStudent ? student!.firstName : professor!.firstName,
            ),
            _ReviewRow(
              label: l10n.lastName,
              value: isStudent ? student!.lastName : professor!.lastName,
            ),
            if (isStudent) ...[
              _ReviewRow(
                label: l10n.nationalId,
                value: maskNationalId(student!.nationalId),
                forceLtr: true,
              ),
              _ReviewRow(
                label: l10n.degree,
                value: localizedDegree(l10n, student.degree),
              ),
              _ReviewRow(label: l10n.department, value: student.department),
              _ReviewRow(
                label: l10n.universityId,
                value: student.universityId,
                forceLtr: true,
              ),
            ] else ...[
              _ReviewRow(label: l10n.department, value: professor!.department),
              _ReviewRow(label: l10n.academicTitle, value: professor.title),
            ],
          ] else
            Text(l10n.genericError),
          const SizedBox(height: 14),
          InlineError(message: localizedAuthError(l10n, state.errorCode)),
          if (state.errorCode != null) const SizedBox(height: 14),
          AsyncPrimaryButton(
            label: isStudent ? l10n.submitForReview : l10n.activateProfile,
            isLoading: state.isBusy,
            onPressed: validDraft
                ? () async {
                    if (isStudent) {
                      await controller.submitStudentProfile();
                    } else {
                      await controller.submitProfessorProfile();
                    }
                  }
                : null,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: state.isBusy ? null : () => context.go(editPath),
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.edit),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.forceLtr = false,
  });

  final String label;
  final String value;
  final bool forceLtr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Directionality(
              textDirection: forceLtr
                  ? TextDirection.ltr
                  : Directionality.of(context),
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
