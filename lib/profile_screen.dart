import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:honda_client_app/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  final String carNumber;
  const ProfileScreen({super.key, required this.carNumber});

  // --- ФУНКЦИЯ ДЛЯ ЗВОНКА ---
  void _makePhoneCall() async {
    final Uri url = Uri.parse("tel:+77017957447");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // --- ФУНКЦИЯ ДЛЯ WHATSAPP ---
  void _openWhatsApp(String carNumber) async {
    String phoneNumber = "77056607250";
    String message = "Здравствуйте! Я по поводу обслуживания авто с госномером $carNumber";
    final Uri waUrl = Uri.parse("whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}");
    final Uri httpsUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(httpsUrl, mode: LaunchMode.externalApplication);
    }
  }

  // --- LOGOUT ---
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_plate_number');
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Профиль"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        // Используем carNumber, который пришел в конструктор
        future: FirebaseFirestore.instance.collection('cars').doc(carNumber).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Профиль не найден в базе."),
                  const Text("Зарегистрируйтесь в сервисе."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text("Вернуться к входу"),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // ... после строки: final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                // Исправленные ключи здесь:
                _buildProfileItem(Icons.directions_car, "Марка/Модель", data['car_model']),
                _buildProfileItem(Icons.numbers, "Госномер", data['plate_number']),
                _buildProfileItem(Icons.person, "Владелец", data['owner_name'] ?? "Клиент Honda"),

                const SizedBox(height: 30),
                // ...

                // Кнопки связи
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _makePhoneCall,
                          icon: const Icon(Icons.phone),
                          label: const Text("Позвонить"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openWhatsApp(carNumber),
                          icon: const Icon(Icons.chat),
                          label: const Text("WhatsApp"),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String? value) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      subtitle: Text(value ?? "Не указано", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Выход"),
        content: const Text("Выйти из системы?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          TextButton(onPressed: () => _logout(context), child: const Text("Выйти", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
