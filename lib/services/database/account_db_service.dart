// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:ledger/models/account.dart';

import 'package:ledger/services/database/core_db_service.dart';

abstract class AbstractAccountDBService {
  Future<void> _ensureTableExists();
  Future<void> _createTable();
  Future<List<Map<String, dynamic>>> fetchAll();

  Future<void> createAccount(Account account);
  Future<void> update(Account account);
  Future<void> delete(String accountId);
}

class AccountDBService implements AbstractAccountDBService {
  AccountDBService._privateConstructor();
  static final AccountDBService _instance =
      AccountDBService._privateConstructor();
  factory AccountDBService() => _instance;

  final DatabaseService _dbService = DatabaseService();

  static const String _tableName = 'accounts';
  bool _tableInitialized = false;

  @protected
  Map<String, dynamic> _toMap(account) {
    return {
      'account_id': account.id,
      'user_id': account.userId ?? 'local',
      'currency': account.currency,
      'account_name': account.name,
      'account_description': account.description,
      'balance': account.balance,
      'created_at': account.createdAt.millisecondsSinceEpoch,
      'updated_at': account.updatedAt.millisecondsSinceEpoch,
    };
  }

  // Defining functions ------------------------------------------

  @override
  Future<void> _ensureTableExists() async {
    if (_tableInitialized) return;
    // Ensure DB is open before we check or create tables
    await _dbService.openDB();
    await _createTable();
    _tableInitialized = true;
  }

  @override
  Future<void> _createTable() async {
    // Table creation is now handled by CoreDBService
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAll() async {
    await _ensureTableExists();
    List<Map<String, dynamic>> accountsList = await _dbService.query(
      _tableName,
    );
    return accountsList;
  }

  @override
  Future<void> createAccount(Account account) async {
    await _ensureTableExists();

    await _dbService.insert(_tableName, _toMap(account));
  }

  @override
  Future<void> update(Account account) async {
    await _ensureTableExists();
    await _dbService.update(
      _tableName,
      _toMap(account),
      where: 'account_id = ?',
      whereArgs: [account.id],
    );
  }

  @override
  Future<void> delete(String accountId) async {
    await _ensureTableExists();
    await _dbService.delete(
      _tableName,
      where: 'account_id = ?',
      whereArgs: [accountId],
    );
  }
}
