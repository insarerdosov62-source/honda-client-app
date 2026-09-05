import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:honda_client_app/registration_screen.dart';
import 'package:honda_client_app/main.dart';

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
  final _phoneController = TextEditingController(text: "+7");
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final rawPhone = _phoneController.text.trim();
    final cleanPhone = _cleanPhoneNumber(rawPhone);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('phone_number', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (!mounted) return;

      if (querySnapshot.docs.isNotEmpty) {
        final carData = querySnapshot.docs.first.data();
        final plateNumber = carData['plate_number'] as String? ?? querySnapshot.docs.first.id;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_plate_number', plateNumber);
        await prefs.setString('last_phone_number', cleanPhone);

        if (!mounted) return;

        final navigator = Navigator.of(context);
        navigator.pushReplacement(MaterialPageRoute(
          builder: (context) => MainNavigationScreen(carNumber: plateNumber),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Номер телефона не найден. Пожалуйста, зарегистрируйтесь.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка входа: $e'),
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
        title: const Text('Сервис HS'),
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
                const Icon(
                  Icons.directions_car_filled,
                  size: 100,
                  color: Colors.red,
                ),
                const SizedBox(height: 40),
                Text(
                  'Вход по номеру телефона',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Номер телефона',
                    hintText: '+7 705 660 72 50',
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