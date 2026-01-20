import 'package:flutter/material.dart';
import '../services/deployment_service.dart';
import '../utils/version_config.dart';
import '../utils/version_control.dart';

class EnvironmentSwitcher extends StatefulWidget {
  const EnvironmentSwitcher({super.key});

  @override
  State<EnvironmentSwitcher> createState() => _EnvironmentSwitcherState();
}

class _EnvironmentSwitcherState extends State<EnvironmentSwitcher> {
  String? selectedEnvironment;
  bool isLoading = false;
  Map<String, dynamic>? currentConfig;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final config = await DeploymentService.getCurrentDeploymentConfig();
    setState(() {
      currentConfig = config;
      selectedEnvironment = config?['environment'] ?? 'SIT';
    });
  }

  Future<void> _switchEnvironment(String environment) async {
    setState(() => isLoading = true);
    
    try {
      await DeploymentService.switchEnvironment(environment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Environment switched to $environment'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Reload the app to apply changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (route) => false,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to switch environment: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest, color: Colors.blue[400]),
                const SizedBox(width: 8),
                Text(
                  'Environment Control',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current environment display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Environment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currentConfig?['environment'] ?? 'SIT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getEnvironmentColor(currentConfig?['environment'] ?? 'SIT'),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          VersionControl.generateVersionNumber(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Environment switcher
            Text(
              'Switch Environment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VersionConfig.environments.keys.map((env) {
                final isCurrent = currentConfig?['environment'] == env;
                return ChoiceChip(
                  label: Text(env),
                  selected: isCurrent,
                  onSelected: isCurrent ? null : (selected) {
                    if (selected) {
                      _showSwitchConfirmation(env);
                    }
                  },
                  backgroundColor: Colors.grey[700],
                  selectedColor: _getEnvironmentColor(env),
                  labelStyle: TextStyle(
                    color: isCurrent ? Colors.white : Colors.grey[300],
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            
            const SizedBox(height: 20),
            
            // Environment info
            _buildEnvironmentInfo(),
            
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    if (selectedEnvironment == null) return const SizedBox.shrink();
    
    final env = selectedEnvironment!;
    final displayName = VersionConfig.getEnvironmentDisplayName(env);
    final colors = VersionConfig.getEnvironmentColors(env);
    final requiredApprovals = VersionConfig.requiredApprovals[env] ?? [];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('Pipeline', VersionConfig.pipelineConfig[env] ?? 'N/A'),
          _buildInfoRow('Required Approvals', requiredApprovals.join(', ')),
          _buildInfoRow('Color Scheme', '#${colors['background']}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnvironmentColor(String env) {
    switch (env) {
      case 'PROD':
        return Colors.red[900] ?? Colors.red;
      case 'UAT':
        return Colors.orange[900] ?? Colors.orange;
      case 'SIT':
        return Colors.grey[700] ?? Colors.grey;
      default:
        return Colors.grey[600] ?? Colors.grey;
    }
  }

  void _showSwitchConfirmation(String environment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to $environment?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will change the application environment to:'),
            const SizedBox(height: 8),
            Text(
              VersionConfig.getEnvironmentDisplayName(environment),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('New version will be: ${VersionControl.generateVersionNumber()}'),
            const SizedBox(height: 16),
            const Text('⚠️ This action will restart the application.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _switchEnvironment(environment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getEnvironmentColor(environment),
            ),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}
