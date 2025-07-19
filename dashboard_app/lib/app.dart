import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'features/dashboard/presentation/screens/employee_dashboard_screen.dart';
import 'features/dashboard/data/repositories/employee_registration_repository.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'di/injection_container.dart' as di;
import 'features/auth/domain/repositories/auth_repository.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository: di.sl<AuthRepository>())..add(AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) => DashboardBloc(
            registrationRepository: EmployeeRegistrationRepository(
              apiBaseUrl: 'https://wny1io6xre.execute-api.ap-south-1.amazonaws.com/dev',
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'FaceAttend',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SplashScreen(),
        routes: {
          '/login': (_) => LoginScreen(),
          '/admin': (_) => AdminDashboardScreen(),
          '/employee': (context) => BlocProvider.value(
            value: BlocProvider.of<DashboardBloc>(context),
            child: EmployeeDashboardScreen(),
          ),
        },
      ),
    );
  }
} 