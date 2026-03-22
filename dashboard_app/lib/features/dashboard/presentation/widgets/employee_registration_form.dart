import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

class EmployeeRegistrationForm extends StatefulWidget {
  final String nextStudentId;
  final void Function({
    required String studentId,
    required String fullName,
    required String email,
    required String password,
    required String profile,
    required String department,
    required XFile? image,
  }) onRegister;
  
  const EmployeeRegistrationForm({
    super.key, 
    required this.onRegister,
    required this.nextStudentId,
  });

  @override
  State<EmployeeRegistrationForm> createState() => EmployeeRegistrationFormState();
}

class EmployeeRegistrationFormState extends State<EmployeeRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _studentIdController;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController();
  String _profile = 'student';
  XFile? _image;

  @override
  void initState() {
    super.initState();
    _studentIdController = TextEditingController(text: widget.nextStudentId);
  }

  @override
  void didUpdateWidget(EmployeeRegistrationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextStudentId != widget.nextStudentId && _studentIdController.text == oldWidget.nextStudentId) {
      _studentIdController.text = widget.nextStudentId;
    }
  }

  void clearForm() {
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _departmentController.clear();
    setState(() {
      _profile = 'student';
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _studentIdController,
                  label: 'Student ID (Auto-generated)',
                  icon: Icons.badge_rounded,
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInputField(
                  controller: _fullNameController,
                  label: 'Full Name',
                  icon: Icons.person_outline_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'This field is required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _emailController,
                  label: 'Student Email',
                  icon: Icons.email_outlined,
                  validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInputField(
                  controller: _departmentController,
                  label: 'Department / Class',
                  icon: Icons.business_rounded,
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a department' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDropdownField(),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInputField(
                  controller: _passwordController,
                  label: 'Account Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  validator: (v) => v == null || v.length < 8 ? 'Minimum 8 characters required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.w600, color: Color(AppConstants.textPrimary))),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(AppConstants.primaryLight).withOpacity(0.1),
                      border: Border.all(color: const Color(AppConstants.primaryColor).withOpacity(0.2), width: 2),
                    ),
                    child: _image != null 
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: Image.network(
                              _image!.path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 64, color: Color(AppConstants.primaryLight)),
                            ),
                          )
                        : const Icon(Icons.person_add_rounded, size: 48, color: Color(AppConstants.primaryLight)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(AppConstants.primaryColor),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _image != null ? 'Photo selected: ${_image!.name}' : 'No photo selected',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _image != null ? const Color(AppConstants.accentColor) : const Color(AppConstants.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This photo will be used for AI face recognition during attendance. Ensure the face is clear and looking forward.',
                      style: TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  if (_image == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please upload a student photo first'))
                    );
                    return;
                  }
                  widget.onRegister(
                    studentId: _studentIdController.text.trim(),
                    fullName: _fullNameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                    profile: _profile,
                    department: _departmentController.text.trim(),
                    image: _image,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(AppConstants.primaryColor),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add Student to System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(color: Color(AppConstants.textPrimary)),
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

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _profile,
      dropdownColor: Colors.white,
      items: const [
        DropdownMenuItem(value: 'student', child: Text('Student')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (v) => setState(() => _profile = v ?? 'student'),
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: const TextStyle(color: Color(AppConstants.textSecondary)),
        prefixIcon: const Icon(Icons.badge_outlined, color: Color(AppConstants.primaryLight)),
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
}