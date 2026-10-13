import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            _HistoryTabPlaceholder(),
            _AssistantTabPlaceholder(),
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

class _HistoryTabPlaceholder extends StatelessWidget {
  const _HistoryTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checkup History',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF12343B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'View your past screening assessments',
                style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        size: 32,
                        color: Color(0xFF006B6F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'History Coming Soon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF12343B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Checkup history and past results will be available in item 7a.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssistantTabPlaceholder extends StatelessWidget {
  const _AssistantTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Health360 AI Assistant',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF12343B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ask questions about your health screening results',
                style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
              ),
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF4FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 32,
                        color: Color(0xFF006B6F),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AI Assistant Coming Soon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF12343B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Interactive assistant chat will be available in item 7b.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF718083)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
