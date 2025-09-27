import 'package:flutter/material.dart';
import 'package:monami/auth/view/admin_auth_view.dart';
import 'package:monami/auth/view/student_auth_view.dart';
import 'package:monami/core/utils/responsive_utils.dart';

class AuthSelectorScreen extends StatelessWidget {
  const AuthSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'images/bg.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: ResponsiveUtils.getResponsiveFormWidth(context),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getResponsiveValue(
                      context,
                      mobile: 20,
                      tablet: 24,
                      desktop: 28,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                margin: ResponsiveUtils.getResponsiveMargin(context),
                child: Padding(
                  padding: ResponsiveUtils.getResponsivePadding(context),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo or icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.computer,
                          size: ResponsiveUtils.getResponsiveValue(
                            context,
                            mobile: 50,
                            tablet: 70,
                            desktop: 90,
                          ),
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Title
                      Text(
                        'COMPUTER-BASED TEST SYSTEM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 22,
                            tablet: 28,
                            desktop: 34,
                          ),
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'FACULTY OF PHARMACEUTICAL SCIENCES\nUNIVERSITY OF NIGERIA, NSUKKA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 14,
                            tablet: 16,
                            desktop: 18,
                          ),
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 50),

                      // Selection prompt
                      Text(
                        'Select your login type:',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            mobile: 16,
                            tablet: 18,
                            desktop: 20,
                          ),
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Student login card
                      _buildLoginCard(
                        context,
                        title: 'Student Login',
                        subtitle: 'Access tests with your registration number',
                        icon: Icons.school,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const StudentAuthScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Admin login card
                      _buildLoginCard(
                        context,
                        title: 'Admin Portal',
                        subtitle: 'Class representatives and administrators',
                        icon: Icons.admin_panel_settings,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AdminAuthScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),

                      // Help text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.help_outline,
                                color: Colors.grey.shade600),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Students: Use your registration number to access tests.\nAdmins: Manage student accounts and upload class lists.',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: ResponsiveUtils.getResponsiveValue(
                    context,
                    mobile: 32,
                    tablet: 40,
                    desktop: 48,
                  ),
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 14,
                          desktop: 16,
                        ),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
