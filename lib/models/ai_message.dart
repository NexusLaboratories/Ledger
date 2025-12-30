class AiMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? chartData;
  final String? chartType; // 'bar', 'pie', 'line'

  AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.chartData,
    this.chartType,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (chartData != null) 'chartData': chartData,
      if (chartType != null) 'chartType': chartType,
    };
  }

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    // Safely convert chartData
    Map<String, dynamic>? chartData;
    if (json['chartData'] != null) {
      if (json['chartData'] is Map<String, dynamic>) {
        chartData = json['chartData'] as Map<String, dynamic>;
      } else if (json['chartData'] is Map) {
        // Handle case where it's a Map but not Map<String, dynamic>
        chartData = Map<String, dynamic>.from(json['chartData'] as Map);
      }
    }

    return AiMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      chartData: chartData,
      chartType: json['chartType'] as String?,
    );
  }
}
