import 'package:flutter/material.dart';

/// Placeholder for the HomeShell (bottom-nav shell, item 4a).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Home shell — coming in item 4a',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
