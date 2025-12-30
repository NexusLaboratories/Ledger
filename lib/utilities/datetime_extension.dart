extension DateTimeExtension on DateTime {
  int toMillisecondsSinceEpoch() => millisecondsSinceEpoch;

  static DateTime? fromMillisecondsSinceEpoch(int? milliseconds) {
    return milliseconds != null ? DateTime.fromMillisecondsSinceEpoch(milliseconds) : null;
  }
}