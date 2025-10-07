import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import '../providers/auth_provider.dart';
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
  
  final List<String> languages = ['English', 'Sinhala', 'Tamil'];

  // Colorful liquid colors for each page
  final List<Color> _pageColors = [
    const Color(0xFF4CB050), // Green for language selection
    const Color(0xFF6C5CE7), // Purple for feature 1
    const Color(0xFF00B894), // Teal for feature 2
    const Color(0xFFE17055), // Orange for feature 3
    const Color(0xFF74B9FF), // Blue for feature 4
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
      body:       LiquidSwipe(
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
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature2_title', _selectedLanguage),
        description: getLocalizedText('feature2_desc', _selectedLanguage),
        icon: Icons.shopping_cart,
        pageIndex: 2,
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature3_title', _selectedLanguage),
        description: getLocalizedText('feature3_desc', _selectedLanguage),
        icon: Icons.analytics,
        pageIndex: 3,
      ),
      _buildFeaturePage(
        title: getLocalizedText('feature4_title', _selectedLanguage),
        description: getLocalizedText('feature4_desc', _selectedLanguage),
        icon: Icons.support_agent,
        pageIndex: 4,
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
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _pageColors[0].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.agriculture,
                          size: 50,
                          color: _pageColors[0],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        getLocalizedText('welcome_title', _selectedLanguage),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _pageColors[0],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      
                      // Subtitle
                      Text(
                        getLocalizedText('select_language', _selectedLanguage),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Language options
                      ...languages.map((language) => _buildLanguageOption(language)),
                      
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
            color: isSelected ? _pageColors[0].withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _pageColors[0] : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
                      
                      // Feature icon
                      Container(
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
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _pageColors[pageIndex],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      
                      // Feature description
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
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
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicators
          Row(
            children: List.generate(5, (index) {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Colors.white
                      : Colors.white.withOpacity(0.3),
                ),
              );
            }),
          ),
          
          // Animated circular next button
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
          border: Border.all(
            color: Colors.white,
            width: 3.0,
          ),
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
    case 'Sinhala':
      return sinhalaTexts[key] ?? key;
    case 'Tamil':
      return tamilTexts[key] ?? key;
    default:
      return englishTexts[key] ?? key;
  }
}
