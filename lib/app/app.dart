// Root Material app: wires theme, initial route, and named route builders.
import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/auth_gate_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/blog/presentation/pages/blog_detail_page.dart';
import '../features/blog/presentation/pages/blog_form_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/profile/presentation/pages/profile_edit_page.dart';
import '../features/profile/presentation/pages/profile_view_page.dart';
import 'app_theme.dart';
import 'routes.dart';

class BlogApp extends StatelessWidget {
  const BlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'InkFrame',
      theme: AppTheme.light,
      initialRoute: AppRoutes.authGate,
      routes: {
        AppRoutes.authGate: (_) => const AuthGatePage(),
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const RegisterPage(),
        AppRoutes.blogCreate: (_) => const BlogFormPage(),
        AppRoutes.blogDetail: (_) => const BlogDetailPage(),
        AppRoutes.profile: (_) => const ProfilePage(),
        AppRoutes.profileEdit: (_) => const ProfileEditPage(),
        AppRoutes.profileView: (_) => const ProfileViewPage(),
      },
    );
  }
}
