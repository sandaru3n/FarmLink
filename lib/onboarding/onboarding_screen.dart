import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../screens/auth/login_screen.dart';
import 'onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final LiquidController _liquidController = LiquidController();
  int _currentPage = 0;
  String _selectedLanguage = 'English';

  final List<String> languages = ['English', 'සිංහල', 'தமிழ்'];

  // Colorful liquid colors for each page
  final List<Color> _pageColors = [
    const Color(0xFF6BBF59), // Green for language selection
    const Color(0xFFFFB84D), // Purple for feature 1
    const Color(0xFF3FA9F5), // Teal for feature 2
    const Color(0xFFA3CB38), // Orange for feature 3
    const Color(0xFF43A047), // Blue for feature 4
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _onPageChanged(int activePageIndex) {
    setState(() {
      _currentPage = activePageIndex;
    });
  }

  void _onLanguageChanged(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _liquidController.animateToPage(page: _currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    // Save the selected language
    await languageProvider.changeLanguage(_selectedLanguage);
    
    // Mark onboarding as completed
    await authProvider.markOnboardingCompleted();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidSwipe(
        pages: _buildPages(),
        liquidController: _liquidController,
        enableSideReveal: true,
        onPageChangeCallback: _onPageChanged,
        slideIconWidget: const Icon(Icons.arrow_back_ios, color: Colors.white),
        positionSlideIcon: 0.8,
        waveType: WaveType.liquidReveal,
        fullTransitionValue: 300,
        enableLoop: false,
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildLanguageSelectionPage(),
      _buildFeaturePage(
        title: getLocalizedText('feature1_title', _selectedLanguage),
        description: getLocalizedText('feature1_desc', _selectedLanguage),
        icon: Icons.agriculture,
        pageIndex: 1,
        imagePath: 'assets/images/onboarding_images/smartfarming.png',
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature2_title', _selectedLanguage),
        description: getLocalizedText('feature2_desc', _selectedLanguage),
        icon: Icons.shopping_cart,
        pageIndex: 2,
        imagePath: 'assets/images/onboarding_images/farmmarketplace.png',
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature3_title', _selectedLanguage),
        description: getLocalizedText('feature3_desc', _selectedLanguage),
        icon: Icons.analytics,
        pageIndex: 3,
        imagePath: 'assets/images/onboarding_images/farmanalytics.png',
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature4_title', _selectedLanguage),
        description: getLocalizedText('feature4_desc', _selectedLanguage),
        icon: Icons.support_agent,
        pageIndex: 4,
        imagePath: 'assets/images/onboarding_images/farmercommunity.png',
      ),
    ];
  }

  Widget _buildLanguageSelectionPage() {
    return Container(
      color: _pageColors[0],
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    getLocalizedText('skip', _selectedLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Main content with white background
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo
                      Image.asset(
                        'assets/images/onboarding_images/fllogo.png',
                        width: 180,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Welcome to FarmLink',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _pageColors[0],
                          letterSpacing: 0.5,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        'Please select your preferred language',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      // Language options
                      ...languages.map(
                        (language) => _buildLanguageOption(language),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _selectedLanguage == language;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _onLanguageChanged(language),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? _pageColors[0].withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _pageColors[0] : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? _pageColors[0] : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? _pageColors[0] : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePage({
    required String title,
    required String description,
    required IconData icon,
    required int pageIndex,
    String? imagePath,
  }) {
    return Container(
      color: _pageColors[pageIndex],
      child: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    getLocalizedText('skip', _selectedLanguage),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Main content with white background
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Feature icon or image
                      imagePath != null
                          ? Image.asset(
                              imagePath,
                              width: 300,
                              height: 300,
                              fit: BoxFit.contain,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _pageColors[pageIndex].withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                icon,
                                size: 40,
                                color: _pageColors[pageIndex],
                              ),
                            ),
                      const SizedBox(height: 20),

                      // Feature title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: _pageColors[pageIndex],
                          letterSpacing: 0.5,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),

                      // Feature description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                          fontFamily: 'Roboto',
                        ),
                        textAlign: TextAlign.left,
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Smooth page indicator - centered at same level as white card
          AnimatedSmoothIndicator(
            activeIndex: _currentPage,
            count: 5,
            effect: ExpandingDotsEffect(
              dotColor: Colors.white.withOpacity(1),
              activeDotColor: Colors.white,
              dotHeight: 12,
              dotWidth: 12,
              spacing: 8,
              expansionFactor: 3,
            ),
          ),

          const SizedBox(height: 20),

          // Next button centered
          _buildAnimatedNextButton(),
        ],
      ),
    );
  }

  Widget _buildAnimatedNextButton() {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 3.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          _currentPage < 4 ? Icons.arrow_forward_ios : Icons.check,
          color: _pageColors[_currentPage],
          size: 24,
        ),
      ),
    );
  }
}

String getLocalizedText(String key, String language) {
  switch (language) {
    case 'සිංහල':
      return sinhalaTexts[key] ?? key;
    case 'தமிழ்':
      return tamilTexts[key] ?? key;
    default:
      return englishTexts[key] ?? key;
  }
}
