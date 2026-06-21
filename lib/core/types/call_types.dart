// Call data types and structures for monitoring app

enum CallType {
  incoming,
  outgoing,
  missed,
}

enum CallState {
  idle,
  ringing,
  offhook,
}

class CallData {
  final String phoneNumber;
  final String? contactName;
  final CallType callType;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds
  final bool isVideoCall;
  final int? simSlot;
  final bool isConference;
  final String deviceId;

  const CallData({
    required this.phoneNumber,
    this.contactName,
    required this.callType,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.isVideoCall = false,
    this.simSlot,
    this.isConference = false,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'contact_name': contactName,
      'call_type': callType.name,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime?.toUtc().toIso8601String(),
      'duration': duration,
      'is_video_call': isVideoCall,
      'sim_slot': simSlot,
      'is_conference': isConference,
      'device_id': deviceId,
    };
  }

  factory CallData.fromJson(Map<String, dynamic> json) {
    return CallData(
      phoneNumber: json['phone_number'] as String,
      contactName: json['contact_name'] as String?,
      callType: CallType.values.firstWhere(
        (e) => e.name == json['call_type'],
        orElse: () => CallType.missed,
      ),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time'] as String) : null,
      duration: json['duration'] as int,
      isVideoCall: json['is_video_call'] as bool? ?? false,
      simSlot: json['sim_slot'] as int?,
      isConference: json['is_conference'] as bool? ?? false,
      deviceId: json['device_id'] as String,
    );
  }
}

class CallEvent {
  final String eventType;
  final CallData callData;
  final DateTime timestamp;

  const CallEvent({
    required this.eventType,
    required this.callData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'call_data': callData.toJson(),
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}