import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EmployeeRegistrationForm extends StatefulWidget {
  final void Function({
    required String username,
    required String email,
    required String password,
    required String profile,
    required XFile? image,
  }) onRegister;
  const EmployeeRegistrationForm({Key? key, required this.onRegister}) : super(key: key);

  @override
  State<EmployeeRegistrationForm> createState() => EmployeeRegistrationFormState();
}

class EmployeeRegistrationFormState extends State<EmployeeRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _profile = 'employee';
  XFile? _image;

  void clearForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _profile = 'employee';
      _image = null;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Register New Employee', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _profile,
                items: const [
                  DropdownMenuItem(value: 'employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _profile = v ?? 'employee'),
                decoration: const InputDecoration(labelText: 'Profile'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Upload Image'),
                  ),
                  const SizedBox(width: 12),
                  _image != null
                      ? Text(_image!.name, style: const TextStyle(fontSize: 12))
                      : const Text('No image selected', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) => v == null || v.length < 8 ? 'Enter password (min 8 chars)' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        widget.onRegister(
                          username: _usernameController.text.trim(),
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                          profile: _profile,
                          image: _image,
                        );
                      }
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 