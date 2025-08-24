import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/group/group_screen.dart';
import '../features/new_expense/new_expense_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/settle_up/settle_up_screen.dart';
import '../features/settings/settings_screen.dart';
import '../core/security/app_lock_service.dart';

/// Create the app router with all routes
GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Check if app is locked and redirect to lock screen if needed
      final appLockState = ref.read(appLockStateProvider);
      if (appLockState.isLocked && !state.matchedLocation.startsWith('/lock')) {
        return '/lock';
      }
      return null;
    },
    routes: [
      // Bottom navigation shell route
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          
          // Analytics tab
          GoRoute(
            path: '/analytics',
            name: 'analytics',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AnalyticsScreen(),
            ),
          ),
          
          // Settings tab
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      
      // Group detail screen
      GoRoute(
        path: '/group/:groupId',
        name: 'group',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return GroupScreen(groupId: groupId);
        },
      ),
      
      // New expense screen
      GoRoute(
        path: '/new-expense',
        name: 'new-expense',
        builder: (context, state) {
          final groupId = state.uri.queryParameters['groupId'];
          return NewExpenseScreen(groupId: groupId);
        },
      ),
      
      // Edit expense screen
      GoRoute(
        path: '/edit-expense/:expenseId',
        name: 'edit-expense',
        builder: (context, state) {
          final expenseId = state.pathParameters['expenseId']!;
          return NewExpenseScreen(expenseId: expenseId);
        },
      ),
      
      // Settle up screen
      GoRoute(
        path: '/settle-up/:groupId',
        name: 'settle-up',
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return SettleUpScreen(groupId: groupId);
        },
      ),
      
      // App lock screen (handled by overlay in app.dart)
      GoRoute(
        path: '/lock',
        name: 'lock',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => ErrorScreen(error: state.error),
  );
}

/// Main navigation shell with bottom navigation bar
class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const MainBottomNavigationBar(),
      floatingActionButton: _shouldShowFAB(context) ? const MainFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Check if FAB should be shown based on current route
  bool _shouldShowFAB(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    return location == '/home' || location.startsWith('/group/');
  }
}

/// Main bottom navigation bar
class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    return BottomNavigationBar(
      currentIndex: _getCurrentIndex(currentLocation),
      onTap: (index) => _onTabTapped(context, index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }

  /// Get current tab index based on location
  int _getCurrentIndex(String location) {
    if (location == '/home') return 0;
    if (location == '/analytics') return 1;
    if (location == '/settings') return 2;
    return 0; // Default to home
  }

  /// Handle tab tap
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/analytics');
        break;
      case 2:
        context.go('/settings');
        break;
    }
  }
}

/// Main floating action button
class MainFloatingActionButton extends StatelessWidget {
  const MainFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _onPressed(context),
      tooltip: 'Add Expense',
      child: const Icon(Icons.add),
    );
  }

  /// Handle FAB press
  void _onPressed(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    
    // If we're on a group screen, pass the group ID
    if (currentLocation.startsWith('/group/')) {
      final groupId = currentLocation.split('/')[2];
      context.push('/new-expense?groupId=$groupId');
    } else {
      context.push('/new-expense');
    }
  }
}

/// Error screen for router errors
class ErrorScreen extends StatelessWidget {
  final Exception? error;

  const ErrorScreen({
    super.key,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops! Something went wrong',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (error != null) ...[
                Text(
                  error.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Route transition helpers
class SlideTransitionPage extends CustomTransitionPage<void> {
  const SlideTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionsBuilder: _slideTransition,
          transitionDuration: const Duration(milliseconds: 300),
        );

  static Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return SlideTransition(
      position: animation.drive(
        Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeInOut)),
      ),
      child: child,
    );
  }
}

class FadeTransitionPage extends CustomTransitionPage<void> {
  const FadeTransitionPage({
    required super.child,
    super.name,
    super.arguments,
    super.restorationId,
  }) : super(
          transitionsBuilder: _fadeTransition,
          transitionDuration: const Duration(milliseconds: 200),
        );

  static Widget _fadeTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
      child: child,
    );
  }
}

/// Navigation extensions
extension GoRouterExtension on BuildContext {
  /// Push a route and return result
  Future<T?> pushAndWait<T extends Object?>(String location) {
    return push<T>(location);
  }

  /// Replace current route
  void replace(String location) {
    go(location);
  }

  /// Pop until reaching a specific route
  void popUntil(String location) {
    while (canPop() && GoRouterState.of(this).matchedLocation != location) {
      pop();
    }
  }
}

/// Route information provider
final currentRouteProvider = Provider<String>((ref) {
  // This would need to be updated by the router
  // For now, return a default value
  return '/home';
});

/// Navigation history provider
final navigationHistoryProvider = StateNotifierProvider<NavigationHistoryNotifier, List<String>>((ref) {
  return NavigationHistoryNotifier();
});

/// Navigation history notifier
class NavigationHistoryNotifier extends StateNotifier<List<String>> {
  NavigationHistoryNotifier() : super(['/home']);

  void push(String route) {
    state = [...state, route];
  }

  void pop() {
    if (state.length > 1) {
      state = state.sublist(0, state.length - 1);
    }
  }

  void clear() {
    state = ['/home'];
  }

  String get current => state.last;
  String? get previous => state.length > 1 ? state[state.length - 2] : null;
}
