import 'package:ledger/models/account.dart';
import 'package:ledger/models/search_filter.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';

abstract class AbstractSearchService {
  Future<List<Transaction>> searchTransactions(SearchFilter filter);
  Future<List<Account>> searchAccounts(SearchFilter filter);
}

class SearchService implements AbstractSearchService {
  final TransactionDBService _transactionDBService = TransactionDBService();
  final AccountDBService _accountDBService = AccountDBService();

  @override
  Future<List<Transaction>> searchTransactions(SearchFilter filter) async {
    List<Map<String, dynamic>> rawTransactions = await _transactionDBService
        .fetchAll();

    List<Transaction> transactions = rawTransactions
        .map((map) => Transaction.fromMap(map))
        .toList();

    // Apply filters
    transactions = transactions.where((transaction) {
      // Query filter (search in title and description)
      if (filter.query != null && filter.query!.isNotEmpty) {
        final query = filter.query!.toLowerCase();
        final titleMatch = transaction.title.toLowerCase().contains(query);
        final descriptionMatch =
            transaction.description?.toLowerCase().contains(query) ?? false;
        if (!titleMatch && !descriptionMatch) return false;
      }

      // Date range filter
      if (filter.startDate != null &&
          transaction.date.isBefore(filter.startDate!)) {
        return false;
      }
      if (filter.endDate != null && transaction.date.isAfter(filter.endDate!)) {
        return false;
      }

      // Amount range filter
      if (filter.minAmount != null && transaction.amount < filter.minAmount!) {
        return false;
      }
      if (filter.maxAmount != null && transaction.amount > filter.maxAmount!) {
        return false;
      }

      // Account filter
      if (filter.accountId != null &&
          transaction.accountId != filter.accountId!) {
        return false;
      }

      // Category filter
      if (filter.categoryId != null &&
          transaction.categoryId != filter.categoryId!) {
        return false;
      }

      // Transaction type filter
      if (filter.transactionType != null &&
          transaction.type.index != filter.transactionType!) {
        return false;
      }

      // Tag filter (if tagIds are provided, check if transaction has any of them)
      if (filter.tagIds != null && filter.tagIds!.isNotEmpty) {
        final hasMatchingTag = filter.tagIds!.any(
          (tagId) => transaction.tagIds.contains(tagId),
        );
        if (!hasMatchingTag) return false;
      }

      return true;
    }).toList();

    return transactions;
  }

  @override
  Future<List<Account>> searchAccounts(SearchFilter filter) async {
    List<Map<String, dynamic>> rawAccounts = await _accountDBService.fetchAll();

    List<Account> accounts = rawAccounts
        .map((map) => Account.fromJson(map))
        .toList();

    // Apply filters
    accounts = accounts.where((account) {
      // Query filter (search in name and description)
      if (filter.query != null && filter.query!.isNotEmpty) {
        final query = filter.query!.toLowerCase();
        final nameMatch = account.name.toLowerCase().contains(query);
        final descriptionMatch =
            account.description?.toLowerCase().contains(query) ?? false;
        if (!nameMatch && !descriptionMatch) return false;
      }

      // Account ID filter
      if (filter.accountId != null && account.id != filter.accountId!) {
        return false;
      }

      // Currency filter (if query contains currency)
      if (filter.query != null && filter.query!.isNotEmpty) {
        final query = filter.query!.toLowerCase();
        if (account.currency.toLowerCase().contains(query)) return true;
      }

      return true;
    }).toList();

    return accounts;
  }
}
