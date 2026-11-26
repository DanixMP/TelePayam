import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/utils/validators.dart';
import 'package:university_messenger/core/widgets/async_primary_button.dart';
import 'package:university_messenger/core/widgets/auth_scaffold.dart';
import 'package:university_messenger/core/widgets/auth_steps.dart';
import 'package:university_messenger/core/widgets/inline_error.dart';
import 'package:university_messenger/l10n/localization_extensions.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final phone = normalizeIranianPhone(_phoneController.text);
    await ref.read(authControllerProvider).requestOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider).state;
    return AuthScaffold(
      title: l10n.phoneTitle,
      description: l10n.phoneBody,
      steps: authSteps(l10n),
      currentStep: 0,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _phoneController,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  labelText: l10n.phoneLabel,
                  hintText: l10n.phoneHint,
                  prefixText: '+98  ',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                ),
                validator: (value) =>
                    isValidIranianPhone(value ?? '') ? null : l10n.invalidPhone,
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 14),
            InlineError(message: localizedAuthError(l10n, auth.errorCode)),
            if (auth.errorCode != null) const SizedBox(height: 14),
            AsyncPrimaryButton(
              label: l10n.sendCode,
              isLoading: auth.isBusy,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.termsNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
