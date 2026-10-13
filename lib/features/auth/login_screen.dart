import 'package:flutter/material.dart';

/// Placeholder for the Login screen (implemented in checklist item 3a).
///
/// Showing a minimal UI so the router can redirect here for unauthenticated
/// users and the app compiles and runs at the scaffold stage.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Login screen — coming in item 3a',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
