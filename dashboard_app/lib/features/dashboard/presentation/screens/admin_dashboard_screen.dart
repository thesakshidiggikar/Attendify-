import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/employee_registration_form.dart';
import '../bloc/dashboard_bloc.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<EmployeeRegistrationFormState> _formKey = GlobalKey<EmployeeRegistrationFormState>();
  int selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
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
                label: Text('Leaves'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.help_outline),
                label: Text('Help'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_add),
                label: Text('Register'),
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
                    // Employees section
                    return Center(
                      child: SizedBox(
                        width: 600,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Employees', style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: 'Search by name or profile',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (query) {
                                context.read<DashboardBloc>().add(SearchEmployeesChanged(query));
                              },
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: BlocConsumer<DashboardBloc, DashboardState>(
                                listener: (context, state) {
                                  if (state is EmployeeDeleteSuccess) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Employee deleted successfully!')),
                                    );
                                  } else if (state is EmployeeDeleteFailure) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Delete failed: ${state.error}')),
                                    );
                                  }
                                },
                                builder: (context, state) {
                                  if (state is EmployeesLoadInProgress || state is EmployeeDeleteInProgress) {
                                    return Center(child: CircularProgressIndicator());
                                  } else if (state is EmployeesLoadFailure) {
                                    return Center(child: Text('Failed to load employees: ${state.error}'));
                                  } else if (state is EmployeesLoadSuccess || state is EmployeeDeleteSuccess || state is EmployeeDeleteFailure) {
                                    final employees = (state is EmployeesLoadSuccess)
                                        ? state.employees
                                        : (state is EmployeeDeleteSuccess)
                                            ? state.employees
                                            : (state as EmployeeDeleteFailure).employees;
                                    if (employees.isEmpty) {
                                      return Center(child: Text('No employees found.'));
                                    }
                                    return ListView.separated(
                                      itemCount: employees.length,
                                      separatorBuilder: (_, __) => Divider(),
                                      itemBuilder: (context, index) {
                                        final emp = employees[index];
                                        return ListTile(
                                          leading: CircleAvatar(child: Text(emp.username[0].toUpperCase())),
                                          title: Text(emp.username),
                                          subtitle: Text('Profile: ${emp.profile} | Attendance: ${emp.attendanceStatus}'),
                                          trailing: IconButton(
                                            icon: Icon(Icons.delete, color: Colors.red),
                                            tooltip: 'Delete Employee',
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title: Text('Delete Employee'),
                                                  content: Text('Are you sure you want to delete ${emp.username}?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(ctx).pop(),
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(ctx).pop();
                                                        context.read<DashboardBloc>().add(DeleteEmployeeRequested(emp.username));
                                                      },
                                                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    );
                                  }
                                  return SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (selectedIndex == 5) {
                    // Register section only
                    return Center(
                      child: SizedBox(
                        width: 500,
                        child: BlocListener<DashboardBloc, DashboardState>(
                          listener: (context, state) {
                            if (state is RegisterEmployeeSuccess) {
                              _formKey.currentState?.clearForm();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Employee registered successfully!')),
                              );
                            } else if (state is RegisterEmployeeFailure) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Registration failed: \n${state.error}')),
                              );
                            }
                          },
                          child: BlocBuilder<DashboardBloc, DashboardState>(
                            builder: (context, state) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EmployeeRegistrationForm(
                                    key: _formKey,
                                    onRegister: ({
                                      required String username,
                                      required String email,
                                      required String password,
                                      required String profile,
                                      required image,
                                    }) {
                                      context.read<DashboardBloc>().add(
                                        RegisterEmployeeRequested(
                                          username: username,
                                          email: email,
                                          password: password,
                                          profile: profile,
                                          image: image,
                                        ),
                                      );
                                    },
                                  ),
                                  if (state is RegisterEmployeeInProgress)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Center(child: Text('Select a section from the sidebar.'));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Employee model for demo
class Employee {
  final String name;
  final String id;
  final String status;
  Employee({required this.name, required this.id, required this.status});
}

final List<Employee> demoEmployees = [
  Employee(name: 'Owen Turner', id: 'EMP001', status: 'Present'),
  Employee(name: 'Chloe Bennett', id: 'EMP002', status: 'Absent'),
  Employee(name: 'Lucas Carter', id: 'EMP003', status: 'Present'),
  Employee(name: 'Sophia Evans', id: 'EMP004', status: 'Late'),
  Employee(name: 'Noah Foster', id: 'EMP005', status: 'Present'),
]; 