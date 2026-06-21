// SMS data types and structures for monitoring app

enum MessageType {
  sms,
  mms,
}

enum MessageDirection {
  incoming,
  outgoing,
}

enum MessageStatus {
  sent,
  delivered,
  failed,
  pending,
}

class SmsData {
  final String messageId;
  final MessageType messageType;
  final MessageDirection direction;
  final String sender;
  final String? senderName;
  final String recipient;
  final String? recipientName;
  final String body;
  final DateTime sentAt;
  final DateTime receivedAt;
  final String? conversationId;
  final bool hasAttachment;
  final MessageStatus status;
  final String deviceId;

  const SmsData({
    required this.messageId,
    required this.messageType,
    required this.direction,
    required this.sender,
    this.senderName,
    required this.recipient,
    this.recipientName,
    required this.body,
    required this.sentAt,
    required this.receivedAt,
    this.conversationId,
    this.hasAttachment = false,
    required this.status,
    required this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'message_type': messageType.name,
      'direction': direction.name,
      'sender': sender,
      'sender_name': senderName,
      'recipient': recipient,
      'recipient_name': recipientName,
      'body': body,
      'sent_at': sentAt.toUtc().toIso8601String(),
      'received_at': receivedAt.toUtc().toIso8601String(),
      'conversation_id': conversationId,
      'has_attachment': hasAttachment,
      'status': status.name,
      'device_id': deviceId,
    };
  }

  factory SmsData.fromJson(Map<String, dynamic> json) {
    return SmsData(
      messageId: json['message_id'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.sms,
      ),
      direction: MessageDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => MessageDirection.incoming,
      ),
      sender: json['sender'] as String,
      senderName: json['sender_name'] as String?,
      recipient: json['recipient'] as String,
      recipientName: json['recipient_name'] as String?,
      body: json['body'] as String,
      sentAt: DateTime.parse(json['sent_at'] as String),
      receivedAt: DateTime.parse(json['received_at'] as String),
      conversationId: json['conversation_id'] as String?,
      hasAttachment: json['has_attachment'] as bool? ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      deviceId: json['device_id'] as String,
    );
  }
}

class SmsEvent {
  final String eventType;
  final SmsData smsData;
  final DateTime timestamp;

  const SmsEvent({
    required this.eventType,
    required this.smsData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'sms_data': smsData.toJson(),
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

class SmsAttachment {
  final String attachmentId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String? filePath;
  final String? contentUri;

  const SmsAttachment({
    required this.attachmentId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.filePath,
    this.contentUri,
  });

  Map<String, dynamic> toJson() {
    return {
      'attachment_id': attachmentId,
      'file_name': fileName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'file_path': filePath,
      'content_uri': contentUri,
    };
  }
}