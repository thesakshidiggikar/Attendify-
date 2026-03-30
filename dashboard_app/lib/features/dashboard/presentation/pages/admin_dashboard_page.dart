import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/employee_registration_form.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/employee.dart';
import 'attendance_analytics_page.dart';
import 'manual_attendance_page.dart';
import 'package:dashboard_app/core/constants/app_constants.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  final GlobalKey<EmployeeRegistrationFormState> _formKey = GlobalKey<EmployeeRegistrationFormState>();
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppConstants.backgroundColor),
      body: Row(
        children: [
          _buildPremiumSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildPremiumHeader(),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
                    child: Container(
                      color: const Color(AppConstants.surfaceColor),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildContent(selectedIndex),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSidebar() {
    return Container(
      width: 280,
      color: const Color(AppConstants.sidebarColor),
      child: Column(
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(AppConstants.primaryColor), Color(AppConstants.primaryLight)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(AppConstants.primaryColor).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                    ]
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Text(
                  'FaceAttend',
                  style: TextStyle(
                    color: Color(AppConstants.textPrimary),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),
          _SidebarItem(
            icon: Icons.grid_view_rounded,
            label: 'Overview',
            isSelected: selectedIndex == 0,
            onTap: () => setState(() => selectedIndex = 0),
          ),
          _SidebarItem(
            icon: Icons.people_alt_rounded,
            label: 'Students',
            isSelected: selectedIndex == 1,
            onTap: () {
              setState(() => selectedIndex = 1);
              context.read<DashboardBloc>().add(FetchAllEmployeesRequested());
            },
          ),
          _SidebarItem(
            icon: Icons.insights_rounded,
            label: 'Analytics',
            isSelected: selectedIndex == 2,
            onTap: () => setState(() => selectedIndex = 2),
          ),
          _SidebarItem(
            icon: Icons.edit_calendar_rounded,
            label: 'Mark Attendance',
            isSelected: selectedIndex == 3,
            onTap: () => setState(() => selectedIndex = 3),
          ),
          _SidebarItem(
            icon: Icons.person_add_alt_1_rounded,
            label: 'Add Student',
            isSelected: selectedIndex == 5,
            onTap: () => setState(() => selectedIndex = 5),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            isSelected: false,
            isLogout: true,
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String userName = 'User';
        String userRole = 'Teacher';

        if (state is AuthAuthenticated) {
          userName = state.user.name;
          userRole = state.user.role == 'admin' ? 'Administrator' : 'Teacher';
        }

        return Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          color: const Color(AppConstants.backgroundColor),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning, $userRole',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(AppConstants.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPageTitle(selectedIndex),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(AppConstants.textPrimary),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: Color(AppConstants.primaryLight),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(AppConstants.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard Overview';
      case 1: return 'Student Management';
      case 2: return 'Student Analytics';
      case 3: return 'Mark Attendance';
      case 5: return 'Add New Student';
      default: return 'Dashboard';
    }
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0: return _buildOverviewSection();
      case 1: return _buildStudentsSection();
      case 2: return const AttendanceAnalyticsPage();
      case 3: return const ManualAttendancePage();
      case 5: return _buildRegistrationSection();
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildOverviewSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      BlocBuilder<DashboardBloc, DashboardState>(
                        builder: (context, state) {
                          if (state is DashboardStatsLoadInProgress || state is DashboardInitial) {
                            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(AppConstants.primaryColor))));
                          }
                          
                          int total = 0;
                          int present = 0;
                          int absent = 0;
                          
                          if (state is DashboardStatsLoadSuccess) {
                            total = state.totalStudents;
                            present = state.presentToday;
                            absent = state.absentToday;
                          } else if (state is EmployeesLoadSuccess) {
                            total = state.employees.length;
                            present = 0; 
                            absent = total;
                          } else if (state is EmployeeDeleteSuccess) {
                            total = state.employees.length;
                            present = 0;
                            absent = total;
                          } else if (state is DashboardStatsLoadFailure) {
                            return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Failed to connect to AWS Database: ${state.error}', style: const TextStyle(color: Colors.red))));
                          }

                          return Row(
                            children: [
                              Expanded(child: _StatCard(title: 'Total Students', value: '$total', icon: Icons.people_rounded, color: Colors.indigoAccent)),
                              const SizedBox(width: 24),
                              Expanded(child: _StatCard(title: 'Present Today', value: '$present', icon: Icons.check_circle_rounded, color: Colors.green)),
                              const SizedBox(width: 24),
                              Expanded(child: _StatCard(title: 'Absent Today', value: '$absent', icon: Icons.cancel_rounded, color: Colors.redAccent)),
                            ],
                          );
                        },
                      ), const SizedBox(height: 48),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _QuickActionCard(
                title: 'Mark Attendance',
                icon: Icons.edit_calendar_rounded,
                onTap: () => setState(() => selectedIndex = 3),
              ),
              const SizedBox(width: 24),
              _QuickActionCard(
                title: 'Add Student',
                icon: Icons.person_add_rounded,
                onTap: () => setState(() => selectedIndex = 5),
              ),
              const SizedBox(width: 24),
              _QuickActionCard(
                title: 'View Analytics',
                icon: Icons.insights_rounded,
                onTap: () => setState(() => selectedIndex = 2),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: Color(AppConstants.textSecondary)),
                hintText: 'Search students by name or ID...',
                hintStyle: TextStyle(color: Color(AppConstants.textSecondary)),
                border: InputBorder.none,
              ),
              onChanged: (q) => context.read<DashboardBloc>().add(SearchEmployeesChanged(q)),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                if (state is DashboardStatsLoadInProgress || state is EmployeesLoadInProgress) {
                  return const Center(child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)));
                }
                if (state is EmployeesLoadSuccess || state is DashboardStatsLoadSuccess) {
                  final employees = state is EmployeesLoadSuccess 
                      ? state.employees 
                      : (state as DashboardStatsLoadSuccess).employees;
                      
                  if (employees.isEmpty) {
                    return _buildEmptyState('No students found.');
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      mainAxisExtent: 100,
                    ),
                    itemCount: employees.length,
                    itemBuilder: (context, i) {
                      final emp = employees[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(AppConstants.primaryLight).withOpacity(0.15),
                              child: Text(
                                emp.username.isNotEmpty ? emp.username[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Color(AppConstants.primaryColor),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    emp.username,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(AppConstants.textPrimary)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    emp.profile,
                                    style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(emp.username, emp.cognitoUserId),
                              tooltip: 'Remove Student',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return _buildEmptyState('Search for students or add new ones.');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 16)),
        ],
      ),
    );
  }

  String _calculateNextStudentId(List<Employee> employees) {
    if (employees.isEmpty) return 'STUD001';
    
    int maxId = 0;
    final idRegex = RegExp(r'STUD(\d+)');
    
    for (var emp in employees) {
      final match = idRegex.firstMatch(emp.cognitoUserId);
      if (match != null) {
        final idNum = int.tryParse(match.group(1)!);
        if (idNum != null && idNum > maxId) {
          maxId = idNum;
        }
      }
    }
    
    final nextId = maxId + 1;
    return 'STUD${nextId.toString().padLeft(3, '0')}';
  }

  Widget _buildRegistrationSection() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        List<Employee> employees = [];
        if (state is DashboardStatsLoadSuccess) {
          employees = state.employees;
        } else if (state is EmployeesLoadSuccess) {
          employees = state.employees;
        } else if (state is EmployeeDeleteSuccess) {
          employees = state.employees;
        }

        final nextId = _calculateNextStudentId(employees);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Container(
              width: 800,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
                child: BlocConsumer<DashboardBloc, DashboardState>(
                listener: (context, state) {
                  if (state is RegisterEmployeeSuccess || state is EmployeeDeleteSuccess || state is ManualAttendanceSubmitSuccess) {
                    // Automatically refresh stats after any change
                    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
                  }
                  if (state is RegisterEmployeeSuccess) {
                    _formKey.currentState?.clearForm();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Student added successfully!'),
                        backgroundColor: const Color(AppConstants.accentColor),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      )
                    );
                  }
                },
                builder: (context, state) {
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Student Details',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(AppConstants.textPrimary)),
                          ),
                          const SizedBox(height: 32),
                          EmployeeRegistrationForm(
                            key: _formKey,
                            nextStudentId: nextId,
                            onRegister: ({
                              required studentId, 
                              required fullName, 
                              required password, 
                              required department, 
                              required image
                            }) {
                              context.read<DashboardBloc>().add(RegisterEmployeeRequested(
                                userId: studentId,
                                fullName: fullName, 
                                email: '', // No longer in UI
                                password: password, 
                                profile: 'student', // Default
                                department: department,
                                image: image,
                              ));
                            },
                          ),
                        ],
                      ),
                      if (state is RegisterEmployeeInProgress)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withOpacity(0.7),
                            child: const Center(
                              child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(String name, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Student', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $name ($userId) from the system? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Cancel', style: TextStyle(color: Color(AppConstants.textSecondary)))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<DashboardBloc>().add(DeleteEmployeeRequested(userId));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isLogout;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isLogout 
        ? Colors.redAccent 
        : widget.isSelected ? const Color(AppConstants.primaryColor) : const Color(AppConstants.textSecondary);
    
    final bgColor = widget.isSelected 
        ? const Color(AppConstants.primaryLight).withOpacity(0.1) 
        : isHovered ? Colors.grey.withOpacity(0.05) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: color, size: 24),
                const SizedBox(width: 16),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected ? const Color(AppConstants.primaryColor) : (widget.isLogout ? Colors.redAccent : const Color(AppConstants.textPrimary)),
                    fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Color(AppConstants.textSecondary), fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(color: Color(AppConstants.textPrimary), fontSize: 32, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({required this.title, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: const Color(AppConstants.primaryColor), size: 32),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(AppConstants.textPrimary))),
            ],
          ),
        ),
      ),
    );
  }
}