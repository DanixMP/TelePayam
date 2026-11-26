import 'package:flutter_test/flutter_test.dart';
import 'package:university_messenger/features/calls/domain/call_models.dart';
import 'package:university_messenger/features/chats/domain/chat_models.dart';
import 'package:university_messenger/features/communities/domain/community_models.dart';
import 'package:university_messenger/features/reports/domain/report_models.dart';
import 'package:university_messenger/features/services/domain/service_models.dart';

void main() {
  test('parses a managed professor channel', () {
    final community = CommunityConversation.fromJson({
      'id': 'channel-1',
      'type': 'channel',
      'visibility': 'public',
      'title': 'Algorithms',
      'owner_id': 'professor-1',
      'member_count': 42,
      'last_seq': 8,
      'is_professor_channel': true,
      'settings': {'comments_enabled': true},
      'created_at': '2026-01-01T00:00:00Z',
      'my_role': 'owner',
      'last_read_seq': 8,
      'under_review': false,
    });

    expect(community.type, CommunityType.channel);
    expect(community.isProfessorChannel, isTrue);
    expect(community.canManage, isTrue);
  });

  test('parses rich poll messages and reaction counts', () {
    final message = ChatMessage.fromJson({
      'id': 'message-1',
      'conversation_id': 'conversation-1',
      'seq': 5,
      'sender_id': 'user-1',
      'client_msg_id': 'client-1',
      'type': 'poll',
      'attachment_ids': ['media-1'],
      'reactions': {'👍': 2},
      'poll': {
        'question': 'When?',
        'options': ['Today', 'Tomorrow'],
        'multiple_choice': false,
        'vote_counts': [1, 3],
      },
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(message.poll?.options, ['Today', 'Tomorrow']);
    expect(message.poll?.voteCounts, [1, 3]);
    expect(message.attachmentIds, ['media-1']);
    expect(message.reactions['👍'], 2);
  });

  test('parses report resolution and service request detail', () {
    final report = ReportRecord.fromJson({
      'id': 'report-1',
      'reporter_id': 'user-1',
      'target_type': 'message',
      'target_id': 'message-1',
      'reason': 'spam',
      'status': 'resolved',
      'resolution': 'remove_content: confirmed',
      'created_at': '2026-01-01T00:00:00Z',
    });
    final request = ServiceRequestDetail.fromJson({
      'id': 'request-1',
      'student_id': 'student-1',
      'service_type_id': 'service-1',
      'status': 'delivered_digitally',
      'data': {'semester': 'Fall'},
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-02T00:00:00Z',
      'timeline': [],
      'documents': [],
      'result_document': {
        'id': 'document-1',
        'media_id': 'media-1',
        'kind': 'result',
        'uploaded_by': 'staff-1',
        'created_at': '2026-01-02T00:00:00Z',
      },
    });

    expect(report.resolutionOutcome, ResolutionOutcome.removeContent);
    expect(report.resolutionNote, 'confirmed');
    expect(request.status, ServiceRequestStatus.deliveredDigitally);
    expect(request.resultDocument?.mediaId, 'media-1');
  });

  test('parses an active video call and participants', () {
    final call = CallSession.fromJson({
      'id': 'call-1',
      'conversation_id': 'conversation-1',
      'caller_id': 'user-1',
      'client_call_id': 'client-call-1',
      'kind': 'video',
      'status': 'active',
      'created_at': '2026-01-01T00:00:00Z',
      'participants': [
        {'user_id': 'user-1', 'status': 'accepted'},
        {'user_id': 'user-2', 'status': 'accepted'},
      ],
    });

    expect(call.kind, CallKind.video);
    expect(call.status, CallStatus.active);
    expect(call.peerIdFor('user-1'), 'user-2');
  });
}
