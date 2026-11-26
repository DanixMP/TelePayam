import 'package:university_messenger/features/calls/domain/call_models.dart';

abstract final class CallRoutes {
  static const historyName = 'callHistory';
  static const outgoingName = 'outgoingCall';
  static const incomingName = 'incomingCall';
  static const activeName = 'activeCall';

  static const history = '/home/calls';
  static const outgoing = '/home/calls/outgoing';
  static const incoming = '/home/calls/incoming';
  static const active = '/home/calls/active';

  static String outgoingLocation({
    required String conversationId,
    required CallKind kind,
    String? peerName,
  }) => Uri(
    path: outgoing,
    queryParameters: {
      'conversationId': conversationId,
      'kind': kind.name,
      if (peerName != null && peerName.isNotEmpty) 'peerName': peerName,
    },
  ).toString();

  static String incomingLocation({String? callId, String? peerName}) {
    final query = <String, String>{'callId': ?callId};
    if (peerName != null && peerName.isNotEmpty) query['peerName'] = peerName;
    return Uri(path: incoming, queryParameters: query).toString();
  }
}
