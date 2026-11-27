import 'dart:async';

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

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  var _seconds = 0;

  @override
  void initState() {
    super.initState();
    _seconds = ref.read(authControllerProvider).state.retryAfter;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    if (_codeController.text.length != 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidCode)));
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(authControllerProvider)
        .verifyOtp(asciiDigits(_codeController.text));
  }

  Future<void> _resend() async {
    final controller = ref.read(authControllerProvider);
    final phone = controller.state.phone;
    if (phone == null) return;
    if (await controller.requestOtp(phone) && mounted) {
      setState(() => _seconds = controller.state.retryAfter);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = ref.watch(authControllerProvider);
    final auth = controller.state;
    final phone = auth.phone ?? '';
    return AuthScaffold(
      title: l10n.otpTitle,
      description: l10n.otpBody('\u2066$phone\u2069'),
      steps: authSteps(l10n),
      currentStep: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextField(
              controller: _codeController,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9۰-۹٠-٩]')),
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l10n.codeLabel,
                prefixIcon: const Icon(Icons.password_rounded),
                counterText: '',
              ),
              maxLength: 6,
              onSubmitted: (_) => _verify(),
            ),
          ),
          if (auth.developmentCode != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l10n.developmentCode(auth.developmentCode!),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          InlineError(message: localizedAuthError(l10n, auth.errorCode)),
          if (auth.errorCode != null) const SizedBox(height: 14),
          AsyncPrimaryButton(
            label: l10n.verify,
            isLoading: auth.isBusy,
            onPressed: _verify,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _seconds == 0 && !auth.isBusy ? _resend : null,
            child: Text(
              _seconds == 0 ? l10n.resendCode : l10n.resendIn(_seconds),
            ),
          ),
          TextButton(
            onPressed: auth.isBusy ? null : controller.restartPhoneEntry,
            child: Text(l10n.changePhone),
          ),
        ],
      ),
    );
  }
}
