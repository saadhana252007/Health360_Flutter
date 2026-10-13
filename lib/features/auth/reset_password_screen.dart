import 'package:flutter/material.dart';

/// Placeholder for the Reset-Password screen (item 3c).
///
/// Opened via the `health360://login/reset` deep link after Supabase
/// redirects from the password-reset email.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Text(
          'Reset password screen — coming in item 3c',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
