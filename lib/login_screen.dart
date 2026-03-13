import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:honda_client_app/registration_screen.dart';
import 'package:honda_client_app/main.dart'; // Обязательно для MainNavigationScreen

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _plateNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateNumberController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final plateNumber = _plateNumberController.text.trim().toUpperCase();

    try {
      // 1. Проверяем наличие машины в базе
      final carDoc = await FirebaseFirestore.instance
          .collection('cars')
          .doc(plateNumber)
          .get();

      if (!mounted) return;

      if (carDoc.exists) {
        // 2. Сохраняем номер в память телефона
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_plate_number', plateNumber);

        // 3. ПЕРЕХОДИМ НА ГЛАВНУЮ С МЕНЮ (MainNavigationScreen)
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => MainNavigationScreen(carNumber: plateNumber),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Машина не найдена, пожалуйста, зарегистрируйтесь.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Произошла ошибка: $e'),
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

  void _navigateToRegistration() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const RegistrationScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сервис Honda'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ЗАМЕНА ЛОГОТИПА НА ИКОНКУ (Чтобы не было проблем с авторскими правами)
                const Icon(
                  Icons.directions_car_filled,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 40),
                Text(
                  'Вход по госномеру',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _plateNumberController,
                  inputFormatters: [
                    UpperCaseTextFormatter(),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Госномер',
                    hintText: '100500',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_car),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Пожалуйста, введите госномер';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text('Войти'),
                      ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _navigateToRegistration,
                  child: const Text('Зарегистрировать новую машину'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
