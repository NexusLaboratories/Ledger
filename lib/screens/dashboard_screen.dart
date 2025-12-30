import 'package:flutter/material.dart';
import 'package:ledger/components/ui/layout/custom_app_bar.dart';
import 'package:ledger/components/ui/layout/custom_app_drawer.dart';
import 'package:ledger/components/ui/buttons/custom_button.dart';
import 'package:ledger/components/ui/dialogs/custom_dialog.dart';
import 'package:ledger/components/ui/buttons/custom_floating_action_button.dart';
import 'package:ledger/components/dashboard/dashboard_widget_container.dart';
import 'package:ledger/components/ui/common/search_bar_widget.dart';
import 'package:ledger/components/ui/common/glass_container.dart';
import 'package:ledger/constants/dashboard_constants.dart';
import 'package:ledger/modals/account_form_modal.dart';
import 'package:ledger/modals/transaction_form_modal.dart';
import 'package:ledger/models/account.dart';
import 'package:ledger/models/dashboard_widget.dart';
import 'package:ledger/models/search_filter.dart';
import 'package:ledger/models/transaction.dart';
import 'package:ledger/services/account_service.dart';
import 'package:ledger/services/dashboard_service.dart';
import 'package:ledger/services/database/core_db_service.dart';
import 'package:ledger/services/search_service.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/utilities/currency_formatter.dart';
import 'package:ledger/presets/theme.dart';
import 'package:ledger/screens/account_transactions_screen.dart';
import 'package:ledger/screens/transaction_detail_screen.dart';
import 'package:ledger/presets/date_formats.dart';
import 'package:ledger/utilities/date_formatter.dart';
import 'package:ledger/services/date_format_service.dart';
import 'package:ledger/components/transactions/transaction_list_item.dart';

