import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  final Map<String, List<ScheduleItem>> _scheduleItems = {
    'Lundi': [
      ScheduleItem(
        title: 'Mathématiques',
        timeSlot: '8:00 - 10:00',
        location: 'Salle A101',
        type: 'Cours',
      ),
      ScheduleItem(
        title: 'Physique',
        timeSlot: '10:30 - 12:30',
        location: 'Laboratoire B201',
        type: 'TP',
      ),
      ScheduleItem(
        title: 'Français',
        timeSlot: '14:00 - 16:00',
        location: 'Salle C305',
        type: 'Cours',
      ),
    ],
    'Mardi': [
      ScheduleItem(
        title: 'Histoire-Géographie',
        timeSlot: '8:00 - 10:00',
        location: 'Salle D102',
        type: 'Cours',
      ),
      ScheduleItem(
        title: 'Anglais',
        timeSlot: '10:30 - 12:30',
        location: 'Salle de langue E201',
        type: 'Cours',
      ),
    ],
    'Mercredi': [
      ScheduleItem(
        title: 'SVT',
        timeSlot: '8:00 - 10:00',
        location: 'Laboratoire F103',
        type: 'TP',
      ),
      ScheduleItem(
        title: 'Éducation Physique',
        timeSlot: '10:30 - 12:30',
        location: 'Gymnase',
        type: 'Sport',
      ),
    ],
    'Jeudi': [
      ScheduleItem(
        title: 'Mathématiques',
        timeSlot: '8:00 - 10:00',
        location: 'Salle A101',
        type: 'Cours',
      ),
      ScheduleItem(
        title: 'Informatique',
        timeSlot: '10:30 - 12:30',
        location: 'Salle Info G205',
        type: 'TP',
      ),
      ScheduleItem(
        title: 'Chimie',
        timeSlot: '14:00 - 16:00',
        location: 'Laboratoire H301',
        type: 'TP',
      ),
    ],
    'Vendredi': [
      ScheduleItem(
        title: 'Philosophie',
        timeSlot: '8:00 - 10:00',
        location: 'Salle I102',
        type: 'Cours',
      ),
      ScheduleItem(
        title: 'Arts Plastiques',
        timeSlot: '10:30 - 12:30',
        location: 'Atelier J201',
        type: 'Atelier',
      ),
    ],
    'Samedi': [],
    'Dimanche': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emploi du temps',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Emploi du temps'),
            Tab(text: 'Emploi du temps des examens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // First tab - Regular schedule
          _buildScheduleTab(),

          // Second tab - Exam schedule
          _buildExamScheduleTab(),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    return Container(
      color: const Color(0xFFFFFDE7), // Light yellow background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Emploi du temps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50), // Green color
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _weekdays.length,
              itemBuilder: (context, index) {
                final day = _weekdays[index];
                final scheduleItems = _scheduleItems[day] ?? [];

                if (scheduleItems.isEmpty) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBE9E7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.event_busy,
                          color: Color(0xFFE67E22), // Orange color
                        ),
                      ),
                      title: Text(day),
                      subtitle: const Text('Pas de cours'),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFFE67E22), // Orange color
                      ),
                    ),
                    title: Text(day),
                    subtitle: Text('${scheduleItems.length} cours'),
                    children: scheduleItems
                        .map((item) => _buildScheduleItemTile(item))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamScheduleTab() {
    // Sample exam data
    final examItems = [
      ExamItem(
        subject: 'Mathématiques',
        date: '15/06/2025',
        timeSlot: '8:00 - 10:00',
        location: 'Salle A101',
        type: 'Examen Final',
      ),
      ExamItem(
        subject: 'Physique',
        date: '17/06/2025',
        timeSlot: '8:00 - 10:00',
        location: 'Salle B201',
        type: 'Examen Final',
      ),
      ExamItem(
        subject: 'Français',
        date: '19/06/2025',
        timeSlot: '8:00 - 10:00',
        location: 'Salle C305',
        type: 'Examen Final',
      ),
      ExamItem(
        subject: 'Histoire-Géographie',
        date: '22/06/2025',
        timeSlot: '8:00 - 10:00',
        location: 'Salle D102',
        type: 'Examen Final',
      ),
      ExamItem(
        subject: 'Anglais',
        date: '24/06/2025',
        timeSlot: '8:00 - 10:00',
        location: 'Salle E201',
        type: 'Examen Final',
      ),
    ];

    return Container(
      color: const Color(0xFFFFFDE7), // Light yellow background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Emploi du temps des examens',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50), // Green color
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: examItems.length,
              itemBuilder: (context, index) {
                final exam = examItems[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(0xFFE67E22), // Orange color
                      ),
                    ),
                    title: Text(exam.subject),
                    subtitle: Text('${exam.date} | ${exam.timeSlot}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildExamDetail(Icons.event, 'Date', exam.date),
                            const SizedBox(height: 8),
                            _buildExamDetail(
                                Icons.access_time, 'Horaire', exam.timeSlot),
                            const SizedBox(height: 8),
                            _buildExamDetail(
                                Icons.location_on, 'Lieu', exam.location),
                            const SizedBox(height: 8),
                            _buildExamDetail(Icons.category, 'Type', exam.type),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Rappel ajouté'),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.alarm),
                                  label: const Text('Rappel'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFFE67E22), // Orange color
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Partagé avec les élèves'),
                                        backgroundColor: Color(0xFF4CAF50),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Partager'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF4CAF50), // Green color
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemTile(ScheduleItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Color(0xFFE67E22)),
              const SizedBox(width: 8),
              Text(
                item.timeSlot,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.subject, size: 16, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFFE67E22)),
              const SizedBox(width: 8),
              Text(item.location),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(item.type),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildExamDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE67E22)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}

class ScheduleItem {
  final String title;
  final String timeSlot;
  final String location;
  final String type;

  ScheduleItem({
    required this.title,
    required this.timeSlot,
    required this.location,
    required this.type,
  });
}

class ExamItem {
  final String subject;
  final String date;
  final String timeSlot;
  final String location;
  final String type;

  ExamItem({
    required this.subject,
    required this.date,
    required this.timeSlot,
    required this.location,
    required this.type,
  });
}
