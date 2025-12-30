import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/logger_service.dart';

abstract class AbstractBalanceService {
  Future<void> applyTransactionToBalance(Transaction transaction);
  Future<void> revertTransactionFromBalance(Transaction transaction);
}

class BalanceService implements AbstractBalanceService {
  BalanceService._internal(this._accountService);

  static BalanceService? _instance;
  factory BalanceService({AccountService? accountService}) {
    // If an accountService is explicitly provided, always create a new instance
    // This allows tests to inject their own AccountService
    if (accountService != null) {
      return BalanceService._internal(accountService);
    }
    // Otherwise, use singleton pattern
    _instance ??= BalanceService._internal(AccountService());
    return _instance!;
  }

  final AccountService _accountService;

  @override
  Future<void> applyTransactionToBalance(Transaction transaction) async {
    final accounts = await _accountService.fetchAccounts(forceRefetch: true);
    final account = accounts
        .where((acc) => acc?.id == transaction.accountId)
        .firstOrNull;
    if (account == null) {
      LoggerService.e(
        'Account not found for transaction: ${transaction.accountId}',
      );
      // Do not throw here to keep migrations and transaction creation robust
      // in environments where accounts may not be present (e.g., migration tests)
      return;
    }
    final newBalance = transaction.type == TransactionType.income
        ? account.balance + transaction.amount
        : account.balance - transaction.amount;
    final updatedAccount = account.copyWith(balance: newBalance);
    await _accountService.updateAccount(updatedAccount);
  }

  @override
  Future<void> revertTransactionFromBalance(Transaction transaction) async {
    final accounts = await _accountService.fetchAccounts(forceRefetch: true);
    final account = accounts
        .where((acc) => acc?.id == transaction.accountId)
        .firstOrNull;
    if (account == null) {
      LoggerService.w(
        'Account not found when reverting transaction: ${transaction.accountId}',
      );
      return;
    }
    final newBalance = transaction.type == TransactionType.income
        ? account.balance - transaction.amount
        : account.balance + transaction.amount;
    final updatedAccount = account.copyWith(balance: newBalance);
    await _accountService.updateAccount(updatedAccount);
  }
}
