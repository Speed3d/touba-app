import 'package:flutter/material.dart';
import '../../../data/services/preferences_service.dart';
import '../auth/auth_wrapper.dart';
import '../onboarding/onboarding_screen.dart';
import '../../widgets/core/decorated_background.dart';
import '../../../l10n/app_localizations.dart';

/// 📝 HINT AR: شاشة البداية — تصميم عصري مطابق لملف التصميم الجديد.
/// تحتوي على شعار في المنتصف وحلقات متراقصة (Pulse Animation).
/// تنتقل تلقائياً بعد ثانيتين تقريباً إلى شاشات التعريف أو واجهة المستخدم.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    // 📝 HINT AR: متحكم الحلقات المتراقصة (تستمر بالحركة ما دامت الشاشة معروضة)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 📝 HINT AR: متحكم ظهور العناصر (Fade & Slide Up)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _goNext();
  }

  Future<void> _goNext() async {
    // 📝 HINT AR: الانتظار قليلاً لرؤية الحركات البصرية ثم الانتقال
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    
    final next = PreferencesService.onboardingSeen
        ? const AuthWrapper()
        : const OnboardingScreen();
        
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => next,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // 📝 HINT AR: استخدام ألوان محددة للتصميم الجديد لتكون جذابة في الوضعين
    final Color ringColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBackground(
        showOrbs: true,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _fadeController]),
            builder: (context, child) {
              // حساب قيم التمدد (Scale) للحلقات لتبدو نابضة
              final pulseVal = _pulseController.value;
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📝 HINT AR: الشعار مع الحلقات المتراقصة خلفه
                  SizedBox(
                    width: 188,
                    height: 188,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // الحلقة الخارجية
                        Transform.scale(
                          scale: 1.0 + (pulseVal * 0.15),
                          child: Container(
                            width: 188,
                            height: 188,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ringColor.withValues(alpha: 0.05 + (1 - pulseVal) * 0.05),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // الحلقة الوسطى
                        Transform.scale(
                          scale: 1.0 + (pulseVal * 0.1),
                          child: Container(
                            width: 148,
                            height: 148,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ringColor.withValues(alpha: 0.1 + (1 - pulseVal) * 0.05),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // الحلقة الداخلية
                        Transform.scale(
                          scale: 1.0 + (pulseVal * 0.05),
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ringColor.withValues(alpha: 0.18 + (1 - pulseVal) * 0.05),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        // الشعار (المربع المنحني مع أيقونة الكرة)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ringColor,
                                theme.colorScheme.primaryContainer.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: ringColor.withValues(alpha: 0.45),
                                blurRadius: 52,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              '⚽',
                              style: TextStyle(fontSize: 38),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  
                  // 📝 HINT AR: النصوص تظهر بتأثير التلاشي والانزلاق للأعلى
                  Opacity(
                    opacity: _fade.value,
                    child: Transform.translate(
                      offset: Offset(0, _slide.value),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.appTitle,
                            style: TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -3,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.toubaFootball,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF1E4030) : const Color(0xFF86EFAC),
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.iraqiAmateurFootballPlatform,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
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
  }
}
