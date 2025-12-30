import 'package:ledger/models/account.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/singleton_service_mixin.dart';
import 'package:ledger/services/logger_service.dart';
import 'package:ledger/services/data_refresh_service.dart';

abstract class AbstractAccountService {
  Future<double> fetchNetWorth({String? inCurrency});
  Future<List<Account?>> fetchAccounts({bool forceRefetch = false});
  Future<void> createAccount(
    String accountName,
    String? accountDescription, {
    String? currency,
    String? iconId,
  });
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String accountId);
  dynamic init();
}

class AccountService implements AbstractAccountService {
  // Internal constructor used for creating test instances with
  // injected dependencies.
  AccountService._internal(this._accountDBService);

  factory AccountService({AbstractAccountDBService? accountDBService}) {
    final hasDeps = accountDBService != null;

    return SingletonFactory.getInstance(
      () => AccountService._internal(AccountDBService()),
      () => AccountService._internal(accountDBService!),
      hasDeps,
    );
  }

  final AbstractAccountDBService _accountDBService;

  // In-memory cache of Account objects; make this per-instance to avoid
  // global state during tests.
  List<Account?> _accounts = [];

  @override
  init() {
    fetchAccounts();
  }

  @override
  Future<void> createAccount(
    String accountName,
    String? accountDescription, {
    String? currency,
    String? iconId,
  }) async {
    LoggerService.i(
      'Creating account: "$accountName" | Currency: ${currency ?? "default"} | Icon: ${iconId ?? "none"}',
    );
    String? accountCurrency;
    try {
      // Use provided currency, otherwise, default to the app preference
      accountCurrency =
          currency ?? await UserPreferenceService.getDefaultCurrency();
      LoggerService.i('Resolved currency: $accountCurrency');
      Account newAccount = Account(
        name: accountName,
        description: accountDescription,
        currency: accountCurrency,
        iconId: iconId,
      );

      // Fetch all accounts first (if we need to fetch from database)
      await fetchAccounts();

      // Add new account to RAM
      _accounts.add(newAccount);

      await _accountDBService.createAccount(newAccount);
      DataRefreshService().notifyAccountsChanged();
      LoggerService.i('Account created successfully: ${newAccount.id}');
    } catch (e, stackTrace) {
      LoggerService.e(
        'Failed to create account: $accountName | Currency: ${accountCurrency ?? currency ?? "unknown"}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Account?>> fetchAccounts({bool forceRefetch = false}) async {
    try {
      if (_accounts.isNotEmpty && !forceRefetch) {
        return _accounts;
      } else {
        final accountsList = await _accountDBService.fetchAll();
        final defaultCurrency =
            await UserPreferenceService.getDefaultCurrency();

        // Ensure all accounts use the user's selected default currency.
        // Create new maps instead of modifying the unmodifiable maps from DB.
        final modifiableAccountsList = accountsList.map((json) {
          return Map<String, dynamic>.from(json)
            ..['currency'] = defaultCurrency;
        }).toList();

        _accounts = modifiableAccountsList
            .map((json) => Account.fromJson(json))
            .toList();

        return _accounts;
      }
    } catch (e, stackTrace) {
      LoggerService.e(
        'AccountService: failed to fetch accounts',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<double> fetchNetWorth({String? inCurrency}) async {
    try {
      // With multi-currency removed, all account balances are assumed to be
      // in the user's selected default currency. We sum balances directly.
      await fetchAccounts();

      if (_accounts.isEmpty) {
        return 0;
      }

      double total = 0.0;
      for (final account in _accounts) {
        if (account != null) {
          total += account.balance;
        }
      }

      return total;
    } catch (e, stackTrace) {
      LoggerService.e(
        'AccountService: failed to fetch net worth',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateAccount(Account account) async {
    try {
      LoggerService.d('AccountService: updating account ${account.id}');
      await _accountDBService.update(account);

      final index = _accounts.indexWhere((acc) => acc!.id == account.id);
      if (index != -1) {
        _accounts[index] = account;
      }
      DataRefreshService().notifyAccountsChanged();
    } catch (e, stackTrace) {
      LoggerService.e('Failed to update account: ${account.id}', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    try {
      await _accountDBService.delete(accountId);
      _accounts.removeWhere((account) => account!.id == accountId);
      DataRefreshService().notifyAccountsChanged();
    } catch (e, stackTrace) {
      LoggerService.e('Failed to delete account: $accountId', e, stackTrace);
      rethrow;
    }
  }
}
