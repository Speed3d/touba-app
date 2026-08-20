import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import 'login_screen.dart';
import '../main/main_screen.dart';
import '../../../core/utils/tooba_snack_bar.dart';

import '../../../core/error/auth_error_resolver.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ToobaSnackBar.error(context, AuthErrorResolver.resolve(context, state.message));
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is AuthAuthenticated || state is AuthVisitor) {
          return const MainScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
