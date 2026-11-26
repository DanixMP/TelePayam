import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/features/services/data/services_api.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';

final servicesApiProvider = Provider<ServicesApi>(
  (ref) => ServicesApi(ref.watch(apiClientProvider)),
);

final serviceCatalogProvider = FutureProvider.autoDispose<List<ServiceType>>(
  (ref) => ref.watch(servicesApiProvider).catalog(),
);

final serviceRequestsProvider =
    FutureProvider.autoDispose<List<ServiceRequest>>(
      (ref) => ref.watch(servicesApiProvider).requests(),
    );

final serviceRequestDetailProvider = FutureProvider.autoDispose
    .family<ServiceRequestDetail, String>(
      (ref, requestId) =>
          ref.watch(servicesApiProvider).requestDetail(requestId),
    );

final ticketMessagesProvider = FutureProvider.autoDispose
    .family<List<TicketMessage>, String>(
      (ref, requestId) => ref.watch(servicesApiProvider).messages(requestId),
    );

final serviceRealtimeSyncProvider = Provider<void>((ref) {
  final subscription = ref.watch(realtimeClientProvider).events.listen((event) {
    if (!event.type.startsWith('service.') && event.type != 'ticket.message') {
      return;
    }
    ref.invalidate(serviceRequestsProvider);
    final data = event.data;
    if (data is! Map) return;
    final requestId = data['request_id']?.toString() ?? data['id']?.toString();
    if (requestId == null) return;
    ref.invalidate(serviceRequestDetailProvider(requestId));
    if (event.type == 'ticket.message') {
      ref.invalidate(ticketMessagesProvider(requestId));
    }
  });
  ref.onDispose(subscription.cancel);
});
