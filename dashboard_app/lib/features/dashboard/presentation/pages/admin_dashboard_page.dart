import 'dart:async';
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
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
    // Auto-refresh every 15 seconds for real-time responsiveness
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _triggerRefresh();
    });
  }

  void _triggerRefresh() {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    context.read<DashboardBloc>().add(FetchDashboardStatsRequested());
    // Reset the spinning indicator after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildPremiumSidebar(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
              ),
              child: Column(
                children: [
                   _buildPremiumHeader(),
                   Expanded(
                     child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeInOutCubic,
                        child: _buildContent(selectedIndex),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(4, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Text(
                  'FaceAttend',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          _SidebarItem(
            icon: Icons.dashboard_customize_rounded,
            label: 'Overview',
            isSelected: selectedIndex == 0,
            onTap: () => setState(() => selectedIndex = 0),
          ),
          _SidebarItem(
            icon: Icons.person_search_rounded,
            label: 'Students',
            isSelected: selectedIndex == 1,
            onTap: () {
              setState(() => selectedIndex = 1);
              context.read<DashboardBloc>().add(FetchAllEmployeesRequested());
            },
          ),
          _SidebarItem(
            icon: Icons.auto_graph_rounded,
            label: 'Analytics',
            isSelected: selectedIndex == 2,
            onTap: () => setState(() => selectedIndex = 2),
          ),
          _SidebarItem(
            icon: Icons.verified_user_rounded,
            label: 'Manual Registry',
            isSelected: selectedIndex == 3,
            onTap: () => setState(() => selectedIndex = 3),
          ),
          _SidebarItem(
            icon: Icons.person_add_rounded,
            label: 'Enrollment',
            isSelected: selectedIndex == 5,
            onTap: () => setState(() => selectedIndex = 5),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                   const Text('System Status', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                       const SizedBox(width: 8),
                       const Text('ACTIVE CLOUD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                     ],
                   )
                ],
              ),
            ),
          ),
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
        String userRole = 'Administrator';
        if (state is AuthAuthenticated) {
          userName = state.user.name;
          userRole = state.user.role == 'admin' ? 'Super Admin' : 'Staff Admin';
        }

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
              ),
              child: Row(
                children: [
                   Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'SESSION: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} IST',
                         style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF6366F1), letterSpacing: 1.5),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         _getPageTitle(selectedIndex),
                         style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                       ),
                     ],
                   ),
                   const Spacer(),
                   // Connection Status Badge
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                     decoration: BoxDecoration(
                       color: const Color(0xFF10B981).withOpacity(0.1),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Row(
                       children: [
                         Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                         const SizedBox(width: 8),
                         const Text('DATABASE SYNCED', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.w900)),
                       ],
                     ),
                   ),
                   const SizedBox(width: 24),
                   _buildHeaderAction(Icons.search_rounded),
                   const SizedBox(width: 12),
                   _buildHeaderAction(Icons.notifications_none_rounded),
                   const SizedBox(width: 24),
                   Row(
                     children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                            Text(userRole, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF6366F1), width: 2),
                          ),
                          child: const CircleAvatar(
                             radius: 18,
                             backgroundColor: Color(0xFFF1F5F9),
                             child: Icon(Icons.person_rounded, color: Color(0xFF6366F1), size: 20),
                          ),
                        ),
                     ],
                   )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
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
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardStatsLoadInProgress || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator(color: Color(AppConstants.primaryColor)));
        }

        int totalCount = 0;
        int presentCount = 0;
        int absentCount = 0;
        List<Employee> allStudents = [];

        if (state is DashboardStatsLoadSuccess) {
          totalCount = state.totalStudents;
          presentCount = state.presentToday;
          absentCount = state.absentToday;
          allStudents = state.employees;
        }

        final startIndex = _currentPage * _itemsPerPage;
        final pagedStudents = allStudents.skip(startIndex).take(_itemsPerPage).toList();
        final maxPages = (allStudents.length / _itemsPerPage).ceil();

        return SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Cards
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      title: 'Total Students', 
                      value: '$totalCount', 
                      icon: Icons.group_rounded, 
                      gradient: const [Color(0xFF6366F1), Color(0xFF818CF8)],
                    )),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(
                      title: 'Present Today', 
                      value: '$presentCount', 
                      icon: Icons.fingerprint_rounded, 
                      gradient: const [Color(0xFF10B981), Color(0xFF34D399)],
                    )),
                    const SizedBox(width: 24),
                    Expanded(child: _StatCard(
                      title: 'Absent Today', 
                      value: '$absentCount', 
                      icon: Icons.person_off_rounded, 
                      gradient: const [Color(0xFFF43F5E), Color(0xFFFB7185)],
                    )),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Attendance Table Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Attendance Register',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Real-time updates from Kiosk Terminal',
                            style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Pagination Controls
                      if (maxPages > 1) 
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withOpacity(0.05)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_currentPage + 1} / $maxPages',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                                visualDensity: VisualDensity.compact,
                                onPressed: _currentPage < maxPages - 1 ? () => setState(() => _currentPage++) : null,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Modern Data Grid Body
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 40, offset: const Offset(0, 20)),
                    ],
                  ),
                  child: Column(
                    children: [
                       // Table Header Labels
                       Padding(
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                         child: Row(
                           children: const [
                             Expanded(flex: 3, child: Text('PRN & STUDENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                             Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5))),
                             Expanded(flex: 2, child: Center(child: Text('VERIFICATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)))),
                             Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text('IST TIME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.5)))),
                           ],
                         ),
                       ),
                       const Divider(height: 1),
                       ...pagedStudents.map((emp) {
                         final isPresent = emp.attendanceStatus == 'Present';
                         return Container(
                           height: 80,
                           decoration: BoxDecoration(
                             border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.02))),
                           ),
                           child: Row(
                             children: [
                               Expanded(
                                 flex: 3,
                                 child: Row(
                                   children: [
                                     Container(
                                       width: 44,
                                       height: 44,
                                       decoration: BoxDecoration(
                                         gradient: LinearGradient(colors: [const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF4F46E5).withOpacity(0.05)]),
                                         borderRadius: BorderRadius.circular(12),
                                       ),
                                       child: Center(child: Text(emp.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w900))),
                                     ),
                                     const SizedBox(width: 16),
                                     Column(
                                       mainAxisAlignment: MainAxisAlignment.center,
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                          Text(emp.username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1E293B))),
                                          Text('ID: ${emp.cognitoUserId}', style: TextStyle(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
                                       ],
                                     ),
                                   ],
                                 ),
                               ),
                               Expanded(
                                 flex: 2,
                                 child: Text(emp.department, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                               ),
                               Expanded(
                                 flex: 2,
                                 child: Center(child: _buildStatusBadge(emp.attendanceStatus)),
                               ),
                               Expanded(
                                 flex: 2,
                                 child: Column(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   crossAxisAlignment: CrossAxisAlignment.end,
                                   children: [
                                      Text(
                                        _formatTimestamp(emp.attendanceTime),
                                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: isPresent ? const Color(0xFF10B981) : const Color(0xFF64748B).withOpacity(0.5)),
                                      ),
                                      if (isPresent) const Text('STABLE CONNECT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                                   ],
                                 ),
                               ),
                             ],
                           ),
                         );
                       }).toList(),
                       const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
  
                const Text(
                  'Quick Access',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _QuickActionCard(
                      title: 'Manual Mark',
                      icon: Icons.history_edu_rounded,
                      onTap: () => setState(() => selectedIndex = 3),
                    ),
                    const SizedBox(width: 20),
                    _QuickActionCard(
                      title: 'Enroll Student',
                      icon: Icons.person_add_alt_rounded,
                      onTap: () => setState(() => selectedIndex = 5),
                    ),
                    const SizedBox(width: 20),
                    _QuickActionCard(
                      title: 'Analytics Subsystem',
                      icon: Icons.analytics_rounded,
                      onTap: () => setState(() => selectedIndex = 2),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'present':
        color = const Color(0xFF10B981); // Emerald
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        break;
      case 'late':
        color = const Color(0xFFF59E0B); // Amber
        bgColor = const Color(0xFFF59E0B).withOpacity(0.12);
        break;
      case 'absent':
        color = const Color(0xFFEF4444); // Rose
        bgColor = const Color(0xFFEF4444).withOpacity(0.12);
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '--:--';
    try {
      final dt = DateTime.parse(timestamp).toUtc().add(const Duration(hours: 5, minutes: 30));
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return timestamp;
    }
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
        ? const Color(0xFFF43F5E) 
        : widget.isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B);
    
    final bgColor = widget.isSelected 
        ? const Color(0xFF6366F1).withOpacity(0.08) 
        : isHovered ? Colors.black.withOpacity(0.02) : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => isHovered = true),
        onExit: (_) => setState(() => isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: color, size: 22),
                const SizedBox(width: 14),
                Text(
                   widget.label,
                   style: TextStyle(
                     color: widget.isSelected ? const Color(0xFF1E293B) : (widget.isLogout ? const Color(0xFFF43F5E) : const Color(0xFF64748B)),
                     fontWeight: widget.isSelected ? FontWeight.w800 : FontWeight.w600,
                     fontSize: 14,
                   ),
                ),
                if (widget.isSelected) ...[
                   const Spacer(),
                   Container(
                     width: 6,
                     height: 6,
                     decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                   ),
                ],
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
  final List<Color> gradient;

  const _StatCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(color: gradient.first.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(icon, color: gradient.first.withOpacity(0.05), size: 80),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: const Color(0xFF1E293B).withOpacity(0.5), fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF6366F1), size: 28),
              ),
              const SizedBox(height: 16),
              const Text('ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E293B), fontSize: 13)),
            ],
          ),
        ),
       ),
    );
  }
}