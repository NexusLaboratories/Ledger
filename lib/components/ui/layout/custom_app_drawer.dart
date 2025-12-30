import 'package:flutter/material.dart';
import 'package:ledger/presets/routes.dart';
import 'package:ledger/presets/theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ledger/services/logger_service.dart';

class CustomAppDrawer extends StatelessWidget {
  const CustomAppDrawer({super.key});

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomColors.primary,
                  CustomColors.primary.withAlpha(204),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nexus',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Ledger',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.dashboard,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports & Statistics',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.reports,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.psychology_rounded,
                    title: 'Assistant',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.aiChat,
                        (route) => false,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Accounts',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.accounts,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.pie_chart_rounded,
                    title: 'Budgets',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.budgets,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Transactions',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.transactions,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.categories,
                        (route) => false,
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.label_rounded,
                    title: 'Tags',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.tags,
                        (route) => false,
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.favorite_rounded,
                    title: 'Support Us',
                    onTap: () async {
                      final url = Uri.parse('https://kalkieshward.me/support');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e, st) {
                        LoggerService.e('Error launching URL', e, st);
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.settings,
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
