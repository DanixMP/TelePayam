import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/admin/admin_screen.dart';
import 'package:university_messenger/features/auth/domain/account.dart';
import 'package:university_messenger/features/auth/presentation/auth_controller.dart';
import 'package:university_messenger/features/calls/calls_feature.dart';
import 'package:university_messenger/features/chats/presentation/home_screen.dart';
import 'package:university_messenger/features/communities/communities.dart';
import 'package:university_messenger/features/onboarding/presentation/otp_screen.dart';
import 'package:university_messenger/features/onboarding/presentation/phone_screen.dart';
import 'package:university_messenger/features/onboarding/presentation/splash_screen.dart';
import 'package:university_messenger/features/onboarding/presentation/welcome_screen.dart';
import 'package:university_messenger/features/people/directory_screen.dart';
import 'package:university_messenger/features/people/profile_screen.dart';
import 'package:university_messenger/features/registration/presentation/blocked_screen.dart';
import 'package:university_messenger/features/registration/presentation/pending_screen.dart';
import 'package:university_messenger/features/registration/presentation/professor_profile_screen.dart';
import 'package:university_messenger/features/registration/presentation/registration_review_screen.dart';
import 'package:university_messenger/features/registration/presentation/rejected_screen.dart';
import 'package:university_messenger/features/registration/presentation/student_profile_screen.dart';
import 'package:university_messenger/features/reports/reports.dart';
import 'package:university_messenger/features/services/services.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: auth,
    redirect: (context, state) => _redirect(auth.state, state.uri.path),
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/phone', builder: (_, _) => const PhoneScreen()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpScreen()),
      GoRoute(path: AdminScreen.path, builder: (_, _) => const AdminScreen()),
      GoRoute(path: '/home/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/home/find',
        builder: (_, state) =>
            DirectoryScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
      ),
      GoRoute(
        path: '/register/student',
        builder: (_, _) => const StudentProfileScreen(),
      ),
      GoRoute(
        path: '/home/communities',
        builder: (context, _) => CommunityDiscoverScreen(
          onOpenConversation: (id) => context.go('/home/chat/$id'),
        ),
      ),
      GoRoute(
        path: '/home/communities/create',
        builder: (_, state) => CommunityCreateScreen(
          initialKind: state.uri.queryParameters['kind'] == 'group'
              ? CommunityCreationKind.group
              : CommunityCreationKind.channel,
        ),
      ),
      GoRoute(
        path: '/home/communities/:conversationId',
        builder: (context, state) => CommunityInfoScreen(
          conversationId: state.pathParameters['conversationId']!,
          onOpenConversation: (id) => context.go('/home/chat/$id'),
        ),
      ),
      GoRoute(
        path: '/home/reports',
        builder: (_, _) => const MyReportsScreen(),
      ),
      GoRoute(
        path: '/home/moderation',
        builder: (_, _) => const ModeratorQueueScreen(),
      ),
      ...ServiceRoutes.routes,
      GoRoute(
        path: CallRoutes.history,
        name: CallRoutes.historyName,
        builder: (_, _) => const CallHistoryScreen(),
      ),
      GoRoute(
        path: CallRoutes.outgoing,
        name: CallRoutes.outgoingName,
        builder: (_, state) => OutgoingCallScreen(
          conversationId: state.uri.queryParameters['conversationId'] ?? '',
          kind: CallKind.fromJson(state.uri.queryParameters['kind']),
          peerName: state.uri.queryParameters['peerName'] ?? 'Unknown caller',
        ),
      ),
      GoRoute(
        path: CallRoutes.incoming,
        name: CallRoutes.incomingName,
        builder: (_, state) => IncomingCallScreen(
          callId: state.uri.queryParameters['callId'],
          peerName: state.uri.queryParameters['peerName'] ?? 'Unknown caller',
        ),
      ),
      GoRoute(
        path: CallRoutes.active,
        name: CallRoutes.activeName,
        builder: (_, state) => ActiveCallScreen(
          peerName: state.uri.queryParameters['peerName'] ?? 'Unknown caller',
        ),
      ),
      GoRoute(
        path: '/register/student/review',
        builder: (_, _) =>
            const RegistrationReviewScreen(role: UserRole.student),
      ),
      GoRoute(
        path: '/register/professor',
        builder: (_, _) => const ProfessorProfileScreen(),
      ),
      GoRoute(
        path: '/register/professor/review',
        builder: (_, _) =>
            const RegistrationReviewScreen(role: UserRole.professor),
      ),
      GoRoute(path: '/pending', builder: (_, _) => const PendingScreen()),
      GoRoute(path: '/rejected', builder: (_, _) => const RejectedScreen()),
      GoRoute(path: '/blocked', builder: (_, _) => const BlockedScreen()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'chat/:conversationId',
            builder: (_, state) => HomeScreen(
              selectedConversationId: state.pathParameters['conversationId'],
            ),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

String? _redirect(AuthState auth, String path) {
  switch (auth.stage) {
    case AuthFlowStage.booting:
      return path == '/splash' ? null : '/splash';
    case AuthFlowStage.signedOut:
      if (path == '/welcome' || path == '/phone') return null;
      return '/welcome';
    case AuthFlowStage.codeRequested:
      return path == '/otp' ? null : '/otp';
    case AuthFlowStage.authenticated:
      break;
  }

  final account = auth.account;
  if (account == null) return '/splash';
  switch (account.status) {
    case AccountStatus.pendingProfile:
      final prefix = switch (account.role) {
        UserRole.professor => '/register/professor',
        UserRole.student => '/register/student',
        _ => '/blocked',
      };
      return path.startsWith(prefix) ? null : prefix;
    case AccountStatus.pendingApproval:
      return path == '/pending' ? null : '/pending';
    case AccountStatus.rejected:
      final prefix = switch (account.role) {
        UserRole.professor => '/register/professor',
        UserRole.student => '/register/student',
        _ => '/blocked',
      };
      if (path == '/rejected' || path.startsWith(prefix)) {
        return null;
      }
      return '/rejected';
    case AccountStatus.suspended:
    case AccountStatus.banned:
      return path == '/blocked' ? null : '/blocked';
    case AccountStatus.active:
      if (path == AdminScreen.path && !account.role.isAdmin) return '/home';
      if (path == '/home/find' && !account.role.canChat) return '/home';
      if (path.startsWith('/home/moderation') &&
          account.role != UserRole.moderator) {
        return '/home';
      }
      if (path.startsWith('/home/services') &&
          account.role != UserRole.student &&
          account.role != UserRole.staff) {
        return '/home';
      }
      if (path.startsWith('/home')) return null;
      return account.role.isAdmin ? AdminScreen.path : '/home';
  }
}
