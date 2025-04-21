import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({Key? key}) : super(key: key);

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Define exam days (4th, 6th, and 8th of current month)
  final List<DateTime> _examDays = [
    DateTime(DateTime.now().year, DateTime.now().month, 4),
    DateTime(DateTime.now().year, DateTime.now().month, 6),
    DateTime(DateTime.now().year, DateTime.now().month, 8),
  ];

  // Define exam details for each exam day
  final Map<String, Map<String, String>> _examDetails = {
    '4': {
      'subject': 'Mathématiques',
      'time': '09:00 - 11:00',
      'description':
          'Examen sur les fonctions dérivées et l\'intégration. Les étudiants doivent réviser les chapitres 5 à 8 du manuel. Calculatrices autorisées.',
    },
    '6': {
      'subject': 'Physique',
      'time': '14:00 - 16:00',
      'description':
          'Examen sur la mécanique des fluides et la thermodynamique. Réviser les expériences de laboratoire et les équations fondamentales. Pas de documents autorisés.',
    },
    '8': {
      'subject': 'Informatique',
      'time': '10:00 - 12:00',
      'description':
          'Examen pratique sur les algorithmes et la programmation en Python. Réviser les structures de données, les algorithmes de tri et les fonctions récursives.',
    },
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier des Examens'),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Check if the selected day is an exam day
              final dayStr = selectedDay.day.toString();
              if (_examDetails.containsKey(dayStr)) {
                _showExamDetailsDialog(dayStr);
              }
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              // Highlight exam days
              markerDecoration: const BoxDecoration(
                color: Color(0xFFE67E22), // Orange color
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              todayDecoration: const BoxDecoration(
                color: Color(0xFF4CAF50), // Green color
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFFE67E22), // Orange color
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Mark exam days
                if (_examDays.any((examDay) => isSameDay(examDay, date))) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE67E22), // Orange color
                      ),
                      width: 8.0,
                      height: 8.0,
                    ),
                  );
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Upcoming exams section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Examens à venir',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _examDays.length,
                      itemBuilder: (context, index) {
                        final examDay = _examDays[index];
                        final dayStr = examDay.day.toString();
                        final examDetail = _examDetails[dayStr];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE67E22), // Orange color
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  dayStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(examDetail?['subject'] ?? ''),
                            subtitle: Text(examDetail?['time'] ?? ''),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _showExamDetailsDialog(dayStr),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExamDetailsDialog(String dayStr) {
    final examDetail = _examDetails[dayStr];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Examen de ${examDetail?['subject']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                    'Date', '${_focusedDay.month}/$dayStr/${_focusedDay.year}'),
                _buildDetailRow('Heure', examDetail?['time'] ?? ''),
                const SizedBox(height: 16),
                const Text(
                  'À réviser:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(examDetail?['description'] ?? ''),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
