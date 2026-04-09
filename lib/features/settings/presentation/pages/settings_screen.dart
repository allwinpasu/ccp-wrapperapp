// lib/features/settings/presentation/pages/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/theme_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, state) {
                      bool isDark = false;
                      if (state is ThemeUpdated) {
                        isDark = state.isDark;
                      }

                      return SwitchListTile(
                        title: const Text('Dark Theme'),
                        subtitle: const Text('Enable dark mode'),
                        value: isDark,
                        onChanged: (value) {
                          context.read<ThemeBloc>().add(ThemeChanged(value));
                        },
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Account',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    subtitle: const Text('View and edit your profile'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => context.go('/profile'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Manage notification preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to notifications settings
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Privacy & Security'),
                    subtitle: const Text('Manage your privacy settings'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to privacy settings
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Support',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('Get help and contact support'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to help
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('App version and information'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'My Flutter App',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 My Company',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
