import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../widgets/app_scaffold.dart';
import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  // Backend API URL - update this to match your backend server
  static const String _baseUrl = 'http://localhost:3001/api/v1/auth';

  Future<void> _validateAndNavigateWithToken() async {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      _showErrorSnackBar('Please enter a token');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      developer.log('Validating token...', name: 'WelcomeScreen');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/validate-token'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': token,
        }),
      ).timeout(const Duration(seconds: 30));

      developer.log('Response status: ${response.statusCode}', name: 'WelcomeScreen');
      developer.log('Response body: ${response.body}', name: 'WelcomeScreen');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['success'] == true) {
          final user = responseData['user'];
          final redirect = responseData['redirect'];
          final tokenData = responseData['token'];
          
          developer.log('Token validated successfully for user: ${user['user_id']}', name: 'WelcomeScreen');
          developer.log('User role: ${user['role']}', name: 'WelcomeScreen');
          developer.log('Redirect URL: ${redirect['url']}', name: 'WelcomeScreen');
          
          // Authenticate user with JWT token
          final isAuthenticated = await _authService.authenticateWithJwtToken(token, tokenData);
          
          if (isAuthenticated) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${user['email']}! Logged in as ${user['role']}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Navigate to the dashboard
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                context.go('/dashboard');
              }
            });
          } else {
            _showErrorSnackBar('Failed to authenticate user');
          }
        } else {
          _showErrorSnackBar(responseData['message'] ?? 'Token validation failed');
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorSnackBar(errorData['message'] ?? 'Token validation failed');
      }
    } catch (e) {
      developer.log('Error validating token: $e', name: 'WelcomeScreen', error: e);
      _showErrorSnackBar('Network error. Please check your connection and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFC10D00),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      useBackgroundImage: true,
      useGlassContainer: true,
      centered: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 140),

            // Logo / Title
            Text(
              'Deliverables and Sprints Sign Off Hub',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Red subtitle
            Text(
              'Your Growth Journey, Simplified',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC10D00),
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Tagline / description
            Text(
              'Build strong habits, build a strong future.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color.fromRGBO(255, 255, 255, 0.85),
                  ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Primary and secondary actions
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC10D00),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text(
                        'GET STARTED',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Token input field
                Container(
                  width: 260,
                  child: Column(
                    children: [
                      TextField(
                        controller: _tokenController,
                        decoration: InputDecoration(
                          hintText: 'Enter token',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 260,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _validateAndNavigateWithToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFC10D00),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC10D00)),
                                  ),
                                )
                              : const Text(
                                  'OPEN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
