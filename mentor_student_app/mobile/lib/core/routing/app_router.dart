import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/mentor/presentation/screens/assigned_students_screen.dart';
import '../../features/mentor/presentation/screens/mentor_dashboard_screen.dart';
import '../../features/mentor/presentation/screens/student_detail_screen.dart';
import '../../features/student/presentation/screens/profile_setup_screen.dart';
import '../../features/student/presentation/screens/student_dashboard_screen.dart';
import '../auth/auth_provider.dart';
import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: ValueNotifier(authState),
    redirect: (context, state) {
      final status = authState.status;
      final isLoggingIn = state.uri.path == '/login';

      if (status == AuthStatus.loading || status == AuthStatus.uninitialized) {
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      // User is authenticated - determine target route based on role
      final user = authState.user;
      if (user == null) return '/login';

      String targetRoute = '/login';
      if (user.role == 'student') {
        targetRoute = user.isProfileComplete ? '/student/dashboard' : '/student/profile-setup';
      } else if (user.role == 'mentor') {
        targetRoute = '/mentor/dashboard';
      } else if (user.role == 'admin' || user.role == 'hod') {
        targetRoute = '/admin/dashboard';
      }

      // If user is already on their correct role target, do not redirect
      if (state.uri.path == targetRoute) return null;

      // If user is at /login or an invalid route, redirect to their role home
      if (isLoggingIn || !state.uri.path.startsWith('/${user.role}')) {
        return targetRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student/profile-setup',
        builder: (context, state) => const StudentProfileSetupScreen(),
      ),
      GoRoute(
        path: '/student/dashboard',
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: '/mentor/dashboard',
        builder: (context, state) => const MentorDashboardScreen(),
      ),
      GoRoute(
        path: '/mentor/students',
        builder: (context, state) => const AssignedStudentsScreen(),
      ),
      GoRoute(
        path: '/mentor/students/:id',
        builder: (context, state) {
          final studentId = state.pathParameters['id'] ?? '';
          return StudentDetailScreen(studentId: studentId);
        },
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Page not found'),
      ),
    ),
  );
});
