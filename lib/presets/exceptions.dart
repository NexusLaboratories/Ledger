class DatabaseException implements Exception {
  final String message;
  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}

class DatabaseNotOpenException extends DatabaseException {
  DatabaseNotOpenException() : super('Database is not open.');
}

class DatabaseInitializationException extends DatabaseException {
  DatabaseInitializationException()
    : super('Failed to initialize the database.');
}

class TableCreationException extends DatabaseException {
  TableCreationException(String tableName)
    : super('Failed to create table "$tableName".');
}

class DatabaseQueryException extends DatabaseException {
  DatabaseQueryException(String message) : super('Query failed: $message');
}

class DatabaseInsertException extends DatabaseException {
  DatabaseInsertException(String message) : super('Insert failed: $message');
}

class DatabaseUpdateException extends DatabaseException {
  DatabaseUpdateException(String message) : super('Update failed: $message');
}

class DatabaseDeleteException extends DatabaseException {
  DatabaseDeleteException(String message) : super('Delete failed: $message');
}

class PasswordNotFoundException extends DatabaseException {
  PasswordNotFoundException() : super('Database password not found.');
}

class AccountNotFoundException extends DatabaseException {
  AccountNotFoundException(String accountId)
    : super('Account not found: $accountId');
}

class ServiceException implements Exception {
  final String message;
  final dynamic cause;

  ServiceException(this.message, [this.cause]);

  @override
  String toString() =>
      'ServiceException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class ValidationException extends ServiceException {
  ValidationException(super.message, [super.cause]);
}

class NetworkException extends ServiceException {
  NetworkException(super.message, [super.cause]);
}

class AuthenticationException extends ServiceException {
  AuthenticationException(super.message, [super.cause]);
}

class FileOperationException extends ServiceException {
  FileOperationException(super.message, [super.cause]);
}

class ImportException extends ServiceException {
  ImportException(super.message, [super.cause]);
}

class ExportException extends ServiceException {
  ExportException(super.message, [super.cause]);
}

class ParseException extends ServiceException {
  ParseException(super.message, [super.cause]);
}

class BiometricException extends ServiceException {
  BiometricException(super.message, [super.cause]);
}

class NotificationException extends ServiceException {
  NotificationException(super.message, [super.cause]);
}

class CurrencyConversionException extends ServiceException {
  CurrencyConversionException(super.message, [super.cause]);
}
