/// Utility class to provide singleton factory pattern for services.
/// Allows creating test instances with injected dependencies while maintaining
/// a singleton for production use.
class SingletonFactory<T> {
  static final Map<Type, dynamic> _instances = {};

  /// Factory method that returns a singleton if no dependencies are provided,
  /// or a new instance if dependencies are injected (for testing).
  static T getInstance<T>(
    T Function() createDefault,
    T Function() createWithDeps,
    bool hasDeps,
  ) {
    if (hasDeps) {
      return createWithDeps();
    }
    return _instances[T] ??= createDefault();
  }
}