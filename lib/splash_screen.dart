import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboards/dashboard_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _farmLinkAnimationController;
  late AnimationController _fllogoAnimationController;
  late AnimationController _textAnimationController;
  
  late Animation<double> _farmLinkFadeAnimation;
  late Animation<double> _farmLinkScaleAnimation;
  late Animation<double> _fllogoFadeAnimation;
  late Animation<double> _fllogoScaleAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // FarmLink animation controller (first logo)
    _farmLinkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Fllogo animation controller (second logo)
    _fllogoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // FarmLink animations
    _farmLinkFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _farmLinkAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _farmLinkScaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _farmLinkAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Fllogo animations
    _fllogoFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fllogoAnimationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _fllogoScaleAnimation = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fllogoAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    ));

    // Text animations
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    // Start animations in sequence
    // Start both logos at the same time
    _farmLinkAnimationController.forward();
    _fllogoAnimationController.forward();
    
    // Start text animation after logos (1.2 seconds delay)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _textAnimationController.forward();
      }
    });

    // Initialize auth and navigate after 4 seconds
    Future.delayed(const Duration(seconds: 4), () async {
      if (mounted) {
        await _initializeAndNavigate();
      }
    });
  }

  Future<void> _initializeAndNavigate() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Initialize auth provider
      await authProvider.initialize();
      
      if (mounted) {
        // First, check if onboarding is completed
        final hasCompletedOnboarding = await authProvider.hasCompletedOnboarding();
        
        if (!hasCompletedOnboarding) {
          // Onboarding not completed, go to onboarding screen first
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const OnboardingScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        } else {
          // Onboarding completed, check login status
          if (authProvider.isLoggedIn) {
            // User is logged in, go to dashboard
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const DashboardRouter(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          } else {
            // User is not logged in, go to login screen
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        }
      }
    } catch (e) {
      // If there's an error, go to login screen (safer default)
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _farmLinkAnimationController.dispose();
    _fllogoAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CB050),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CB050),
              Color(0xFF45A049),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // First Logo - FarmLinkwhite.png
              AnimatedBuilder(
                animation: _farmLinkAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _farmLinkFadeAnimation,
                    child: ScaleTransition(
                      scale: _farmLinkScaleAnimation,
                      child: Image.asset(
                        'assets/images/splash_images/FarmLinkwhite.png',
                        width: 500,
                        height: 250,
                        
                      ),
                    ),
                  );
                },
              ),
              
              // Second Logo - fllogowhite.png
              AnimatedBuilder(
                animation: _fllogoAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fllogoFadeAnimation,
                    child: ScaleTransition(
                      scale: _fllogoScaleAnimation,
                      child: Image.asset(
                        'assets/images/splash_images/fllogowhite.png',
                        width: 300,
                        height: 200,
                        
                      ),
                    ),
                  );
                },
              ),
              
              // Animated Text
              AnimatedBuilder(
                animation: _textAnimationController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textFadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _textAnimationController,
                        curve: Curves.easeOut,
                      )),
                      child: Text(
                        'Smart Farming, Simple Connections',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
