import 'package:flutter/material.dart';
import '../services/deployment_service.dart';
import '../utils/version_config.dart';

class EnvironmentSwitcher extends StatefulWidget {
  const EnvironmentSwitcher({super.key});

  @override
  State<EnvironmentSwitcher> createState() => _EnvironmentSwitcherState();
}

class _EnvironmentSwitcherState extends State<EnvironmentSwitcher> {
  String currentEnvironment = VersionConfig.environment;
  bool isDeploying = false;

  Future<void> _switchEnvironment(String environment) async {
    setState(() {
      isDeploying = true;
    });

    try {
      await DeploymentService.switchEnvironment(environment);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Environment switched to $environment'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isDeploying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Environment: $currentEnvironment',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (isDeploying)
            const CircularProgressIndicator()
          else
            Wrap(
              spacing: 8,
              children: ['DEV', 'SIT', 'UAT', 'PROD'].map((env) {
                return ElevatedButton(
                  onPressed: currentEnvironment == env ? null : () => _switchEnvironment(env),
                  child: Text(env),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
