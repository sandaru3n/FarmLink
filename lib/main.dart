import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'providers/auth_provider.dart';
import 'providers/crop_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/delivery_order_provider.dart';
import 'providers/transport_order_provider.dart';
import 'providers/consumer_order_provider.dart';
import 'providers/favorites_provider.dart';
import 'utils/app_localizations.dart';
import 'services/crop_status_service.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Stripe - temporarily commented out
  // Stripe.publishableKey = 'pk_test_51R0iJpQOtXlNP6ZKo0NwWCEkwW2SAq51llmdIRsAX095DZPWnaWcuTZUK0EFcMGo2EkwW2SAq51llmdIRsAX095DZPWnaWcuTZUK0EFcMGo2eU7WrWy081Skjav8SlzvE9c00G7vYBNQN';
  
  // Start crop status service
  final cropStatusService = CropStatusService();
  cropStatusService.startStatusUpdateService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CropProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => DeliveryOrderProvider()),
        ChangeNotifierProvider(create: (_) => TransportOrderProvider()),
        ChangeNotifierProvider(create: (_) => ConsumerOrderProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'FarmLink',
        debugShowCheckedModeBanner: false,
        
        // Localization
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
                            supportedLocales: const [
                      Locale('en', ''),
                      Locale('si', ''),
                      Locale('ta', ''),
                    ],
        
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CB050),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        
        home: const SplashScreen(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CB050),
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.agriculture,
              size: 80,
              color: Color(0xFF4CB050),
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome to FarmLink',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CB050),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your farming companion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF4CB050),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        backgroundColor: const Color(0xFF4CB050),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
