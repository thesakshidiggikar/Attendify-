import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/employee.dart';

class EmployeeDashboardPage extends StatefulWidget {
  @override
  State<EmployeeDashboardPage> createState() => _EmployeeDashboardPageState();
}

class _EmployeeDashboardPageState extends State<EmployeeDashboardPage> {
  int selectedIndex = 0;
  bool _employeesLoaded = false;

  @override
  void initState() {
    super.initState();
    // Optionally, fetch employees on load if Employees tab is default
  }

  @override
  Widget build(BuildContext context) {
    // Always trigger fetch when Employees section is selected and not loaded
    if (selectedIndex == 1 && !_employeesLoaded) {
      context.read<DashboardBloc>().add(FetchAllEmployeesRequested());
      _employeesLoaded = true;
    } else if (selectedIndex != 1 && _employeesLoaded) {
      _employeesLoaded = false;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
              if (index == 1) {
                // Employees section
                context.read<DashboardBloc>().add(FetchAllEmployeesRequested());
              }
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Employees'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.event_note),
                label: Text('Attendance'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.beach_access),
                label: Text('Leaves'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('Profile'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help_outline),
                label: Text('Help'),
              ),
            ],
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Builder(
                builder: (context) {
                  if (selectedIndex == 1) {
                    // Employees section: show employee list with BlocListener and Centered/SizedBox
                    return Center(
                      child: SizedBox(
                        width: 700,
                        child: BlocListener<DashboardBloc, DashboardState>(
                          listener: (context, state) {
                            if (state is EmployeesLoadFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to load employees: ${state.error}')),
                              );
                            }
                          },
                          child: BlocBuilder<DashboardBloc, DashboardState>(
                            builder: (context, state) {
                              if (state is EmployeesLoadInProgress) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (state is EmployeesLoadFailure) {
                                return Center(child: Text('Failed to load employees: ${state.error}'));
                              } else if (state is EmployeesLoadSuccess) {
                                final employees = state.employees;
                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Employee Attendance', style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: 12),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: TextField(
                                            decoration: const InputDecoration(
                                              hintText: 'Search employees...',
                                              prefixIcon: Icon(Icons.search),
                                              border: InputBorder.none,
                                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade300),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: const [
                                                    Expanded(child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    SizedBox(width: 16),
                                                    Expanded(child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                                    SizedBox(width: 16),
                                                    Expanded(child: Text('Profile', style: TextStyle(fontWeight: FontWeight.bold))),
                                                  ],
                                                ),
                                              ),
                                              Divider(height: 1, color: Colors.grey.shade300),
                                              ...employees.map((e) => Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                child: Row(
                                                  children: [
                                                    Expanded(child: Text(e.username)),
                                                    SizedBox(width: 16),
                                                    Expanded(child: Text(e.cognitoUserId, style: TextStyle(color: Colors.grey[600]))),
                                                    SizedBox(width: 16),
                                                    Expanded(
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey[200],
                                                            borderRadius: BorderRadius.circular(16),
                                                          ),
                                                          child: Text(
                                                            e.profile,
                                                            style: const TextStyle(
                                                              color: Colors.black87,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              // Default: show nothing
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    );
                  } else if (selectedIndex == 2) {
                    // Attendance section: show attendance calendar
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Attendance', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 24),
                          // Calendar placeholder
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Attendance Calendar', style: Theme.of(context).textTheme.titleMedium),
                                      Row(
                                        children: [
                                          _buildLegendDot(Colors.green, 'Present'),
                                          _buildLegendDot(Colors.red, 'Absent'),
                                          _buildLegendDot(Colors.yellow, 'Half-day'),
                                          _buildLegendDot(Colors.blue, 'Holiday'),
                                          _buildLegendDot(Colors.orange, 'Leave'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 320,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: const Center(child: Text('Calendar Placeholder')),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Default: show profile/leave cards
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Leave Application
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Apply for Leave', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Type',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Date Range',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Reason',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      ElevatedButton(
                                        onPressed: () {},
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  Text('Leave Requests', style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 8),
                                  DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Type')),
                                      DataColumn(label: Text('Date Range')),
                                      DataColumn(label: Text('Reason')),
                                      DataColumn(label: Text('Status')),
                                    ],
                                    rows: const [
                                      DataRow(cells: [
                                        DataCell(Text('Sick')),
                                        DataCell(Text('2024-06-01 to 2024-06-02')),
                                        DataCell(Text('Fever')),
                                        DataCell(Text('Approved')),
                                      ]),
                                      DataRow(cells: [
                                        DataCell(Text('Casual')),
                                        DataCell(Text('2024-06-10')),
                                        DataCell(Text('Personal Work')),
                                        DataCell(Text('Pending')),
                                      ]),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Profile Summary
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              String userName = 'Employee Name';
                              String userId = 'EMP001';
                              if (state is AuthAuthenticated) {
                                userName = state.user.name;
                                userId = state.user.id;
                              }
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 48)),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(userName, style: Theme.of(context).textTheme.titleLarge),
                                            const SizedBox(height: 8),
                                            Text('ID: $userId'),
                                            const SizedBox(height: 8),
                                            const Text('Individual Stats Integration Pending', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
} 