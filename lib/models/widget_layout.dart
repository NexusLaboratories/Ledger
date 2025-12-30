class WidgetLayout {
  final String widgetId;
  final int row;
  final int col;
  final int width;
  final int height;

  WidgetLayout({
    required this.widgetId,
    required this.row,
    required this.col,
    this.width = 1,
    this.height = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'widgetId': widgetId,
      'row': row,
      'col': col,
      'width': width,
      'height': height,
    };
  }

  factory WidgetLayout.fromJson(Map<String, dynamic> json) {
    return WidgetLayout(
      widgetId: json['widgetId'] as String,
      row: json['row'] as int,
      col: json['col'] as int,
      width: json['width'] as int? ?? 1,
      height: json['height'] as int? ?? 1,
    );
  }

  WidgetLayout copyWith({
    String? widgetId,
    int? row,
    int? col,
    int? width,
    int? height,
  }) {
    return WidgetLayout(
      widgetId: widgetId ?? this.widgetId,
      row: row ?? this.row,
      col: col ?? this.col,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
