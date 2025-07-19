import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

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
      backgroundColor: const Color(0xFFFAF6F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.verified_user, color: Color(0xFFF4B183)),
            const SizedBox(width: 8),
            Text('SwiftCheck', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            child: SizedBox(
              width: 400,
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
                        const SizedBox(height: 8),
                        const Text('Login', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person),
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) => _username = val,
                          validator: (val) => val == null || val.isEmpty ? 'Enter username' : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          onChanged: (val) => _password = val,
                          validator: (val) => val == null || val.isEmpty ? 'Enter password' : null,
                        ),
                        const SizedBox(height: 32),
                        if (state is AuthLoading)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF4B183),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<AuthBloc>().add(
                                    AuthLoginRequested(_username, _password),
                                  );
                                }
                              },
                              child: const Text('Login', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
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

  Widget _buildNewPasswordForm(BuildContext context, AuthNewPasswordRequiredState state) {
    final _newPasswordFormKey = GlobalKey<FormState>();
    return Form(
      key: _newPasswordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          const Text('Set New Password', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text(
            'You must set a new password before continuing.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock_reset),
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            onChanged: (val) => _newPassword = val,
            validator: (val) => val == null || val.length < 8 ? 'Password must be at least 8 characters' : null,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFF4B183),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              child: const Text('Update Password', style: TextStyle(color: Colors.white)),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
} 