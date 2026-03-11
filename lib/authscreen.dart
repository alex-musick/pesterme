import 'package:flutter/material.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real authentication state and callbacks.
    const bool signedIn = false; //replace with call to calendar code
    const String userEmail = 'example@example.com'; // placeholder email

    final String statusText = signedIn
        ? 'Signed in: $userEmail'
        : 'Not Signed In';
    final String buttonText = signedIn ? 'Sign Out' : 'Sign In'; //Choose button text

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement sign‑in/out logic here.
              // Check bool signedIn to determine which callback to use.
            },
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}
