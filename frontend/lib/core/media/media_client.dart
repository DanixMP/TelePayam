import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:university_messenger/core/media/media_save.dart';
import 'package:university_messenger/core/network/api_client.dart';
import 'package:university_messenger/core/network/api_exception.dart';

class MediaResource {
  const MediaResource({
    required this.id,
    required this.kind,
    required this.mime,
    required this.size,
    required this.status,
    this.originalName,
    this.width,
    this.height,
    this.duration,
  });

  factory MediaResource.fromJson(Map<String, dynamic> json) => MediaResource(
    id: json['id'].toString(),
    kind: json['kind']?.toString() ?? 'file',
    mime: json['mime']?.toString() ?? 'application/octet-stream',
    size: (json['size'] as num?)?.toInt() ?? 0,
    status: json['status']?.toString() ?? 'ready',
    originalName: json['original_name']?.toString(),
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
    duration: (json['duration'] as num?)?.toDouble(),
  );

  final String id;
  final String kind;
  final String mime;
  final int size;
  final String status;
  final String? originalName;
  final int? width;
  final int? height;
  final double? duration;
}

class MediaClient {
  const MediaClient(this._api);

  final ApiClient _api;

  Future<MediaResource> upload(
    XFile file, {
    ProgressCallback? onProgress,
  }) async {
    final length = await file.length();
    if (length <= 0 || length > 25 * 1024 * 1024) {
      throw const ApiException(
        'file_too_large',
        'File must be non-empty and 25 MB or less',
      );
    }
    final mime = switch (file.name.split('.').last.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'ogg' || 'opus' => 'audio/ogg',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/media',
      data: FormData.fromMap({
        'file': MultipartFile.fromStream(
          () => file.openRead(),
          length,
          filename: file.name,
          contentType: DioMediaType.parse(mime),
        ),
      }),
      onSendProgress: onProgress,
    );
    return MediaResource.fromJson(response.data!);
  }

  Future<MediaResource> metadata(String mediaId) async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/media/$mediaId/metadata',
    );
    return MediaResource.fromJson(response.data!);
  }

  Future<Uint8List> download(String mediaId) async {
    final response = await _api.dio.get<List<int>>(
      '/media/$mediaId',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<String?> save(
    String mediaId, {
    MediaResource? resource,
    String? fallbackName,
  }) async {
    final metadata = resource ?? await this.metadata(mediaId);
    return saveMediaBytes(
      await download(mediaId),
      metadata.originalName ?? fallbackName ?? '${metadata.kind}-$mediaId',
    );
  }
}
