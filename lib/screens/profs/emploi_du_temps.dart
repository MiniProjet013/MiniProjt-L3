import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfScheduleScreen extends StatefulWidget {
  @override
  State<ProfScheduleScreen> createState() => _ProfScheduleScreenState();
}

class _ProfScheduleScreenState extends State<ProfScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  String? errorMessage;
  
  String profId = "";
  String profName = "";
  String matiere = "";
  
  Map<String, List<ScheduleItem>> _scheduleItems = {};
  List<ExamItem> _examItems = [];

  final List<String> _weekdays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot profDoc = await FirebaseFirestore.instance
          .collection('profs')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get()
          .then((snapshot) => snapshot.docs.first);

      if (profDoc.exists) {
        Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
        profId = profData['profId'] ?? profData['idProf'] ?? '';
        profName = "${profData['prenom'] ?? ''} ${profData['nom'] ?? ''}";
        matiere = profData['matiere'] ?? '';
      }

      await _loadProfSchedule();
      await _loadProfExams();

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadProfSchedule() async {
    Map<String, List<ScheduleItem>> loadedSchedule = {};
    
    for (String day in _weekdays) {
      loadedSchedule[day] = [];
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('emplois_profs')
          .where('profId', isEqualTo: profId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        QuerySnapshot altQuery = await FirebaseFirestore.instance
            .collection('emplois_classes')
            .where('profId', isEqualTo: profId)
            .get();
        querySnapshot = altQuery;
      }

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        if (data.containsKey('sessions') && data['sessions'] is List) {
          List<dynamic> sessions = data['sessions'];
          
          for (var session in sessions) {
            if (session is Map<String, dynamic>) {
              String jour = session['jour'] ?? '';
              String classeId = session['classeId'] ?? data['classeId'] ?? '';
              String heureDebut = session['heureDebut'] ?? '';
              String heureFin = session['heureFin'] ?? '';
              String salle = session['salle'] ?? '';

              if (jour.isNotEmpty && _weekdays.contains(jour)) {
                ScheduleItem item = ScheduleItem(
                  title: classeId,
                  timeSlot: '$heureDebut - $heureFin',
                  location: salle.isNotEmpty ? salle : 'Non spécifié',
                  type: 'Cours',
                  matiere: matiere,
                );
                loadedSchedule[jour]!.add(item);
              }
            }
          }
        } else {
          String jour = data['jour'] ?? '';
          String classeId = data['classeId'] ?? '';
          String heureDebut = data['heureDebut'] ?? '';
          String heureFin = data['heureFin'] ?? '';
          String salle = data['salle'] ?? '';

          if (jour.isNotEmpty && _weekdays.contains(jour)) {
            ScheduleItem item = ScheduleItem(
              title: classeId,
              timeSlot: '$heureDebut - $heureFin',
              location: salle.isNotEmpty ? salle : 'Non spécifié',
              type: 'Cours',
              matiere: matiere,
            );
            loadedSchedule[jour]!.add(item);
          }
        }
      }

      for (String day in loadedSchedule.keys) {
        loadedSchedule[day]!.sort((a, b) {
          try {
            String timeA = a.timeSlot.split(' - ')[0];
            String timeB = b.timeSlot.split(' - ')[0];
            int minutesA = _timeToMinutes(timeA);
            int minutesB = _timeToMinutes(timeB);
            return minutesA.compareTo(minutesB);
          } catch (e) {
            return 0;
          }
        });
      }

      setState(() {
        _scheduleItems = loadedSchedule;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur emploi du temps: $e';
      });
    }
  }

  int _timeToMinutes(String time) {
    try {
      String cleanTime = time.replaceAll(RegExp(r'[APM\s]'), '');
      List<String> parts = cleanTime.split(':');
      if (parts.length >= 2) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        
        if (time.toUpperCase().contains('PM') && hours != 12) {
          hours += 12;
        }
        if (time.toUpperCase().contains('AM') && hours == 12) {
          hours = 0;
        }
        
        return hours * 60 + minutes;
      }
    } catch (e) {
      print('Erreur parsing time: $time - $e');
    }
    return 0;
  }

  Future<void> _loadProfExams() async {
    List<ExamItem> loadedExams = [];

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('examens')
          .where('matiere', isEqualTo: matiere)
          .get();

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String subject = data['matiere'] ?? '';
        String date = data['date'] ?? '';
        String heureDebut = data['heureDebut'] ?? '';
        String heureFin = data['heureFin'] ?? '';
        String salle = data['salle'] ?? '';
        String classe = data['classe'] ?? data['classeId'] ?? '';
        String type = data['type'] ?? 'Examen';

        if (subject.isNotEmpty) {
          ExamItem exam = ExamItem(
            subject: subject,
            date: date.isNotEmpty ? date : 'Date non spécifiée',
            timeSlot: (heureDebut.isNotEmpty && heureFin.isNotEmpty) 
                ? '$heureDebut - $heureFin' 
                : 'Horaire non spécifié',
            location: salle.isNotEmpty ? salle : 'Lieu non spécifié',
            type: type,
            classe: classe,
          );
          
          loadedExams.add(exam);
        }
      }
      
      loadedExams.sort((a, b) {
        try {
          if (a.date != 'Date non spécifiée' && b.date != 'Date non spécifiée') {
            int dateComparison = a.date.compareTo(b.date);
            if (dateComparison != 0) return dateComparison;
            
            String timeA = a.timeSlot.split(' - ')[0];
            String timeB = b.timeSlot.split(' - ')[0];
            int minutesA = _timeToMinutes(timeA);
            int minutesB = _timeToMinutes(timeB);
            return minutesA.compareTo(minutesB);
          }
          return a.classe.compareTo(b.classe);
        } catch (e) {
          return a.classe.compareTo(b.classe);
        }
      });

      setState(() {
        _examItems = loadedExams;
      });

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur examens: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Emploi du Temps',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 124, 6),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Emploi du Temps'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color.fromARGB(255, 235, 142, 4)),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erreur', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfData,
                        child: Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromRGBO(235, 142, 2, 1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildScheduleTab(),
                    _buildExamTab(),
                  ],
                ),
    );
  }

  Widget _buildScheduleTab() {
    return Container(
      color: const Color(0xFFFFFDE7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfInfo(),
          
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 243, 243, 243),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Matière: $matiere | Prof ID: $profId\n'
              'Jours avec cours: ${_scheduleItems.values.where((items) => items.isNotEmpty).length}',
              style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 31, 128, 6)),
            ),
          ),
          
          Expanded(
            child: _scheduleItems.isEmpty || _scheduleItems.values.every((items) => items.isEmpty)
                ? _buildEmptyState('Aucun cours programmé')
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _weekdays.length,
                    itemBuilder: (context, index) {
                      final day = _weekdays[index];
                      final scheduleItems = _scheduleItems[day] ?? [];
                      return _buildDayCard(day, scheduleItems);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTab() {
    return Container(
      color: const Color(0xFFFFFDE7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfInfo(),
          
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Examens de $matiere\nTotal: ${_examItems.length}',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ),
          
          Expanded(
            child: _examItems.isEmpty
                ? _buildEmptyState('Aucun examen programmé')
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _examItems.length,
                    itemBuilder: (context, index) {
                      final exam = _examItems[index];
                      return _buildExamCard(exam);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color.fromARGB(255, 2, 109, 6), Color.fromARGB(255, 28, 156, 35)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                profName.isNotEmpty ? profName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').join('') : 'P',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Matière: $matiere',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, List<ScheduleItem> scheduleItems) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: scheduleItems.isEmpty
          ? ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.event_busy, color: Color(0xFFE67E22)),
              ),
              title: Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pas de cours'),
            )
          : ExpansionTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.calendar_today, color: Color(0xFFE67E22)),
              ),
              title: Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${scheduleItems.length} cours'),
              children: scheduleItems.map((item) => _buildScheduleItemTile(item)).toList(),
            ),
    );
  }

  Widget _buildExamCard(ExamItem exam) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFBE9E7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.event_note, color: Color(0xFFE67E22)),
        ),
        title: Text('Classe: ${exam.classe}', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${exam.date} | ${exam.timeSlot}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExamDetail(Icons.event, 'Date', exam.date),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.access_time, 'Horaire', exam.timeSlot),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.location_on, 'Lieu', exam.location),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.category, 'Type', exam.type),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.class_, 'Classe', exam.classe),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemTile(ScheduleItem item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: Color(0xFF4CAF50), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Color(0xFFE67E22)),
              SizedBox(width: 8),
              Text(item.timeSlot, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE67E22))),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.class_, size: 16, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Expanded(child: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Color(0xFFE67E22)),
              SizedBox(width: 8),
              Text(item.location),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExamDetail(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE67E22)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700]))),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadProfData,
            icon: Icon(Icons.refresh),
            label: Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleItem {
  final String title;
  final String timeSlot;
  final String location;
  final String type;
  final String matiere;

  ScheduleItem({
    required this.title,
    required this.timeSlot,
    required this.location,
    required this.type,
    required this.matiere,
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