import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';
  String _newPassword = '';
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(AppConstants.primaryColor),
              Color(AppConstants.primaryLight),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 480,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    if (state.user.role == 'admin') {
                      Navigator.pushReplacementNamed(context, '/admin');
                    } else {
                      Navigator.pushReplacementNamed(context, '/employee');
                    }
                  }
                  if (state is AuthError) {
                    setState(() {
                      _errorMessage = state.message;
                    });
                  } else {
                    setState(() {
                      _errorMessage = null;
                    });
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(AppConstants.primaryLight).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school_rounded, size: 64, color: Color(AppConstants.primaryColor)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Teacher Portal',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(AppConstants.textPrimary),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to manage your students and classes',
                          style: TextStyle(color: Color(AppConstants.textSecondary), fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildInputField(
                          label: 'Username or Email',
                          icon: Icons.person_outline_rounded,
                          onChanged: (val) => _username = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter your username' : null,
                        ),
                        const SizedBox(height: 24),
                        _buildInputField(
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          onChanged: (val) => _password = val,
                          validator: (val) => val == null || val.isEmpty ? 'Please enter your password' : null,
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                              ],
                            ),
                          ),
                        const SizedBox(height: 32),
                        if (state is AuthLoading)
                          const CircularProgressIndicator(color: Color(AppConstants.primaryColor))
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // Restore bypass for dev/testing
                                    if (_username == 'admin' && _password == 'admin') {
                                      context.read<AuthBloc>().add(AuthBypassRequested(_username));
                                      return;
                                    }

                                    // Use the AuthBloc even for the bypass to ensure state is updated
                                    context.read<AuthBloc>().add(
                                      AuthLoginRequested(_username, _password),
                                    );
                                  }
                                },
                              child: const Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    required void Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      obscureText: isPassword,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Color(AppConstants.textPrimary), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(AppConstants.textSecondary)),
        prefixIcon: Icon(icon, color: const Color(AppConstants.primaryLight)),
        filled: true,
        fillColor: const Color(AppConstants.backgroundColor).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(AppConstants.primaryColor), width: 2),
        ),
      ),
    );
  }

  Widget _buildNewPasswordForm(BuildContext context, AuthNewPasswordRequiredState state) {
    final _newPasswordFormKey = GlobalKey<FormState>();
    return Form(
      key: _newPasswordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(AppConstants.accentColor).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 48, color: Color(AppConstants.accentColor)),
          ),
          const SizedBox(height: 24),
          const Text('Create New Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(AppConstants.textPrimary))),
          const SizedBox(height: 12),
          const Text(
            'For security reasons, you must set a permanent password before continuing.',
            style: TextStyle(fontSize: 15, color: Color(AppConstants.textSecondary), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildInputField(
            label: 'New Secure Password',
            icon: Icons.shield_outlined,
            isPassword: true,
            onChanged: (val) => _newPassword = val,
            validator: (val) => val == null || val.length < 8 ? 'Password must be at least 8 characters' : null,
          ),
          const SizedBox(height: 32),
          if (_errorMessage != null)
             Container(
               margin: const EdgeInsets.only(bottom: 24),
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
               child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
             ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.accentColor),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                if (_newPasswordFormKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    AuthNewPasswordRequired(
                      username: state.username,
                      newPassword: _newPassword,
                    ),
                  );
                }
              },
              child: const Text('Save & Continue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}