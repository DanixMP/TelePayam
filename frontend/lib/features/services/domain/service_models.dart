enum ServiceRequestStatus {
  draft('draft'),
  submitted('submitted'),
  inReview('in_review'),
  needsInfo('needs_info'),
  approved('approved'),
  rejected('rejected'),
  readyForPickup('ready_for_pickup'),
  deliveredDigitally('delivered_digitally'),
  completed('completed'),
  cancelled('cancelled'),
  unknown('unknown');

  const ServiceRequestStatus(this.wireValue);

  final String wireValue;

  static ServiceRequestStatus fromJson(Object? value) {
    final wireValue = value?.toString();
    return ServiceRequestStatus.values.firstWhere(
      (status) => status.wireValue == wireValue,
      orElse: () => ServiceRequestStatus.unknown,
    );
  }
}

const allowedStaffStatusTransitions =
    <ServiceRequestStatus, List<ServiceRequestStatus>>{
      ServiceRequestStatus.submitted: [ServiceRequestStatus.inReview],
      ServiceRequestStatus.inReview: [
        ServiceRequestStatus.needsInfo,
        ServiceRequestStatus.approved,
        ServiceRequestStatus.rejected,
      ],
      ServiceRequestStatus.needsInfo: [ServiceRequestStatus.inReview],
      ServiceRequestStatus.approved: [
        ServiceRequestStatus.readyForPickup,
        ServiceRequestStatus.deliveredDigitally,
        ServiceRequestStatus.completed,
      ],
      ServiceRequestStatus.readyForPickup: [ServiceRequestStatus.completed],
      ServiceRequestStatus.deliveredDigitally: [ServiceRequestStatus.completed],
    };

class ServiceFieldDefinition {
  const ServiceFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    this.description,
    this.placeholder,
    this.options = const [],
    this.initialValue,
  });

  factory ServiceFieldDefinition.fromEntry(String key, Object? schema) {
    if (schema is Map) {
      final map = _stringMap(schema);
      return ServiceFieldDefinition(
        key: key,
        label: (map['label'] ?? map['title'])?.toString() ?? _humanize(key),
        type: (map['type'] ?? map['format'] ?? 'text').toString().toLowerCase(),
        required: map['required'] is bool ? map['required'] as bool : true,
        description: (map['description'] ?? map['help_text'])?.toString(),
        placeholder: map['placeholder']?.toString(),
        options: _options(map['options'] ?? map['choices'] ?? map['enum']),
        initialValue: (map['default'] ?? map['initial'])?.toString(),
      );
    }
    if (schema is List) {
      return ServiceFieldDefinition(
        key: key,
        label: _humanize(key),
        type: 'select',
        required: true,
        options: _options(schema),
      );
    }
    final value = schema?.toString().trim() ?? '';
    const types = {
      'text',
      'string',
      'multiline',
      'textarea',
      'number',
      'integer',
      'decimal',
      'date',
      'boolean',
      'bool',
      'select',
      'email',
      'phone',
    };
    return ServiceFieldDefinition(
      key: key,
      label: value.isNotEmpty && !types.contains(value.toLowerCase())
          ? value
          : _humanize(key),
      type: types.contains(value.toLowerCase()) ? value.toLowerCase() : 'text',
      required: true,
    );
  }

  final String key;
  final String label;
  final String type;
  final bool required;
  final String? description;
  final String? placeholder;
  final List<String> options;
  final String? initialValue;

  bool get isBoolean => type == 'boolean' || type == 'bool';
  bool get isSelect => options.isNotEmpty;
  bool get isDate => type == 'date';
  bool get isMultiline => type == 'multiline' || type == 'textarea';
  bool get isNumeric =>
      type == 'number' || type == 'integer' || type == 'decimal';
}

