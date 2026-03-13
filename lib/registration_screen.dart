import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // ДОБАВИЛИ
import 'package:honda_client_app/history_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:honda_client_app/main.dart'; 

import 'login_screen.dart'; 

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _ownerController = TextEditingController();
  final _modelController = TextEditingController();
  final _phoneController = TextEditingController(text: "+7");

  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    _ownerController.dispose();
    _modelController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _registerCar() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final plateNumber = _plateController.text.toUpperCase().trim();

    try {
      // --- ПОЛУЧАЕМ ТОКЕН ДЛЯ УВЕДОМЛЕНИЙ ---
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint("Не удалось получить токен: $e");
      }

      // 1. Сохраняем данные в Firebase (теперь с fcmToken)
      await FirebaseFirestore.instance.collection('cars').doc(plateNumber).set({
        'owner_name': _ownerController.text.trim(),
        'car_model': _modelController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'plate_number': plateNumber,
        'registration_date': Timestamp.now(),
        'fcmToken': fcmToken, // ПОЛЕ ДЛЯ АДМИНКИ
      }, SetOptions(merge: true));

      // 2. Сохраняем госномер в память телефона
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_plate_number', plateNumber);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Машина успешно зарегистрирована!'),
          backgroundColor: Colors.green,
        ),
      );

      // 3. Переходим на ГЛАВНУЮ НАВИГАЦИЮ
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(carNumber: plateNumber),
        ),
            (route) => false,
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка регистрации: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация машины'),
        backgroundColor: Colors.red[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _plateController,
                inputFormatters: [UpperCaseTextFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Госномер',
                  hintText: 'A123BC777',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.directions_car),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Введите госномер' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'ФИО владельца',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                 validator: (value) => value!.trim().isEmpty ? 'Введите ФИО' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Модель машины',
                  hintText: 'Honda CR-V',
                  border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.time_to_leave),
                ),
                 validator: (value) => value!.trim().isEmpty ? 'Введите модель' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона',
                  hintText: '(705) 660-72-50',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  if (!value.startsWith('+7')) {
                    _phoneController.text = '+7';
                    _phoneController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _phoneController.text.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().length < 12) {
                    return 'Введите полный номер телефона';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _registerCar,
                      child: const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}