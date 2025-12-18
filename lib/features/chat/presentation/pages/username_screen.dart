import 'package:e2ee_chatapp/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'join_create_screen.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUsername();
  }

  Future<void> _checkUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => JoinCreateScreen(username: username),
        ),
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUsername() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _usernameController.text.trim());

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                JoinCreateScreen(username: _usernameController.text.trim()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.withOpacity(AppColors.gradientStart, 0.1),
              AppColors.withOpacity(AppColors.gradientEnd, 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'E2EE Chat',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'End-to-End Encrypted Messaging',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Choose Your Username',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                hintText: 'Enter your username',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                              ),
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.trim().length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _saveUsername(),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _saveUsername,
                              icon: const Icon(Icons.arrow_forward),
                              label: const Text('Continue'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textOnPrimary,
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
