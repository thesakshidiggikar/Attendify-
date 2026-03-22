import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this line
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/pages/admin_dashboard_page.dart';
import 'features/dashboard/presentation/pages/employee_dashboard_page.dart';
import 'features/dashboard/data/repositories/dashboard_repository_impl.dart';
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
            dashboardRepository: DashboardRepositoryImpl(
              apiBaseUrl: dotenv.env['API_BASE_URL'] ?? '',
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
          '/admin': (_) => AdminDashboardPage(),
          '/employee': (context) => BlocProvider.value(
            value: BlocProvider.of<DashboardBloc>(context),
            child: EmployeeDashboardPage(),
          ),
        },
      ),
    );
  }
} 