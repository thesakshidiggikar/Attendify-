import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/widgets/professional_card.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _newPassword = '';
  String? _errorMessage;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: ProfessionalCard(
              padding: const EdgeInsets.all(40),
              borderRadius: 24,
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    Navigator.pushReplacementNamed(context, '/attendance');
                  }
                  if (state is AuthError) {
                    setState(() => _errorMessage = state.message);
                  } else {
                    setState(() => _errorMessage = null);
                  }
                },
                builder: (context, state) {
                  if (state is AuthNewPasswordRequiredState) {
                    return _buildNewPasswordForm(context, state);
                  }
                  
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.primaryColor).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.school_rounded, 
                            size: 48, 
                            color: Color(AppConstants.primaryColor)
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Student Portal',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(AppConstants.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in with the ID provided by Admin',
                          style: TextStyle(
                            color: Color(AppConstants.textSecondary), 
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        _buildInputField(
                          label: 'Student ID',
                          icon: Icons.badge_outlined,
                          onChanged: (val) => _username = val,
                          validator: (val) => val == null || val.isEmpty ? 'Enter your Student ID (e.g. STUD001)' : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                          onChanged: (val) => _password = val,
                          validator: (val) => val == null || val.isEmpty ? 'Enter your password' : null,
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 20),
                          _buildErrorBox(_errorMessage!),
                        ],
                        const SizedBox(height: 32),
                        if (state is AuthLoading)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(AppConstants.primaryColor),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  // Restore bypass for dev/testing
                                  if (_username == 'admin' && _password == 'admin') {
                                    context.read<AuthBloc>().add(AuthBypassRequested(_username));
                                    return;
                                  }

                                  context.read<AuthBloc>().add(
                                    AuthLoginRequested(_username, _password),
                                  );
                                }
                              },
                              child: const Text(
                                'Login to Kiosk', 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    required void Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      obscureText: isPassword ? obscureText : false,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Color(AppConstants.textPrimary)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(AppConstants.primaryColor).withOpacity(0.7)),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(AppConstants.primaryColor).withOpacity(0.7),
              ),
              onPressed: onToggleVisibility,
            )
          : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message, 
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500)
            )
          ),
        ],
      ),
    );
  }

  Widget _buildNewPasswordForm(BuildContext context, AuthNewPasswordRequiredState state) {
    return Form(
      key: _newPassKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: Color(AppConstants.accentColor)),
          const SizedBox(height: 24),
          const Text('Reset Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('A new password is required for first-time login', textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildInputField(
            label: 'New Password',
            icon: Icons.lock_reset,
            isPassword: true,
            obscureText: _obscurePassword,
            onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
            onChanged: (val) => _newPassword = val,
            validator: (val) => val == null || val.length < 8 ? 'Min 8 characters' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_newPassKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    AuthNewPasswordRequired(username: state.username, newPassword: _newPassword)
                  );
                }
              },
              child: const Text('Update & Sign In'),
            ),
          ),
        ],
      ),
    );
  }
}
