import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _days = [
    'Dimanche',
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi'
  ];

  final List<String> _hours = [
    '7:00',
    '8:00',
    '9:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00'
  ];

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
        title: const Text('Emploi du temps'),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Emploi du temps'),
            Tab(text: 'Emploi du temps des examens'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScheduleTab(false),
          _buildScheduleTab(true),
        ],
      ),
    );
  }

  Widget _buildScheduleTab(bool isExamSchedule) {
    return Container(
      color:
          const Color(0xFFF5F5DC), // Light beige background to mimic cork board
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Schedule title
          Text(
            isExamSchedule ? 'Emploi du temps des examens' : 'Emploi du temps',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50), // Green color
            ),
          ),
          const SizedBox(height: 16),

          // Schedule table
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Days header row
                  Row(
                    children: [
                      // Empty cell for hours column
                      Container(
                        width: 60,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                        ),
                      ),
                      // Days of the week
                      ...List.generate(7, (index) {
                        return Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Text(
                                _days[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),

                  // Hours and schedule cells
                  ...List.generate(_hours.length, (hourIndex) {
                    return Row(
                      children: [
                        // Hour cell
                        Container(
                          width: 60,
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            color: Colors.white,
                          ),
                          child: Center(
                            child: Text(_hours[hourIndex]),
                          ),
                        ),
                        // Schedule cells for each day
                        ...List.generate(7, (dayIndex) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                _showAddEventDialog(
                                    dayIndex, hourIndex, isExamSchedule);
                              },
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(int dayIndex, int hourIndex, bool isExamSchedule) {
    final TextEditingController _eventController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ajouter un ${isExamSchedule ? 'examen' : 'cours'}'),
          content: TextField(
            controller: _eventController,
            decoration: InputDecoration(
              labelText: isExamSchedule ? 'Nom de l\'examen' : 'Nom du cours',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                // Here you would save the event
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${isExamSchedule ? 'Examen' : 'Cours'} ajouté: ${_eventController.text}'),
                    backgroundColor: const Color(0xFF4CAF50), // Green color
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22), // Orange color
              ),
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }
}