class ServiceType {
  const ServiceType({
    required this.id,
    required this.name,
    required this.requiredFields,
    required this.requiredDocuments,
    required this.assigneeDepartment,
    this.description,
    this.slaHours,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) {
    final fields = _stringMap(json['required_fields']);
    return ServiceType(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString(),
      requiredFields: fields.entries
          .map(
            (entry) => ServiceFieldDefinition.fromEntry(entry.key, entry.value),
          )
          .toList(),
      requiredDocuments: _stringList(json['required_documents']),
      assigneeDepartment: json['assignee_dept']?.toString() ?? '',
      slaHours: (json['sla_hours'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;
  final String? description;
  final List<ServiceFieldDefinition> requiredFields;
  final List<String> requiredDocuments;
  final String assigneeDepartment;
  final int? slaHours;
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.studentId,
    required this.serviceTypeId,
    required this.status,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    this.assignedStaffId,
    this.verificationCode,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) => ServiceRequest(
    id: json['id'].toString(),
    studentId: json['student_id'].toString(),
    serviceTypeId: json['service_type_id'].toString(),
    status: ServiceRequestStatus.fromJson(json['status']),
    assignedStaffId: json['assigned_staff_id']?.toString(),
    data: _stringMap(json['data']),
    verificationCode: json['verification_code']?.toString(),
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  final String id;
  final String studentId;
  final String serviceTypeId;
  final ServiceRequestStatus status;
  final String? assignedStaffId;
  final Map<String, dynamic> data;
  final String? verificationCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAssigned => assignedStaffId?.isNotEmpty == true;
  bool get canCancel => status == ServiceRequestStatus.submitted && !isAssigned;
}

class ServiceRequestEvent {
  const ServiceRequestEvent({
    required this.id,
    required this.actorId,
    required this.kind,
    required this.createdAt,
    this.note,
  });

  factory ServiceRequestEvent.fromJson(Map<String, dynamic> json) =>
      ServiceRequestEvent(
        id: json['id'].toString(),
        actorId: json['actor_id'].toString(),
        kind: json['kind'].toString(),
        note: json['note']?.toString(),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String actorId;
  final String kind;
  final String? note;
  final DateTime createdAt;
}

class ServiceRequestDocument {
  const ServiceRequestDocument({
    required this.id,
    required this.mediaId,
    required this.kind,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory ServiceRequestDocument.fromJson(Map<String, dynamic> json) =>
      ServiceRequestDocument(
        id: json['id'].toString(),
        mediaId: json['media_id'].toString(),
        kind: json['kind'].toString(),
        uploadedBy: json['uploaded_by'].toString(),
        createdAt: _date(json['created_at']),
      );

  final String id;
  final String mediaId;
  final String kind;
  final String uploadedBy;
  final DateTime createdAt;
}

class ServiceRequestDetail extends ServiceRequest {
  const ServiceRequestDetail({
    required super.id,
    required super.studentId,
    required super.serviceTypeId,
    required super.status,
    required super.data,
    required super.createdAt,
    required super.updatedAt,
    required this.timeline,
    required this.documents,
    super.assignedStaffId,
    super.verificationCode,
    this.resultDocument,
  });

  factory ServiceRequestDetail.fromJson(Map<String, dynamic> json) {
    final request = ServiceRequest.fromJson(json);
    return ServiceRequestDetail(
      id: request.id,
      studentId: request.studentId,
      serviceTypeId: request.serviceTypeId,
      status: request.status,
      assignedStaffId: request.assignedStaffId,
      data: request.data,
      verificationCode: request.verificationCode,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
      timeline: _mapList(
        json['timeline'],
      ).map(ServiceRequestEvent.fromJson).toList(),
      documents: _mapList(
        json['documents'],
      ).map(ServiceRequestDocument.fromJson).toList(),
      resultDocument: json['result_document'] is Map
          ? ServiceRequestDocument.fromJson(_stringMap(json['result_document']))
          : null,
    );
  }

  final List<ServiceRequestEvent> timeline;
  final List<ServiceRequestDocument> documents;
  final ServiceRequestDocument? resultDocument;
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.attachmentId,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: json['id'].toString(),
    senderId: json['sender_id'].toString(),
    body: json['body'].toString(),
    attachmentId: json['attachment_id']?.toString(),
    createdAt: _date(json['created_at']),
  );

  final String id;
  final String senderId;
  final String body;
  final String? attachmentId;
  final DateTime createdAt;
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is! Map) return {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return [];
  return value.whereType<Map>().map(_stringMap).toList();
}

List<String> _stringList(Object? value) {
  if (value is! List) return [];
  return value.map((item) => item.toString()).toList();
}

List<String> _options(Object? value) {
  if (value is Map) return value.keys.map((key) => key.toString()).toList();
  return _stringList(value);
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

String _humanize(String value) {
  final spaced = value
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .trim();
  if (spaced.isEmpty) return value;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}