class DashboardScreen extends StatefulWidget {
  final AbstractAccountService? accountService;
  final AbstractDashboardService? dashboardService;
  const DashboardScreen({
    super.key,
    this.accountService,
    this.dashboardService,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AbstractAccountService _accountService;
  late final AbstractDashboardService _dashboardService;
  late final AbstractSearchService _searchService;
  final DatabaseService _dbService = DatabaseService();

  List<DashboardWidget> _widgets = [];
  bool _isLoadingWidgets = true;
  Map<String, bool> _widgetVisibility = {};
  String _dateFormatKey = DateFormats.defaultKey;

  Future<void> _loadDateFormat() async {
    final k = await UserPreferenceService.getDateFormat();
    if (mounted) setState(() => _dateFormatKey = k);
  }

  void _onDateFormatChanged() {
    if (mounted) {
      setState(() => _dateFormatKey = DateFormatService.notifier.value);
    }
  }

  @override
  void dispose() {
    DateFormatService.notifier.removeListener(_onDateFormatChanged);
    super.dispose();
  }

  // Search state
  bool _isSearching = false;
  List<Transaction> _searchTransactions = [];
  List<Account> _searchAccounts = [];
  SearchFilter _currentFilter = const SearchFilter();
  Map<String, String> _accountNames = {};

  late final List<Map<String, dynamic>> fabMenu;

  void _showDBPasswordDialog() async {
    // Check if password is already set
    final bool hasPassword =
        await UserPreferenceService.isDatabasePasswordSet();

    if (hasPassword) {
      // Password exists, try to open database
      try {
        DatabaseService dbService = DatabaseService();
        await dbService.init();
        await dbService.openDB();

        if (mounted) {
          setState(() {}); // Refresh to show data
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DashboardConstants.failedToOpenDatabaseError),
            backgroundColor: CustomColors.negative,
            action: SnackBarAction(
              label: DashboardConstants.settingsLabel,
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(DashboardConstants.settingsRoute),
            ),
          ),
        );
      }
      return;
    }

    // No password set, show beautiful dialog to set one
    final TextEditingController dbPasswordController = TextEditingController();
    String? errorMessage;
    bool isObscured = true;
    void outerSetState(VoidCallback fn) => setState(fn);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon and Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.security,
                            color: Colors.blue[700],
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            DashboardConstants.secureYourDataTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Description Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.withAlpha(25)
                            : Colors.blue.withAlpha(12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withAlpha(51)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DashboardConstants.databasePasswordDescription,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: isDark
                                    ? Colors.blue[200]
                                    : Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Password Field
                    TextField(
                      controller: dbPasswordController,
                      obscureText: isObscured,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: DashboardConstants.databasePasswordLabel,
                        hintText: DashboardConstants.minimumCharactersHint,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isObscured
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isObscured = !isObscured;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.blue[700]!,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CustomColors.red400.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CustomColors.red400.withAlpha(76),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: CustomColors.red400,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: CustomColors.red400,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Set Password Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (dbPasswordController.text.trim().isEmpty) {
                          setState(() {
                            errorMessage =
                                DashboardConstants.passwordCannotBeEmptyError;
                          });
                          return;
                        }

                        if (dbPasswordController.text.trim().length <
                            DashboardConstants.minimumPasswordLength) {
                          setState(() {
                            errorMessage =
                                DashboardConstants.passwordMinLengthError;
                          });
                          return;
                        }

                        try {
                          await UserPreferenceService.setDBPassword(
                            password: dbPasswordController.text.trim(),
                          );
                          // Initialize and open the database after setting password
                          DatabaseService dbService = DatabaseService();
                          await dbService.init();
                          await dbService.openDB();

                          if (!mounted) return;
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          // Refresh the screen to load data
                          outerSetState(() {});
                        } catch (e) {
                          setState(() {
                            errorMessage =
                                '${DashboardConstants.failedToSetPasswordError}: $e';
                          });
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text(
                        DashboardConstants.setPasswordAndContinueLabel,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() => dbPasswordController.dispose());
  }

  Future<void> _checkDBPassword() async {
    if (!await UserPreferenceService.isDatabasePasswordSet()) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showDBPasswordDialog();
        });
      }
    }
  }

  Future<void> _loadDashboardWidgets() async {
    try {
      final widgets = await _dashboardService.getDashboardWidgets();
      final visibility =
          await UserPreferenceService.getDashboardWidgetVisibility();
      setState(() {
        _widgets = widgets;
        _widgetVisibility = visibility;
        _isLoadingWidgets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWidgets = false;
      });
    }
  }

  Future<void> _performSearch(SearchFilter filter) async {
    setState(() {
      _isSearching = true;
      _currentFilter = filter;
    });

    try {
      final transactions = await _searchService.searchTransactions(filter);
      final accounts = await _searchService.searchAccounts(filter);

      // Load account names for transactions
      final allAccounts = await _accountService.fetchAccounts();
      final accountNames = {
        for (final acc in allAccounts)
          if (acc != null) acc.id: acc.name,
      };

      setState(() {
        _searchTransactions = transactions;
        _searchAccounts = accounts;
        _accountNames = accountNames;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${DashboardConstants.searchFailedError}: $e'),
          ),
        );
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _isSearching = false;
      _searchTransactions = [];
      _searchAccounts = [];
      _currentFilter = const SearchFilter();
    });
  }

  @override
  void initState() {
    super.initState();
    _checkDBPassword();
    _accountService = widget.accountService ?? AccountService();
    _dashboardService = widget.dashboardService ?? DashboardService();
    _searchService = SearchService();
    _loadDateFormat();
    DateFormatService.notifier.addListener(_onDateFormatChanged);
    _loadDashboardWidgets();
    fabMenu = [
      {
        'title': DashboardConstants.addTransactionTitle,
        'onTap': () async {
          // Ensure at least one account exists before creating a transaction
          final accounts = await _accountService.fetchAccounts();
          if (!mounted) return; // prevent use of context after async gap
          if (accounts.isEmpty) {
            final createAccount = await showDialog<bool>(
              context: context,
              builder: (BuildContext dc) => CustomDialog(
                title: DashboardConstants.noAccountsTitle,
                content: DashboardConstants.noAccountsMessage,
                actions: [
                  CustomButton(
                    text: DashboardConstants.cancelLabel,
                    onPressed: () => Navigator.of(dc).pop(false),
                  ),
                  CustomButton(
                    text: DashboardConstants.createAccountLabel,
                    onPressed: () => Navigator.of(dc).pop(true),
                  ),
                ],
              ),
            );
            if (createAccount == true) {
              if (!mounted) return;
              final accountData =
                  await showModalBottomSheet<Map<String, String?>>(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext bc) {
                      return AccountFormModal(accountService: _accountService);
                    },
                  );
              if (accountData == null) {
                return; // user cancelled account creation
              }
              await _accountService.createAccount(
                accountData['name']!,
                accountData['description'],
                currency: accountData['currency'],
              );
            } else {
              return; // user cancelled No Accounts dialog
            }
          }

          if (!mounted) return;
          if (!mounted) return; // double safety
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return const TransactionFormModal();
            },
          );
          if (!mounted) return;
          setState(() {});
        },
      },
      {
        'title': DashboardConstants.addAccountTitle,
        'onTap': () async {
          final accountData = await showModalBottomSheet<Map<String, String?>>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return AccountFormModal(accountService: _accountService);
            },
          );
          if (accountData != null) {
            await _accountService.createAccount(
              accountData['name']!,
              accountData['description'],
              currency: accountData['currency'],
            );
            if (!mounted) return;
            setState(() {}); // Refresh the net worth
          }
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: DashboardConstants.screenTitle),
      drawer: const CustomAppDrawer(),
      floatingActionButton: CustomFloatingActionButton(
        tooltip: DashboardConstants.addTooltip,
        menuOptions: fabMenu,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            SearchBarWidget(
              onSearch: _performSearch,
              initialFilter: _currentFilter,
              showFilters: true,
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_currentFilter.query != null &&
                _currentFilter.query!.isNotEmpty)
              _buildSearchResults()
            else ...[
              // Net Worth Section
              Text(
                DashboardConstants.netWorthSectionTitle,
                style: DashboardConstants.getSectionTitleStyle(context),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: DashboardConstants.cardPaddingHorizontal,
                  vertical: DashboardConstants.cardPaddingVertical,
                ),
                child: _dbService.isDBOpen
                    ? FutureBuilder(
                        future: _accountService.fetchNetWorth(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else if (snapshot.hasData) {
                            return FutureBuilder<String>(
                              future:
                                  UserPreferenceService.getDefaultCurrency(),
                              builder: (context, currencySnapshot) {
                                final currency =
                                    currencySnapshot.data ??
                                    DashboardConstants.defaultCurrency;
                                final formatted = CurrencyFormatter.format(
                                  (snapshot.data as double),
                                  currency,
                                );
                                return Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? CustomColors.darkGreen.withAlpha(
                                                35,
                                              )
                                            : Theme.of(
                                                context,
                                              ).primaryColor.withAlpha(25),
                                        borderRadius: BorderRadius.circular(
                                          DashboardConstants
                                              .iconContainerBorderRadius,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet,
                                        color: isDark
                                            ? CustomColors.lightGreen
                                            : Theme.of(context).primaryColor,
                                        size: DashboardConstants.iconSize,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            DashboardConstants
                                                .totalBalanceLabel,
                                            style:
                                                DashboardConstants.getBalanceLabelStyle(
                                                  context,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formatted,
                                            style:
                                                DashboardConstants.getBalanceAmountStyle(
                                                  context,
                                                  (snapshot.data as double) >=
                                                      0,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withAlpha(25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(
                                  child: Text(
                                    DashboardConstants.noDataFoundLabel,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      )
                    : InkWell(
                        onTap: () => _showDBPasswordDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lock_outline,
                                color: Colors.blue[700],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                DashboardConstants.setPasswordPrompt,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Dashboard Widgets Section
              Text(
                DashboardConstants.dashboardSectionTitle,
                style: DashboardConstants.getSectionTitleStyle(context),
              ),
              const SizedBox(height: 12),
              if (_isLoadingWidgets)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildDashboardGrid(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              DashboardConstants.searchResultsTitle,
              style: DashboardConstants.getSectionTitleStyle(context),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.clear, size: 18),
              label: const Text(DashboardConstants.clearSearchLabel),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_searchTransactions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Transactions (${_searchTransactions.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: DashboardConstants.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(
                DashboardConstants.cardBorderRadius,
              ),
              boxShadow: DashboardConstants.getCardShadow(),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchTransactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = _searchTransactions[index];
                final accountName =
                    _accountNames[transaction.accountId] ?? 'Unknown';
                return TransactionListItem(
                  transaction: transaction,
                  subtitle:
                      '$accountName • ${DateFormatter.formatWithKeyOrPattern(transaction.date, _dateFormatKey)}',
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            TransactionDetailScreen(transaction: transaction),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_searchAccounts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Accounts (${_searchAccounts.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: DashboardConstants.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(
                DashboardConstants.cardBorderRadius,
              ),
              boxShadow: DashboardConstants.getCardShadow(),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _searchAccounts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final account = _searchAccounts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  title: Text(
                    account.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Balance: \$${account.balance} ${account.currency}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AccountTransactionsScreen(account: account),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_searchTransactions.isEmpty && _searchAccounts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: DashboardConstants.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(
                DashboardConstants.cardBorderRadius,
              ),
              boxShadow: DashboardConstants.getCardShadow(),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: DashboardConstants.emptyStateIconSize,
                    color: DashboardConstants.getEmptyStateIconColor(context),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  DashboardConstants.noResultsFoundLabel,
                  style: DashboardConstants.getEmptyStateTitleStyle(context),
                ),
                const SizedBox(height: 8),
                Text(
                  DashboardConstants.adjustSearchCriteriaPrompt,
                  style: DashboardConstants.getEmptyStateSubtitleStyle(context),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDashboardGrid() {
    // Filter widgets based on visibility preferences
    final visibleWidgets = _widgets.where((widget) {
      final key = widget.type.toString().split('.').last;
      return _widgetVisibility[key] ?? true;
    }).toList();

    if (visibleWidgets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: DashboardConstants.getCardBackgroundColor(context),
          borderRadius: BorderRadius.circular(
            DashboardConstants.cardBorderRadius,
          ),
          boxShadow: DashboardConstants.getCardShadow(),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.widgets_outlined,
                size: DashboardConstants.emptyStateIconSize,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              DashboardConstants.noWidgetsVisibleLabel,
              style: DashboardConstants.getEmptyStateTitleStyle(context),
            ),
            const SizedBox(height: 8),
            Text(
              DashboardConstants.enableWidgetsPrompt,
              style: DashboardConstants.getEmptyStateSubtitleStyle(context),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(
                context,
              ).pushNamed(DashboardConstants.settingsRoute),
              icon: const Icon(Icons.settings, size: 18),
              label: const Text(DashboardConstants.goToSettingsLabel),
            ),
          ],
        ),
      );
    }

    return Column(
      children: visibleWidgets.map((widget) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DashboardWidgetContainer(widget: widget),
        );
      }).toList(),
    );
  }
}
