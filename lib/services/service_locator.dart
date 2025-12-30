import 'package:get_it/get_it.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/database/account_db_service.dart';
import 'package:ledger/services/database/transaction_db_service.dart';
import 'package:ledger/services/database/category_db_service.dart';
import 'package:ledger/services/database/tag_db_service.dart';
import 'package:ledger/services/database/budget_db_service.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/transaction_service.dart';
import 'package:ledger/services/tag_service.dart';
import 'package:ledger/services/category_service.dart';
import 'package:ledger/services/transaction_item_service.dart';
import 'package:ledger/services/transaction_tag_service.dart';
import 'package:ledger/services/theme_service.dart';
import 'package:ledger/services/notification_service.dart';
import 'package:ledger/services/search_service.dart';
import 'package:ledger/services/budget_service.dart';
import 'package:ledger/services/balance_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // Register DB services
  getIt.registerLazySingleton<AccountDBService>(() => AccountDBService());
  getIt.registerLazySingleton<TransactionDBService>(
    () => TransactionDBService(),
  );
  getIt.registerLazySingleton<CategoryDBService>(() => CategoryDBService());
  getIt.registerLazySingleton<TagDBService>(() => TagDBService());
  getIt.registerLazySingleton<BudgetDBService>(() => BudgetDBService());

  // Register business logic services
  getIt.registerLazySingleton<AccountService>(() => AccountService());
  getIt.registerLazySingleton<BalanceService>(() => BalanceService());
  getIt.registerLazySingleton<TransactionService>(() => TransactionService());
  getIt.registerLazySingleton<TagService>(() => TagService());
  getIt.registerLazySingleton<CategoryService>(() => CategoryService());
  getIt.registerLazySingleton<TransactionItemService>(
    () => TransactionItemService(),
  );
  getIt.registerLazySingleton<TransactionTagService>(
    () => TransactionTagService(),
  );
  getIt.registerLazySingleton<ThemeService>(() => ThemeService());
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<SearchService>(() => SearchService());
  getIt.registerLazySingleton<BudgetService>(() => BudgetService());
}
