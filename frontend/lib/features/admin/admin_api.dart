import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:university_messenger/app/providers.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/features/auth/domain/account.dart';

class StudentRequest {
  StudentRequest.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = [
        json['first_name'],
        json['last_name'],
      ].whereType<String>().join(' ').trim(),
      department = json['department'] as String,
      degree = json['degree'] as String,
      universityId = json['university_id'] as String,
      maskedNationalId = json['national_id_masked'] as String;

  final String id, name, department, degree, universityId, maskedNationalId;
}

class AdminApi {
  const AdminApi(this._client);
  final ApiClient _client;

  Future<List<StudentRequest>> pending() async {
    final response = await _client.getList('/admin/approvals');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(StudentRequest.fromJson)
        .toList();
  }

  Future<void> approve(String id) async {
    await _client.post('/admin/approvals/$id', data: {'action': 'approve'});
  }

  Future<void> createAdmin(String phone) async {
    await _client.post('/admin/admins', data: {'phone': phone});
  }
}

final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(apiClientProvider)),
);
final studentRequestsProvider =
    FutureProvider.autoDispose<List<StudentRequest>>((ref) {
      final account = ref.watch(
        authControllerProvider.select((auth) => auth.state.account),
      );
      if (account?.status != AccountStatus.active ||
          account?.role.isAdmin != true) {
        return [];
      }
      return ref.watch(adminApiProvider).pending();
    });
