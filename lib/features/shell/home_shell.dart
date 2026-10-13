import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../assistant/assistant_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';

/// Tracks the active bottom navigation tab:
/// 0: Home, 1: History, 2: Assistant, 3: Profile.
final activeTabProvider = StateProvider<int>((ref) => 0);

/// Bottom navigation shell mirroring Android `HomeActivity.kt` and `activity_home.xml`.
class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);

    return PopScope(
      canPop: activeTab == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && activeTab != 0) {
          ref.read(activeTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: activeTab,
          children: const [
            HomeScreen(),
            HistoryScreen(),
            AssistantScreen(),
            ProfileScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE1E9EB), width: 1)),
          ),
          child: BottomNavigationBar(
            currentIndex: activeTab,
            onTap: (index) {
              ref.read(activeTabProvider.notifier).state = index;
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF006B6F),
            unselectedItemColor: const Color(0xFF718083),
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Assistant',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
