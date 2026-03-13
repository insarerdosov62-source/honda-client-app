import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  void _openGoogleMaps() async {
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=HONDA+SERVICE+Суюнбая+143а+Алматы");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Наш Адрес"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "HONDA SERVICE",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "г. Алматы, просп. Суюнбая 143а",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const Divider(height: 40),
            _buildWorkTimeRow("Пн - Пт", "09:00 – 18:00"),
            _buildWorkTimeRow("Суббота", "09:00 – 15:00"),
            _buildWorkTimeRow("Воскресенье", "Закрыто", isClosed: true),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _openGoogleMaps,
              icon: const Icon(Icons.map),
              label: const Text("ПРОЛОЖИТЬ МАРШРУТ"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTimeRow(String day, String time, {bool isClosed = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 16)),
          Text(time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isClosed ? Colors.red : Colors.black)),
        ],
      ),
    );
  }
}