import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Твои экраны
import 'map_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

// Канал уведомлений для Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'Важные уведомления Honda',
  description: 'Уведомления о готовности автомобиля',
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Обработка уведомлений в фоновом режиме
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Инициализируем Firebase
  await Firebase.initializeApp();

  // 2. Настройки стабильности для Казахстана/плохого интернета
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Включает офлайн-режим
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Инициализация уведомлений
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  final prefs = await SharedPreferences.getInstance();
  final String? lastPlateNumber = prefs.getString('last_plate_number');

  // Решаем, какой экран показать при старте
  Widget initialScreen = (lastPlateNumber != null && lastPlateNumber.isNotEmpty)
      ? MainNavigationScreen(carNumber: lastPlateNumber)
      : const LoginScreen();

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Honda Client App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final String carNumber;
  const MainNavigationScreen({super.key, required this.carNumber});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    setupPushNotifications();
    listenToStatusChanges();
  }

  // 1. Настройка PUSH-уведомлений
  void setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    if (token != null && widget.carNumber.isNotEmpty) {
      debugPrint("TOKEN_DEBUG: $token");
      await FirebaseFirestore.instance
          .collection('cars')
          .doc(widget.carNumber.toUpperCase()) // Добавил ToUpperCase для надежности
          .set({'pushToken': token}, SetOptions(merge: true)); // Используем merge, чтобы не затереть статус
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  // 2. Слушаем изменения статуса
  void listenToStatusChanges() {
    FirebaseFirestore.instance
        .collection('cars')
        .doc(widget.carNumber.toUpperCase())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        String newStatus = snapshot.data()?['status'] ?? '';
        if (_lastStatus != null && _lastStatus != newStatus) {
          String msg = newStatus == 'ready' 
              ? "✅ Ваша Honda готова!" 
              : "🔔 Статус: $newStatus";
          _showInternalNotification(msg, newStatus == 'ready' ? Colors.green : Colors.black87);
        }
        _lastStatus = newStatus;
      }
    });
  }

  void _showInternalNotification(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HistoryScreen(carNumber: widget.carNumber),
      ProfileScreen(carNumber: widget.carNumber),
      const MapScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.red,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'История'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Профиль'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Адрес'),
        ],
      ),
    );
  }
}