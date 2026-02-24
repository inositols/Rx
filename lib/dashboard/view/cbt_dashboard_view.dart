import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:monami/auth/bloc/bloc.dart';
import 'package:monami/core/utils/responsive_utils.dart';
import 'package:monami/question/view/question_management_view.dart';
import 'package:monami/quiz/bloc/bloc.dart';
import 'package:monami/quiz/view/quiz_upload_view.dart';
import 'package:monami/shared/view/auth_selector_view.dart';

import '../../test/view/view.dart';
import 'admin_tools_view.dart';

class CBTDashboardView extends StatelessWidget {
  const CBTDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthSelectorScreen()),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Computer-Based Test System'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        context.read<AuthBloc>().add(AuthSignOutRequested());
                      } else if (value == 'admin') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminToolsView(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Text(state.userData['regNo'] ?? 'User'),
                          ],
                        ),
                      ),
                      // Add admin tools option for specific users
                      if (_isAdminUser(state.userData))
                        const PopupMenuItem(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings,
                                  color: Colors.red),
                              SizedBox(width: 8),
                              Text('Admin Tools'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: ResponsiveContainer(
          child: Column(
            children: [
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthAuthenticated) {
                    final userData = state.userData;
                    final regNo = userData['regNo'] ??
                        userData['regNoNormalized']?.replaceAll('_', '/') ??
                        'N/A';
                    return ResponsiveCard(
                      elevation: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 2,
                        tablet: 3,
                        desktop: 4,
                      ),
                      child: Padding(
                        padding: ResponsiveUtils.getResponsivePadding(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.badge,
                                    color: Colors.teal.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Registration: $regNo',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.school,
                                    color: Colors.teal.shade600, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Level: ${userData['level'] ?? 'N/A'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (userData['gender'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                spacing: 8,
                                children: [
                                  Icon(Icons.person,
                                      color: Colors.teal.shade600, size: 20),
                                  Text(
                                    'Gender: ${userData['gender']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is! AuthAuthenticated) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final isAdmin =
                        state.isAdmin || _isAdminUser(state.userData);
                    final dashboardCards = _getDashboardCards(context, isAdmin);

                    return GridView.count(
                      crossAxisCount:
                          ResponsiveUtils.getResponsiveGridColumns(context),
                      crossAxisSpacing: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                      mainAxisSpacing: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 12,
                        tablet: 16,
                        desktop: 20,
                      ),
                      childAspectRatio: ResponsiveUtils.getResponsiveValue(
                        context,
                        mobile: 1.0,
                        tablet: 1.1,
                        desktop: 1.2,
                      ),
                      children: dashboardCards,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get dashboard cards based on user type
  List<Widget> _getDashboardCards(BuildContext context, bool isAdmin) {
    final studentCards = [
      _DashboardCard(
        title: 'Take Test',
        subtitle: 'Start a new computer-based test',
        icon: Icons.quiz,
        color: Colors.blue,
        onTap: () {
          context.read<QuizBloc>().add(LoadAvailableTests());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TestListView(),
            ),
          );
        },
      ),
      _DashboardCard(
        title: 'Test History',
        subtitle: 'View your past test results',
        icon: Icons.history,
        color: Colors.green,
        onTap: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final userId = authState.userData['regNo'] ?? '';
            context.read<QuizBloc>().add(LoadTestHistory(userId: userId));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TestHistoryView(),
              ),
            );
          }
        },
      ),
    ];

    final adminCards = [
      _DashboardCard(
        title: 'Upload Questions',
        subtitle: 'Add new test questions via CSV',
        icon: Icons.upload_file,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WebCsvUploadScreen(),
            ),
          );
        },
      ),
      _DashboardCard(
        title: 'Manage Questions',
        subtitle: 'View and edit questions',
        icon: Icons.edit_note,
        color: Colors.purple,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuestionManagementView(),
            ),
          );
        },
      ),
      _DashboardCard(
        title: 'Statistics',
        subtitle: 'View performance analytics',
        icon: Icons.analytics,
        color: Colors.indigo,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Statistics view coming soon!')),
          );
        },
      ),
      _DashboardCard(
        title: 'Settings',
        subtitle: 'Configure test settings',
        icon: Icons.settings,
        color: Colors.grey,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings view coming soon!')),
          );
        },
      ),
    ];

    // Students get only student cards, admins get all cards
    return isAdmin ? [...studentCards, ...adminCards] : studentCards;
  }

  // Helper method to check if user is admin
  bool _isAdminUser(Map<String, dynamic> userData) {
    // Check if user has admin privileges
    final regNo = userData['regNo'] as String?;
    final email = userData['email'] as String?;

    // Admin if reg number starts with 2020/000xxx or specific email domains
    if (regNo != null && regNo.startsWith('2020/000')) {
      return true;
    }

    if (email != null &&
        (email.endsWith('@admin.unn.edu.ng') || email == 'admin@example.com')) {
      return true;
    }

    // Check for admin role field
    final role = userData['role'] as String?;
    if (role == 'admin' || role == 'administrator') {
      return true;
    }

    return false;
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: ResponsiveUtils.getResponsiveValue(
        context,
        mobile: 2,
        tablet: 3,
        desktop: 4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveValue(
            context,
            mobile: 8,
            tablet: 12,
            desktop: 16,
          ),
        ),
        child: Padding(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 36.0,
                  tablet: 42.0,
                  desktop: 48.0,
                ),
                color: color,
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 8.0,
                  tablet: 10.0,
                  desktop: 12.0,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 16,
                        tablet: 17,
                        desktop: 18,
                      ),
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(
                height: ResponsiveUtils.getResponsiveValue(
                  context,
                  mobile: 2.0,
                  tablet: 3.0,
                  desktop: 4.0,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
