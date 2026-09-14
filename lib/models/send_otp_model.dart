import 'dart:developer';

class SendOtpRequest {
  final String mobileNumber;

  SendOtpRequest({required this.mobileNumber});

  Map<String, dynamic> toJson() {
    log("request numebr >> $mobileNumber");
    return {'mobileNumber': mobileNumber};
  }
}

class SendOtpResponse {
  final bool success;
  final SendOtpData? data;
  final String? timestamp;
  final String? exception;

  SendOtpResponse({
    required this.success,
    this.data,
    this.timestamp,
    this.exception,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    log("jsoncheck ??>> $json");
    return SendOtpResponse(
      success: json['success'] ?? false,
      data: json['data'] != null
          ? SendOtpData.fromJson(Map<String, dynamic>.from(json['data']))
          : null,
      timestamp: json['timestamp']?.toString(),
      exception: json['exception']?.toString(),
    );
  }
}

class SendOtpData {
  final String providerRef;
  final int expiresInSeconds;
  final String flow;

  SendOtpData({
    required this.providerRef,
    required this.expiresInSeconds,
    required this.flow,
  });

  factory SendOtpData.fromJson(Map<String, dynamic> json) {
    return SendOtpData(
      providerRef: json['providerRef'] ?? '',
      expiresInSeconds: json['expiresInSeconds'] ?? 300,
      flow: json['flow'] ?? '',
    );
  }
}

class VerifyOtpRequest {
  final String mobileNumber;
  final String otp;
  final String purpose;
  final String providerRef;

  VerifyOtpRequest({
    required this.mobileNumber,
    required this.otp,
    required this.purpose,
    required this.providerRef,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobileNumber': mobileNumber,
      'otp': otp,
      'purpose': purpose,
      'providerRef': providerRef,
    };
  }
}

class VerifyOtpResponse {
  final bool success;
  final int? statusCode;
  final String? code;
  final String? message;
  final String? timestamp;
  final Map<String, dynamic>? data;

  VerifyOtpResponse({
    required this.success,
    this.statusCode,
    this.code,
    this.message,
    this.timestamp,
    this.data,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    log("check verify data >> $json");
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      statusCode: json['statusCode'],
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      timestamp: json['timestamp']?.toString(),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }
}
