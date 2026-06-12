import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/design_tokens.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(AppTheme.getTheme(brightness: Brightness.light, designMode: DesignMode.classic));

  void toggleTheme(Brightness brightness) {
    emit(AppTheme.getTheme(brightness: brightness, designMode: DesignMode.classic));
  }
}
