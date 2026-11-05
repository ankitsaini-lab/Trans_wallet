class PrivacyPolicyResponse {
  final bool success;
  final String? code;
  final String? message;
  final PrivacyPolicyData? data;
  final String? timestamp;

  PrivacyPolicyResponse({
    required this.success,
    this.code,
    this.message,
    this.data,
    this.timestamp,
  });

  factory PrivacyPolicyResponse.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyResponse(
      success: json['success'] ?? false,
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      data: json['data'] != null && json['data'] is Map
          ? PrivacyPolicyData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
      timestamp: json['timestamp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'code': code,
      'message': message,
      'data': data?.toJson(),
      'timestamp': timestamp,
    };
  }
}

class PrivacyPolicyData {
  final String title;
  final String contentType;
  final String html;
  final List<PrivacyPolicySection> sections;

  PrivacyPolicyData({
    required this.title,
    required this.contentType,
    required this.html,
    required this.sections,
  });

  factory PrivacyPolicyData.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    List<PrivacyPolicySection> parsedSections = [];
    if (rawSections is List) {
      parsedSections = rawSections
          .whereType<Map>()
          .map(
            (e) => PrivacyPolicySection.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }

    return PrivacyPolicyData(
      title: json['title']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      html: json['html']?.toString() ?? '',
      sections: parsedSections,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'contentType': contentType,
      'html': html,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}

class PrivacyPolicySection {
  final String heading;
  final List<String> paragraphs;
  final List<String> bullets;

  PrivacyPolicySection({
    required this.heading,
    required this.paragraphs,
    required this.bullets,
  });

  factory PrivacyPolicySection.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicySection(
      heading: json['heading']?.toString() ?? '',
      paragraphs:
          (json['paragraphs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      bullets:
          (json['bullets'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'heading': heading, 'paragraphs': paragraphs, 'bullets': bullets};
  }
}
