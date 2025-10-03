import 'package:flutter/material.dart';
import 'package:monami/core/utils/migration_helper.dart';

class AdminToolsView extends StatefulWidget {
  const AdminToolsView({super.key});

  @override
  State<AdminToolsView> createState() => _AdminToolsViewState();
}

class _AdminToolsViewState extends State<AdminToolsView> {
  final MigrationHelper _migrationHelper = MigrationHelper();
  bool _isRunning = false;
  String _status = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tools'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning card
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Administrator Tools',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'These tools modify data in Firebase. Use with caution and ensure you have backups.',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Migration section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Number Format Migration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Migrates existing registration numbers to the new YYYY/NNNNNN format and ensures proper normalization in Firebase collections.',
                    ),
                    const SizedBox(height: 16),
                    if (_status.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _status,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isRunning ? null : _runMigration,
                          icon: _isRunning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label:
                              Text(_isRunning ? 'Running...' : 'Run Migration'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isRunning ? null : _validateMigration,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Validate Data'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registration Number Format',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text('• New format: YYYY/NNNNNN (e.g., 2019/240045)'),
                    const Text('• Year: 4 digits (2000-2030)'),
                    const Text('• Number: 6 digits'),
                    const Text(
                        '• Stored in Firebase as: YYYY_NNNNNN (normalized)'),
                    const Text(
                        '• Displayed to users as: YYYY/NNNNNN (original format)'),
                    const SizedBox(height: 8),
                    const Text(
                      'Migration process:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Text('1. Updates user documents with new fields'),
                    const Text('2. Normalizes test session user IDs'),
                    const Text('3. Validates data integrity'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Starting migration...';
    });

    try {
      // Run migration and capture output
      final result = await _migrationHelper.runAllMigrations();

      setState(() {
        _status = result;
        _status += '\n✅ Migration completed successfully!';
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Migration completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status += '\n❌ Migration failed: $e';
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Migration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _validateMigration() async {
    setState(() {
      _isRunning = true;
      _status = 'Validating data...';
    });

    try {
      // Run validation
      final result = await _migrationHelper.validateMigration();

      setState(() {
        _status = result;
        _status += '\n✅ Validation completed!';
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Validation completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status += '\n❌ Validation failed: $e';
        _isRunning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
