import 'package:uuid/uuid.dart';

enum NotificationType {
  budgetExceeded,
  transactionAlert,
  scheduledReminder,
  reportReminder,
  donationReminder,
}

enum NotificationPriority { low, normal, high, urgent }

class Notification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Notification({
    String? id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    DateTime? createdAt,
    this.scheduledFor,
    this.isRead = false,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'notification_id': id,
      'title': title,
      'body': body,
      'type': type.index,
      'priority': priority.index,
      'created_at': createdAt.millisecondsSinceEpoch,
      'scheduled_for': scheduledFor?.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'metadata': metadata?.toString(),
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic>? parsedMetadata;
    if (map['metadata'] != null) {
      // For simplicity, we'll store metadata as JSON string in DB
      // In a real implementation, you'd use json.decode here
      parsedMetadata = {};
    }

    return Notification(
      id: map['notification_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: NotificationType.values[map['type'] as int],
      priority: NotificationPriority.values[map['priority'] as int],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      scheduledFor: map['scheduled_for'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['scheduled_for'] as int)
          : null,
      isRead: (map['is_read'] as int) == 1,
      metadata: parsedMetadata,
    );
  }

  Notification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? createdAt,
    DateTime? scheduledFor,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Notification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}
