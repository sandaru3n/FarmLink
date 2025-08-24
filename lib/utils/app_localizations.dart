import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Auth
      'sign_up': 'Sign Up',
      'sign_in': 'Sign In',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'create_account': 'Create Account',
      'login': 'Login',
      'logout': 'Logout',
      
      // Role Selection
      'select_role': 'Select Your Role',
      'role_description': 'Choose the role that best describes your involvement in the food supply chain',
      'farmer': 'Farmer',
      'consumer': 'Consumer',
      'food_distributor': 'Food Distributor',
      'transporter': 'Transporter',
      'farmer_description': 'Grow and harvest crops, raise livestock',
      'consumer_description': 'Purchase and consume food products',
      'distributor_description': 'Distribute food products to markets',
      'transporter_description': 'Transport food products between locations',
      'continue': 'Continue',
      
      // Onboarding
      'welcome': 'Welcome to FarmLink',
      'connecting_farmers': 'Connecting Farmers with Consumers',
      'fresh_produce': 'Fresh Produce Direct from Farm',
      'secure_transactions': 'Secure and Transparent Transactions',
      'get_started': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
      
      // Settings
      'settings': 'Settings',
      'switch_to_consumer': 'Switch to Consumer',
      'language': 'Language',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'privacy': 'Privacy',
      'help': 'Help',
      'about': 'About',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'back': 'Back',
      'home': 'Home',
      'search': 'Search',
      'menu': 'Menu',
      
      // Validation
      'email_required': 'Email is required',
      'password_required': 'Password is required',
      'confirm_password_required': 'Please confirm your password',
      'passwords_dont_match': 'Passwords do not match',
      'password_too_short': 'Password must be at least 6 characters',
      'invalid_email': 'Please enter a valid email address',
      
      // Dashboard
      'dashboard': 'Dashboard',
      'my_products': 'My Products',
      'orders': 'Orders',
      'analytics': 'Analytics',
      'messages': 'Messages',
      
      // Errors
      'network_error': 'Network error. Please check your connection.',
      'unknown_error': 'An unknown error occurred.',
      'auth_error': 'Authentication error.',
    },
    'si': {
      // Auth
      'sign_up': 'ලියාපදිංචි වන්න',
      'sign_in': 'පිවිසෙන්න',
      'email': 'විද්‍යුත් තැපෑල',
      'password': 'මුරපදය',
      'confirm_password': 'මුරපදය තහවුරු කරන්න',
      'forgot_password': 'මුරපදය අමතක වුණා?',
      'dont_have_account': 'ගිණුමක් නැද්ද?',
      'already_have_account': 'දැනටමත් ගිණුමක් තිබේද?',
      'create_account': 'ගිණුම සාදන්න',
      'login': 'පිවිසෙන්න',
      'logout': 'පිටවීම',
      
      // Role Selection
      'select_role': 'ඔබේ කාර්යභාරය තෝරන්න',
      'role_description': 'ආහාර සැපයුම් දාමයේ ඔබේ සහභාගීත්වය හොඳින් විස්තර කරන කාර්යභාරය තෝරන්න',
      'farmer': 'ගොවියා',
      'consumer': 'පාරිභෝගිකයා',
      'food_distributor': 'ආහාර බෙදාහරින්නා',
      'transporter': 'ප්‍රවාහනකරු',
      'farmer_description': 'බෝග වගා කර අස්වැන්න ලබා ගැනීම, ගවයින් ඇති කිරීම',
      'consumer_description': 'ආහාර නිෂ්පාදන මිලදී ගැනීම සහ පරිභෝජනය කිරීම',
      'distributor_description': 'වෙළඳපොළවලට ආහාර නිෂ්පාදන බෙදාහරින්න',
      'transporter_description': 'ස්ථාන අතර ආහාර නිෂ්පාදන ප්‍රවාහනය කරන්න',
      'continue': 'ඉදිරියට',
      
      // Onboarding
      'welcome': 'FarmLink වෙත සාදරයෙන් පිළිගනිමු',
      'connecting_farmers': 'ගොවියන් පාරිභෝගිකයින් සමඟ සම්බන්ධ කිරීම',
      'fresh_produce': 'ගොවිපලෙන් සෘජුවම නැවුම් නිෂ්පාදන',
      'secure_transactions': 'ආරක්ෂිත සහ පාරදෘශ්‍ය ගනුදෙනු',
      'get_started': 'ආරම්භ කරන්න',
      'skip': 'මඟ හරින්න',
      'next': 'ඊළඟ',
      
      // Settings
      'settings': 'සැකසුම්',
      'switch_to_consumer': 'පාරිභෝගිකයාට මාරු වන්න',
      'language': 'භාෂාව',
      'profile': 'පැතිකඩ',
      'notifications': 'දැනුම්දීම්',
      'privacy': 'පෞද්ගලිකත්වය',
      'help': 'උදව්',
      'about': 'ගැන',
      
      // Common
      'loading': 'පූරණය වෙමින්...',
      'error': 'දෝෂය',
      'success': 'සාර්ථකයි',
      'cancel': 'අවලංගු කරන්න',
      'save': 'සුරැකින්න',
      'delete': 'මකන්න',
      'edit': 'සංස්කරණය',
      'back': 'ආපසු',
      'home': 'මුල් පිටුව',
      'search': 'සොයන්න',
      'menu': 'මෙනුව',
      
      // Validation
      'email_required': 'විද්‍යුත් තැපෑල අවශ්‍ය වේ',
      'password_required': 'මුරපදය අවශ්‍ය වේ',
      'confirm_password_required': 'කරුණාකර ඔබේ මුරපදය තහවුරු කරන්න',
      'passwords_dont_match': 'මුරපද නොගැලපේ',
      'password_too_short': 'මුරපදය අවම වශයෙන් අකුරු 6 ක් විය යුතුය',
      'invalid_email': 'කරුණාකර වලංගු විද්‍යුත් තැපෑලක් ඇතුළත් කරන්න',
      
      // Dashboard
      'dashboard': 'උපකරණ පුවරුව',
      'my_products': 'මගේ නිෂ්පාදන',
      'orders': 'ඇණවුම්',
      'analytics': 'විශ්ලේෂණ',
      'messages': 'පණිවිඩ',
      
      // Errors
      'network_error': 'ජාල දෝෂය. කරුණාකර ඔබේ සම්බන්ධතාවය පරීක්ෂා කරන්න.',
      'unknown_error': 'නොදන්නා දෝෂයක් සිදු විය.',
      'auth_error': 'සත්‍යාපන දෝෂය.',
    },
    'ta': {
      // Auth
      'sign_up': 'பதிவு செய்க',
      'sign_in': 'உள்நுழைய',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'confirm_password': 'கடவுச்சொல்லை உறுதிப்படுத்து',
      'forgot_password': 'கடவுச்சொல் மறந்துவிட்டதா?',
      'dont_have_account': 'கணக்கு இல்லையா?',
      'already_have_account': 'ஏற்கனவே கணக்கு உள்ளதா?',
      'create_account': 'கணக்கு உருவாக்கு',
      'login': 'உள்நுழைய',
      'logout': 'வெளியேறு',
      
      // Role Selection
      'select_role': 'உங்கள் பாத்திரத்தைத் தேர்ந்தெடுக்கவும்',
      'role_description': 'உணவு சங்கிலியில் உங்கள் பங்கேற்பை சிறப்பாக விவரிக்கும் பாத்திரத்தைத் தேர்ந்தெடுக்கவும்',
      'farmer': 'விவசாயி',
      'consumer': 'நுகர்வோர்',
      'food_distributor': 'உணவு விநியோகஸ்தர்',
      'transporter': 'போக்குவரத்து',
      'farmer_description': 'பயிர்களை வளர்த்து அறுவடை செய்தல், கால்நடைகளை வளர்த்தல்',
      'consumer_description': 'உணவு பொருட்களை வாங்கி பயன்படுத்துதல்',
      'distributor_description': 'சந்தைகளுக்கு உணவு பொருட்களை விநியோகித்தல்',
      'transporter_description': 'இடங்களுக்கு இடையே உணவு பொருட்களை போக்குவரத்து செய்தல்',
      'continue': 'தொடரவும்',
      
      // Onboarding
      'welcome': 'FarmLink க்கு வரவேற்கிறோம்',
      'connecting_farmers': 'விவசாயிகளை நுகர்வோருடன் இணைத்தல்',
      'fresh_produce': 'பண்ணையிலிருந்து நேரடியாக புதிய பொருட்கள்',
      'secure_transactions': 'பாதுகாப்பான மற்றும் வெளிப்படையான பரிவர்த்தனைகள்',
      'get_started': 'தொடங்கவும்',
      'skip': 'தவிர்க்கவும்',
      'next': 'அடுத்து',
      
      // Settings
      'settings': 'அமைப்புகள்',
      'switch_to_consumer': 'நுகர்வோருக்கு மாற்று',
      'language': 'மொழி',
      'profile': 'சுயவிவரம்',
      'notifications': 'அறிவிப்புகள்',
      'privacy': 'தனியுரிமை',
      'help': 'உதவி',
      'about': 'பற்றி',
      
      // Common
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'cancel': 'ரத்து செய்',
      'save': 'சேமி',
      'delete': 'அழி',
      'edit': 'திருத்து',
      'back': 'பின்செல்',
      'home': 'முகப்பு',
      'search': 'தேடு',
      'menu': 'மெனு',
      
      // Validation
      'email_required': 'மின்னஞ்சல் தேவை',
      'password_required': 'கடவுச்சொல் தேவை',
      'confirm_password_required': 'உங்கள் கடவுச்சொல்லை உறுதிப்படுத்தவும்',
      'passwords_dont_match': 'கடவுச்சொற்கள் பொருந்தவில்லை',
      'password_too_short': 'கடவுச்சொல் குறைந்தது 6 எழுத்துகள் இருக்க வேண்டும்',
      'invalid_email': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்',
      
      // Dashboard
      'dashboard': 'டாஷ்போர்டு',
      'my_products': 'எனது பொருட்கள்',
      'orders': 'ஆர்டர்கள்',
      'analytics': 'பகுப்பாய்வு',
      'messages': 'செய்திகள்',
      
      // Errors
      'network_error': 'பிணைய பிழை. உங்கள் இணைப்பை சரிபார்க்கவும்.',
      'unknown_error': 'தெரியாத பிழை ஏற்பட்டது.',
      'auth_error': 'அங்கீகார பிழை.',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']![key] ?? 
           key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si', 'ta'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
