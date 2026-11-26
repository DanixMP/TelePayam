import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/app/router.dart';
import 'package:university_messenger/app/theme/app_theme.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/calls/calls_feature.dart';
import 'package:university_messenger/l10n/generated/app_localizations.dart';

class UniversityMessengerApp extends ConsumerWidget {
  const UniversityMessengerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final router = ref.watch(routerProvider);
    final active =
        ref.watch(authControllerProvider).state.account?.status ==
        AccountStatus.active;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'University Messenger',
      routerConfig: router,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      builder: (context, child) {
        if (!active || child == null) return child ?? const SizedBox.shrink();
        final calls = ref.watch(callControllerProvider).state;
        final call = calls.currentCall ?? calls.incomingCall;
        if (call == null ||
            (call.status != CallStatus.ringing &&
                call.status != CallStatus.active)) {
          return child;
        }
        final incoming =
            calls.incomingCall?.id == call.id &&
            calls.currentCall?.id != call.id;
        return Stack(
          children: [
            Positioned.fill(child: child),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.all(12),
                child: Material(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  elevation: 3,
                  borderRadius: BorderRadius.circular(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListTile(
                      leading: Icon(
                        call.kind == CallKind.video
                            ? Icons.videocam_rounded
                            : Icons.call_rounded,
                      ),
                      title: Text(incoming ? 'Incoming call' : 'Active call'),
                      subtitle: Text(
                        call.status == CallStatus.active
                            ? 'Connected'
                            : 'Ringing',
                      ),
                      trailing: FilledButton.tonal(
                        onPressed: () => incoming
                            ? router.push(
                                CallRoutes.incomingLocation(callId: call.id),
                              )
                            : router.push(CallRoutes.active),
                        child: Text(incoming ? 'Answer' : 'Return'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
