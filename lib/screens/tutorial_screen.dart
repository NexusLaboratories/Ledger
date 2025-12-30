import 'package:flutter/material.dart';
import 'package:ledger/services/user_preference_service.dart';
import 'package:ledger/presets/routes.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Soft, soothing green color
  static const Color _tutorialGreen = Color(0xFF66BB6A);

  final List<TutorialCardData> _tutorialPages = [
    TutorialCardData(
      title: 'Welcome to Nexus Ledger',
      description:
          'Your personal finance companion that helps you manage accounts, track transactions, and take control of your financial life.',
      icon: Icons.wallet_travel,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Manage Your Accounts',
      description:
          'Create and manage multiple accounts - checking, savings, credit cards, and more. Keep track of all your finances in one place.',
      icon: Icons.account_balance_wallet,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Track & Tag Transactions',
      description:
          'Add transactions with categories and tags for better organization. Tag your expenses to find patterns and insights in your spending.',
      icon: Icons.local_offer,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Talk to Your Financial Assistant',
      description:
          'Chat with our AI-powered financial assistant. Get insights, ask questions about your spending, and receive personalized advice.',
      icon: Icons.chat_bubble_outline,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Set Budgets & View Reports',
      description:
          'Create budgets for different categories and view beautiful charts and analytics. Make informed financial decisions with detailed insights.',
      icon: Icons.pie_chart,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Import & Export Your Data',
      description:
          'Easily import your financial data or export it for backup. Your data is always secure and portable whenever you need it.',
      icon: Icons.import_export,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'Encrypted & Secure Database',
      description:
          'Your financial data is protected with encryption. The database cannot be accessed without your permission, keeping your information safe and private.',
      icon: Icons.lock_outline,
      color: _tutorialGreen,
    ),
    TutorialCardData(
      title: 'You\'re All Set',
      description:
          'Explore all these features and more. Ready to take control of your financial journey? Let\'s get started!',
      icon: Icons.check_circle,
      color: _tutorialGreen,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _fadeController.reset();
    _fadeController.forward();
  }

  void _finish() async {
    final navigator = Navigator.of(context);
    await UserPreferenceService.setHasSeenTutorial(value: true);
    if (!mounted) return;
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Tutorial'),
        elevation: 0,
        actions: [
          if (_currentPage < _tutorialPages.length - 1)
            TextButton(
              onPressed: _finish,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tutorialPages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withAlpha(77),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Swipeable cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _tutorialPages.length,
              itemBuilder: (context, index) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: _TutorialCard(
                    data: _tutorialPages[index],
                    pageNumber: index + 1,
                    totalPages: _tutorialPages.length,
                  ),
                );
              },
            ),
          ),

          // Navigation buttons and swipe hint
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swipe,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe left or right to navigate',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TutorialCardData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const TutorialCardData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _TutorialCard extends StatelessWidget {
  final TutorialCardData data;
  final int pageNumber;
  final int totalPages;

  const _TutorialCard({
    required this.data,
    required this.pageNumber,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 2,
        shadowColor: data.color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: data.color.withValues(alpha: 0.08),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data.icon, size: 80, color: data.color),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Description
                Text(
                  data.description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(179),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Page counter
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pageNumber of $totalPages',
                    style: TextStyle(
                      color: data.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
