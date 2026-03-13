import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistoryScreen extends StatelessWidget {
  final String carNumber;
  const HistoryScreen({super.key, required this.carNumber});

  @override
  Widget build(BuildContext context) {
    // Чистим номер машины от лишних пробелов и переводим в верхний регистр
    final String cleanCarNumber = carNumber.trim().toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'HONDA SERVICE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .doc(cleanCarNumber)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка связи: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Автомобиль "$cleanCarNumber" не найден',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Извлекаем данные
          final docData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> historyArray = docData['history'] ?? [];

          if (historyArray.isEmpty) {
            return const Center(child: Text('История обслуживания пуста'));
          }

          // Новые записи в начало списка
          final sortedHistory = historyArray.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedHistory.length,
            itemBuilder: (context, index) {
              final service = sortedHistory[index] as Map<String, dynamic>;

              // Выносим данные в переменные для чистоты
              final String sDate = service['date']?.toString() ?? 'Нет даты';
              final String sTime = service['time']?.toString() ?? '';
              final String sPrice = service['totalPrice']?.toString() ?? '0';
              final String sType = service['type']?.toString() ?? '';
              final String? photoBefore = service['photoUriBefore'];
              final String? photoAfter = service['photoUriAfter'];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Icon(Icons.build_circle, color: Colors.red[800], size: 30),
                    title: Text(
                      sDate,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(sTime, style: TextStyle(color: Colors.grey[600])),
                    trailing: Text(
                      '$sPrice ₸',
                      style: TextStyle(
                        color: Colors.red[800],
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    children: [
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategorizedList(sType),
                            const SizedBox(height: 20),
                            if ((photoBefore != null && photoBefore.isNotEmpty) ||
                                (photoAfter != null && photoAfter.isNotEmpty))
                              Row(
                                children: [
                                  if (photoBefore != null && photoBefore.isNotEmpty)
                                    _buildPhotoItem(context, "ДО", photoBefore),
                                  if (photoBefore != null && 
                                      photoBefore.isNotEmpty && 
                                      photoAfter != null && 
                                      photoAfter.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (photoAfter != null && photoAfter.isNotEmpty)
                                    _buildPhotoItem(context, "ПОСЛЕ", photoAfter),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCategorizedList(String rawText) {
    if (rawText.isEmpty) return const Text("Данные о работах отсутствуют");

    // Расшифровка популярных сокращений
    String text = rawText
        .replaceAll('Ф.', 'Фильтр')
        .replaceAll('масл.', 'масляный')
        .replaceAll('возд.', 'воздушный')
        .replaceAll('сал.', 'салонный')
        .replaceAll('Торм.', 'Тормозные')
        .replaceAll('Аморт.', 'Амортизаторы');

    List<String> lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String cleanLine = line.trim();
        if (cleanLine.isEmpty) return const SizedBox.shrink();

        // Проверка на заголовки категорий
        final categories = ['ТО', 'ХОДОВАЯ', 'ДВС', 'ТРАНСМИССИЯ', 'ПРОЧЕЕ'];
        bool isHeader = categories.any((cat) => cleanLine.toUpperCase().startsWith(cat));

        if (isHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              cleanLine.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: Colors.red[800],
                letterSpacing: 1.1,
              ),
            ),
          );
        }

        // Логика выделения комментариев в скобках
        String job = cleanLine;
        String? comment;
        if (cleanLine.contains('(') && cleanLine.contains(')')) {
          int start = cleanLine.indexOf('(');
          int end = cleanLine.indexOf(')');
          comment = cleanLine.substring(start + 1, end).replaceAll('ком:', '').trim();
          job = cleanLine.substring(0, start).trim();
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(child: Text(job, style: const TextStyle(fontSize: 15))),
                ],
              ),
              if (comment != null && comment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 14, top: 2),
                  child: Text(
                    "— $comment",
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoItem(BuildContext context, String label, String url) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => _showFullImage(context, url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 140,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black,
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}