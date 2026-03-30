import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/attendance/presentation/pages/attendance_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or failed to load");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(
            authRepository: AuthRepositoryImpl(),
          )..add(CheckMachineStatus()), // Check if already activated on startup
        ),
      ],
      child: MaterialApp(
        title: 'FaceAttend Kiosk',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
        ),
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is MachineAuthenticated) {
              return const AttendancePage();
            }
            return const LoginPage();
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/scanner': (context) => const AttendancePage(),
        },
      ),
    );
  }
}
