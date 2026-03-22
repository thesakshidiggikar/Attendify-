import 'package:flutter/material.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/employee.dart';

class ManualAttendancePage extends StatefulWidget {
  const ManualAttendancePage({super.key});

  @override
  State<ManualAttendancePage> createState() => _ManualAttendancePageState();
}

class _ManualAttendancePageState extends State<ManualAttendancePage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedStudent;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _status = 'Present';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<DashboardBloc, DashboardState>(
      listener: (context, state) {
        if (state is ManualAttendanceSubmitInProgress) {
          setState(() => _isSubmitting = true);
        } else if (state is ManualAttendanceSubmitSuccess) {
          setState(() {
            _isSubmitting = false;
            _selectedStudent = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Attendance recorded successfully!'),
              backgroundColor: const Color(AppConstants.primaryColor),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        } else if (state is ManualAttendanceSubmitFailure) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed: ${state.error}'), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.accentColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_calendar_rounded, size: 64, color: Color(AppConstants.accentColor)),
              ),
              const SizedBox(height: 32),
              const Text(
                'Mark Manual Attendance',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary)),
              ),
              const SizedBox(height: 8),
              const Text('Record overriding attendance entries for specific students', style: TextStyle(color: Color(AppConstants.textSecondary))),
              const SizedBox(height: 48),
              
              Container(
                width: 700,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      BlocBuilder<DashboardBloc, DashboardState>(
                        builder: (context, state) {
                          List<Employee> employees = [];
                          if (state is DashboardStatsLoadSuccess) {
                            employees = state.employees;
                          } else if (state is EmployeesLoadSuccess) {
                            employees = state.employees;
                          }

                          // Ensure selected student exists in newly loaded array
                          if (_selectedStudent != null && !employees.any((e) => e.username == _selectedStudent)) {
                             _selectedStudent = null;
                          }

                          return DropdownButtonFormField<String>(
                            decoration: _buildInputDecoration('Select Student', Icons.person_search_rounded),
                            dropdownColor: Colors.white,
                            value: _selectedStudent,
                            hint: Text(employees.isEmpty ? 'Loading students...' : 'Choose a student'),
                            items: employees.map((val) => DropdownMenuItem(value: val.cognitoUserId, child: Text(val.username.isNotEmpty ? val.username : 'Unknown (No Name)'))).toList(),
                            onChanged: employees.isEmpty ? null : (val) => setState(() => _selectedStudent = val),
                            validator: (val) => val == null ? 'Selection required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: _buildInputDecoration('Date', Icons.calendar_today_rounded),
                              controller: TextEditingController(text: "${_selectedDate.toLocal()}".split(' ')[0]),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context, 
                                  initialDate: _selectedDate, 
                                  firstDate: DateTime(2000), 
                                  lastDate: DateTime(2100),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(AppConstants.primaryColor),
                                          onPrimary: Colors.white,
                                          onSurface: Color(AppConstants.textPrimary),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) setState(() => _selectedDate = picked);
                              },
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              decoration: _buildInputDecoration('Time', Icons.access_time_rounded),
                              controller: TextEditingController(text: _selectedTime.format(context)),
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context, 
                                  initialTime: _selectedTime,
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(
                                          primary: Color(AppConstants.primaryColor),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) setState(() => _selectedTime = picked);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<String>(
                        decoration: _buildInputDecoration('Status', Icons.flaky_rounded),
                        dropdownColor: Colors.white,
                        value: _status,
                        items: ['Present', 'Late', 'Excused', 'Absent'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) => setState(() => _status = val!),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppConstants.accentColor),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSubmitting ? null : () {
                            if (_formKey.currentState!.validate() && _selectedStudent != null) {
                              context.read<DashboardBloc>().add(
                                SubmitManualAttendanceRequested(
                                  userId: _selectedStudent!,
                                  date: _selectedDate.toLocal().toString().split(' ')[0],
                                  time: _selectedTime.format(context),
                                  status: _status.toLowerCase(), // Send lowercase 'present', 'absent' etc to match AWS enum
                                )
                              );
                            }
                          },
                          child: _isSubmitting 
                             ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                             : const Text('Confirm Record', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
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
    );
  }
}
