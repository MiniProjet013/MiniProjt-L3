import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  final String? professorId; // ID du professeur si c'est un prof qui consulte
  
  const ScheduleScreen({Key? key, this.professorId}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedLevel = '1ère année'; // Niveau par défaut

  // Couleurs mises à jour pour correspondre aux autres interfaces
  final Color _primaryColor = const Color(0xFF3F51B5); // Bleu indigo
  final Color _accentColor = const Color(0xFFFF9800);  // Orange
  final Color _backgroundColor = const Color(0xFFF5F5F5); // Gris très clair
  final Color _cardColor = Colors.white;

  final List<String> _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  // Map pour stocker les emplois du temps récupérés de Firestore
  final Map<String, List<ScheduleItem>> _scheduleItems = {
    'Lundi': [],
    'Mardi': [],
    'Mercredi': [],
    'Jeudi': [],
    'Vendredi': [],
    'Samedi': [],
    'Dimanche': [],
  };

  // Liste pour stocker les examens récupérés de Firestore
  List<ExamItem> _examItems = [];
  
  // Liste des niveaux disponibles
  final List<String> _levels = ['1ère année', '2ème année', '3ème année'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Récupération des données depuis Firestore
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Réinitialiser les données
      for (var day in _weekdays) {
        _scheduleItems[day] = [];
      }
      _examItems = [];

      // Récupérer l'emploi du temps du professeur si on a un ID de professeur
      if (widget.professorId != null) {
        await _fetchProfessorSchedule(widget.professorId!);
      } else {
        // Sinon récupérer l'emploi du temps par niveau
        await _fetchClassSchedule(_selectedLevel);
      }

      // Récupérer les examens du niveau sélectionné
      await _fetchExams(_selectedLevel);
    } catch (e) {
      print('Erreur lors de la récupération des données: $e');
      // Afficher une boîte de dialogue d'erreur si nécessaire
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Récupérer l'emploi du temps d'un professeur
  Future<void> _fetchProfessorSchedule(String profId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Récupérer tous les cours du professeur pour l'année en cours
    final QuerySnapshot snapshot = await firestore
        .collection('emplois_profs')
        .where('profId', isEqualTo: profId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Traiter les sessions de cours
      if (data.containsKey('sessions') && data['sessions'] is List) {
        for (var session in data['sessions']) {
          if (session is Map<String, dynamic>) {
            final String jour = session['jour'] ?? '';
            final String heureDebut = session['heureDebut'] ?? '';
            final String heureFin = session['heureFin'] ?? '';
            final String matiere = session['matiere'] ?? '';
            final String classeId = session['classeId'] ?? '';
            
            // Récupérer les informations sur la classe
            String salle = '';
            try {
              final classeDoc = await firestore.collection('classes').doc(classeId).get();
              if (classeDoc.exists) {
                final classeData = classeDoc.data() as Map<String, dynamic>;
                salle = classeData['salle'] ?? '';
              }
            } catch (e) {
              print('Erreur lors de la récupération de la classe: $e');
            }
            
            if (_weekdays.contains(jour)) {
              _scheduleItems[jour]!.add(
                ScheduleItem(
                  title: matiere,
                  timeSlot: '$heureDebut - $heureFin',
                  location: 'Salle: $salle (Classe: $classeId)',
                  type: 'Cours',
                ),
              );
            }
          }
        }
      }
    }
  }

  // Récupérer l'emploi du temps d'un niveau
  Future<void> _fetchClassSchedule(String level) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Convertir le niveau en ID de niveau tel qu'il est stocké dans Firestore
    String levelId = level.toLowerCase().replaceAll(' ', '_').replaceAll('è', 'e');
    
    // Récupérer tous les cours pour le niveau sélectionné
    final QuerySnapshot snapshot = await firestore
        .collection('emplois_classes')
        .where('niveau', isEqualTo: levelId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      final String jour = data['jour'] ?? '';
      final String heureDebut = data['heureDebut'] ?? '';
      final String heureFin = data['heureFin'] ?? '';
      final String matiere = data['matiere'] ?? '';
      final String salle = data['salle'] ?? '';
      final String type = data['type'] ?? 'Cours';
      
      if (_weekdays.contains(jour)) {
        _scheduleItems[jour]!.add(
          ScheduleItem(
            title: matiere,
            timeSlot: '$heureDebut - $heureFin',
            location: 'Salle: $salle',
            type: type,
          ),
        );
      }
    }
  }

  // Récupérer les examens d'un niveau
  Future<void> _fetchExams(String level) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    // Convertir le niveau en ID de niveau tel qu'il est stocké dans Firestore
    String levelId = level.toLowerCase().replaceAll(' ', '_').replaceAll('è', 'e');
    
    final QuerySnapshot snapshot = await firestore
        .collection('school_years')
        .doc('2024-2025')
        .collection('levels')
        .doc(levelId)
        .collection('exams')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      final String matiere = data['matiere'] ?? '';
      final String date = data['date'] ?? '';
      final String heureDebut = data['heureDebut'] ?? '';
      final String heureFin = data['heureFin'] ?? '';
      final String salle = data['salle'] ?? '';
      final String classe = data['classe'] ?? '';
      
      _examItems.add(
        ExamItem(
          subject: matiere,
          date: date,
          timeSlot: '$heureDebut - $heureFin',
          location: '$salle',
          type: 'Examen',
          classe: classe
        ),
      );
    }
    
    // Trier les examens par date
    _examItems.sort((a, b) {
      // Convertir les dates au format DD/MM/YYYY pour la comparaison
      List<String> partsA = a.date.split('/');
      List<String> partsB = b.date.split('/');
      
      if (partsA.length == 3 && partsB.length == 3) {
        DateTime dateA = DateTime(
          int.parse(partsA[2]), 
          int.parse(partsA[1]), 
          int.parse(partsA[0])
        );
        DateTime dateB = DateTime(
          int.parse(partsB[2]), 
          int.parse(partsB[1]), 
          int.parse(partsB[0])
        );
        return dateA.compareTo(dateB);
      }
      return 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emploi du temps',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String level) {
              setState(() {
                _selectedLevel = level;
              });
              _fetchData();
            },
            itemBuilder: (BuildContext context) {
              return _levels.map((String level) {
                return PopupMenuItem<String>(
                  value: level,
                  child: Text(level),
                );
              }).toList();
            },
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: _accentColor,
          tabs: const [
            Tab(text: 'Emploi du temps'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                // Premier onglet - Emploi du temps régulier
                _buildScheduleTab(),

                // Deuxième onglet - Emploi du temps des examens
                _buildExamScheduleTab(),
              ],
            ),
    );
  }

  Widget _buildScheduleTab() {
    return Container(
      color: _backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.professorId != null 
                      ? 'Emploi du temps du professeur' 
                      : 'Emploi du temps: $_selectedLevel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                Text(
                  '2024-2025',
                  style: TextStyle(
                    fontSize: 16,
                    color: _accentColor,
                  ),
                ),
              ],
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
                    color: _cardColor,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    elevation: 2,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.event_busy,
                          color: _accentColor,
                        ),
                      ),
                      title: Text(
                        day,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Pas de cours'),
                    ),
                  );
                }

                return Card(
                  color: _cardColor,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: _primaryColor,
                      ),
                    ),
                    title: Text(
                      day,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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
    return Container(
      color: _backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Examens: $_selectedLevel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                Text(
                  '2024-2025',
                  style: TextStyle(
                    fontSize: 16,
                    color: _accentColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _examItems.isEmpty
                ? Center(
                    child: Text(
                      'Aucun examen programmé',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _examItems.length,
                    itemBuilder: (context, index) {
                      final exam = _examItems[index];

                      return Card(
                        color: _cardColor,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        elevation: 2,
                        child: ExpansionTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.event_note,
                              color: _accentColor,
                            ),
                          ),
                          title: Text(
                            exam.subject,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                                  _buildExamDetail(Icons.group, 'Classe', exam.classe),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Rappel ajouté'),
                                              backgroundColor: _primaryColor,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.alarm),
                                        label: const Text('Rappel'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _accentColor,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content:
                                                  const Text('Partagé avec les élèves'),
                                              backgroundColor: _primaryColor,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.share),
                                        label: const Text('Partager'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryColor,
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
              Icon(Icons.access_time, size: 16, color: _accentColor),
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
              Icon(Icons.subject, size: 16, color: _primaryColor),
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
              Icon(Icons.location_on, size: 16, color: _accentColor),
              const SizedBox(width: 8),
              Expanded(child: Text(item.location)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: _primaryColor),
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
        Icon(icon, size: 16, color: _accentColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
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
  final String classe;

  ExamItem({
    required this.subject,
    required this.date,
    required this.timeSlot,
    required this.location,
    required this.type,
    required this.classe,
  });
}