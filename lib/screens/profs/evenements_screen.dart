import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({Key? key}) : super(key: key);

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  // Pre-populated events for a primary school
  final List<SchoolEvent> _events = [
    SchoolEvent(
      id: '1',
      title: 'Journée Portes Ouvertes',
      type: 'Événement Scolaire',
      date: DateTime(2023, 10, 15),
      time: '14:00 - 17:00',
      description:
          'Journée portes ouvertes pour les parents et futurs élèves. Visite des salles de classe et rencontre avec les enseignants.',
      location: 'École Primaire',
    ),
    SchoolEvent(
      id: '2',
      title: 'Spectacle de Fin d\'Année',
      type: 'Activité Culturelle',
      date: DateTime(2023, 12, 20),
      time: '15:30 - 17:30',
      description:
          'Spectacle de fin d\'année présenté par les élèves de CE1 et CE2. Chants, danses et petites pièces de théâtre.',
      location: 'Salle Polyvalente',
    ),
    SchoolEvent(
      id: '3',
      title: 'Sortie au Musée',
      type: 'Sortie Éducative',
      date: DateTime(2023, 11, 8),
      time: '09:00 - 14:00',
      description:
          'Sortie éducative au musée d\'histoire naturelle pour les classes de CM1 et CM2. Prévoir un pique-nique et une tenue adaptée.',
      location: 'Musée d\'Histoire Naturelle',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PublishEventScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _events.isEmpty
          ? const Center(
              child: Text(
                'Aucun événement à afficher',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _events.length,
              itemBuilder: (context, index) {
                final event = _events[index];
                return EventCard(event: event);
              },
            ),
    );
  }
}

class SchoolEvent {
  final String id;
  final String title;
  final String type;
  final DateTime date;
  final String time;
  final String description;
  final String location;

  SchoolEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.date,
    required this.time,
    required this.description,
    required this.location,
  });
}

class EventCard extends StatelessWidget {
  final SchoolEvent event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          event.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${DateFormat('dd/MM/yyyy').format(event.date)} • ${event.time}',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        leading: Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFFE67E22), // Orange color
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getEventIcon(event.type),
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.category, 'Type', event.type),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.location_on, 'Lieu', event.location),
                const SizedBox(height: 8),
                _buildInfoRow(
                    Icons.description, 'Description', event.description),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // Add reminder functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Rappel ajouté pour cet événement'),
                            backgroundColor: Color(0xFF4CAF50), // Green color
                          ),
                        );
                      },
                      icon: const Icon(Icons.alarm_add),
                      label: const Text('Rappel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFE67E22), // Orange color
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Share functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Événement partagé'),
                            backgroundColor: Color(0xFF4CAF50), // Green color
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Partager'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Green color
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
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'Événement Scolaire':
        return Icons.school;
      case 'Activité Culturelle':
        return Icons.theater_comedy;
      case 'Sortie Éducative':
        return Icons.directions_bus;
      default:
        return Icons.event;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF4CAF50), // Green color
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PublishEventScreen extends StatefulWidget {
  const PublishEventScreen({Key? key}) : super(key: key);

  @override
  State<PublishEventScreen> createState() => _PublishEventScreenState();
}

class _PublishEventScreenState extends State<PublishEventScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedEventType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _eventTypes = [
    'Événement Scolaire',
    'Activité Culturelle',
    'Sortie Éducative',
    'Réunion Parents-Professeurs',
    'Journée Sportive',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publier un événement'),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Type Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: const Text('Type d\'événement'),
                  value: _selectedEventType,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFFE67E22)), // Orange color
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedEventType = newValue;
                    });
                  },
                  items:
                      _eventTypes.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Selection
            InkWell(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2025),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4CAF50), // Green color
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDate == null
                          ? 'Sélectionner une date'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                      style: TextStyle(
                        color:
                            _selectedDate == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.calendar_month,
                        color: Color(0xFFE67E22)), // Orange color
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time Selection
            InkWell(
              onTap: () async {
                final TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Color(0xFF4CAF50), // Green color
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedTime != null) {
                  setState(() {
                    _selectedTime = pickedTime;
                  });
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _selectedTime == null
                          ? 'Sélectionner une heure'
                          : _selectedTime!.format(context),
                      style: TextStyle(
                        color:
                            _selectedTime == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.access_time_filled,
                        color: Color(0xFFE67E22)), // Orange color
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description TextField
            Container(
              height: 150,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Description',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Publish Button
            ElevatedButton(
              onPressed: () {
                // Handle publish button press
                if (_selectedEventType != null &&
                    _selectedDate != null &&
                    _selectedTime != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Événement publié avec succès'),
                      backgroundColor: Color(0xFF4CAF50), // Green color
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Color(0xFF4CAF50), // Green color
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Green color
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Publier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
