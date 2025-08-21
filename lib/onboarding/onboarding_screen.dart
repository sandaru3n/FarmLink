import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import 'onboarding_content.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'English';
  
  final List<String> languages = ['English', 'Sinhala', 'Tamil'];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onLanguageChanged(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _saveLanguageAndContinue() async {
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
      backgroundColor: const Color(0xFF4CB050),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < 4)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _saveLanguageAndContinue,
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
            
            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildPageContent(index);
                },
              ),
            ),
            
            // Bottom navigation
            _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _buildLanguageSelectionPage();
      case 1:
        return _buildFeaturePage(
          title: getLocalizedText('feature1_title', _selectedLanguage),
          description: getLocalizedText('feature1_desc', _selectedLanguage),
          icon: Icons.agriculture,
        );
      case 2:
        return _buildFeaturePage(
          title: getLocalizedText('feature2_title', _selectedLanguage),
          description: getLocalizedText('feature2_desc', _selectedLanguage),
          icon: Icons.shopping_cart,
        );
      case 3:
        return _buildFeaturePage(
          title: getLocalizedText('feature3_title', _selectedLanguage),
          description: getLocalizedText('feature3_desc', _selectedLanguage),
          icon: Icons.analytics,
        );
      case 4:
        return _buildFeaturePage(
          title: getLocalizedText('feature4_title', _selectedLanguage),
          description: getLocalizedText('feature4_desc', _selectedLanguage),
          icon: Icons.support_agent,
        );
      default:
        return Container();
    }
  }

  Widget _buildLanguageSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200, // Account for top and bottom areas
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.agriculture,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            
            // Title
            Text(
              getLocalizedText('welcome_title', _selectedLanguage),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            // Subtitle
            Text(
              getLocalizedText('select_language', _selectedLanguage),
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            
            // Language options
            ...languages.map((language) => _buildLanguageOption(language)),
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
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFF4CB050) : Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? const Color(0xFF4CB050) : Colors.white,
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
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 200,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Feature icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            
            // Feature title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            
            // Feature description
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
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
          
          // Next/Get Started button
          ElevatedButton(
            onPressed: () {
              if (_currentPage < 4) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                _saveLanguageAndContinue();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF4CB050),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Text(
              _currentPage < 4
                  ? getLocalizedText('next', _selectedLanguage)
                  : getLocalizedText('get_started', _selectedLanguage),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
