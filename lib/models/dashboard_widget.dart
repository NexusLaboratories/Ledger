enum WidgetType {
  recentTransactions,
  spendingByCategory,
  accountBalances,
  budgetProgress,
}

class DashboardWidget {
  final String id;
  final WidgetType type;
  final Map<String, dynamic> config;
  final bool isEnabled;

  DashboardWidget({
    String? id,
    required this.type,
    this.config = const {},
    this.isEnabled = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'config': config,
      'isEnabled': isEnabled,
    };
  }

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['id'] as String,
      type: WidgetType.values[json['type'] as int],
      config: json['config'] as Map<String, dynamic>? ?? {},
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  DashboardWidget copyWith({
    String? id,
    WidgetType? type,
    Map<String, dynamic>? config,
    bool? isEnabled,
  }) {
    return DashboardWidget(
      id: id ?? this.id,
      type: type ?? this.type,
      config: config ?? this.config,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}
