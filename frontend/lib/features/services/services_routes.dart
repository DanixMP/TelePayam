import 'package:go_router/go_router.dart';
import 'package:university_messenger/features/services/presentation/service_request_detail_screen.dart';
import 'package:university_messenger/features/services/presentation/service_request_wizard_screen.dart';
import 'package:university_messenger/features/services/presentation/services_home_screen.dart';
import 'package:university_messenger/features/services/presentation/ticket_chat_screen.dart';

class ServiceRoutes {
  const ServiceRoutes._();

  static const root = '/home/services';

  static String newRequest(String serviceTypeId) => '$root/new/$serviceTypeId';

  static String requestDetail(String requestId) => '$root/requests/$requestId';

  static String ticketChat(String requestId) =>
      '${requestDetail(requestId)}/chat';

  static final List<RouteBase> routes = [
    GoRoute(
      path: root,
      builder: (_, _) => const ServicesHomeScreen(),
      routes: [
        GoRoute(
          path: 'new/:serviceTypeId',
          builder: (_, state) => ServiceRequestWizardScreen(
            serviceTypeId: state.pathParameters['serviceTypeId']!,
          ),
        ),
        GoRoute(
          path: 'requests/:requestId',
          builder: (_, state) => ServiceRequestDetailScreen(
            requestId: state.pathParameters['requestId']!,
          ),
          routes: [
            GoRoute(
              path: 'chat',
              builder: (_, state) => TicketChatScreen(
                requestId: state.pathParameters['requestId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
