import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmploiTempsScreen extends StatefulWidget {
  final String eleveId;
  final String classeId;
  final String schoolYear;
  final String level;

  const EmploiTempsScreen({
    super.key, 
    required this.eleveId,
    required this.classeId,
    required this.schoolYear,
    required this.level,
  });

  @override
  State<EmploiTempsScreen> createState() => _EmploiTempsScreenState();
}

class _EmploiTempsScreenState extends State<EmploiTempsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  bool _isLoadingClasse = true;
  bool _isLoadingExamens = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoadingClasse = false;
        _isLoadingExamens = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête fixe avec gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 40, 141, 0), Color.fromARGB(255, 63, 136, 3)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "EMPLOI DU TEMPS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isLoadingClasse = true;
                              _isLoadingExamens = true;
                            });
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  ),
                  // Onglets
                  Container(
                    height: 48,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 14,
                      ),
                      tabs: [
                        Tab(
                          icon: Icon(Icons.schedule, size: 20),
                          text: "COURS",
                        ),
                        Tab(
                          icon: Icon(Icons.quiz, size: 20),
                          text: "EXAMENS",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoursTab(),
                _buildExamensTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursTab() {
    return _isLoadingClasse
        ? _buildLoadingContent()
        : _buildEmploiClasseList();
  }

  Widget _buildExamensTab() {
    return _isLoadingExamens
        ? _buildLoadingContent()
        : _buildEmploiExamensList();
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 40,
                        height: 40,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 16,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 20,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Container(
                        height: 14,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmploiClasseList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('emplois_classes')
          .doc(widget.classeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget("Erreur lors du chargement de l'emploi du temps");
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyWidget(
            "Aucun emploi du temps trouvé",
            "L'emploi du temps de votre classe n'est pas encore disponible",
            Icons.schedule_outlined,
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        
        if (data['sessions'] == null || (data['sessions'] as List).isEmpty) {
          return _buildEmptyWidget(
            "Aucune session programmée",
            "Aucun cours n'est programmé pour cette classe",
            Icons.event_busy,
          );
        }

        List<dynamic> sessions = data['sessions'];
        
        // Grouper les sessions par jour
        Map<String, List<dynamic>> sessionsByDay = _groupSessionsByDay(sessions);
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          physics: BouncingScrollPhysics(),
          itemCount: sessionsByDay.keys.length,
          itemBuilder: (context, index) {
            String day = sessionsByDay.keys.elementAt(index);
            List<dynamic> daySessions = sessionsByDay[day]!;
            return _buildDayCard(day, daySessions, false);
          },
        );
      },
    );
  }

  Widget _buildEmploiExamensList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('school_years')
          .doc(widget.schoolYear)
          .collection('levels')
          .doc(widget.level)
          .collection('exams')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget("Erreur lors du chargement des examens");
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget(
            "Aucun examen programmé",
            "Aucun examen n'est programmé pour votre niveau",
            Icons.quiz_outlined,
          );
        }

        List<QueryDocumentSnapshot> examDocs = snapshot.data!.docs;
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          physics: BouncingScrollPhysics(),
          itemCount: examDocs.length,
          itemBuilder: (context, index) {
            var examData = examDocs[index].data() as Map<String, dynamic>;
            return _buildExamenCard(examData);
          },
        );
      },
    );
  }

  Map<String, List<dynamic>> _groupSessionsByDay(List<dynamic> sessions) {
    Map<String, List<dynamic>> grouped = {};
    
    for (var session in sessions) {
      String day = session['jour'] ?? 'Non spécifié';
      if (!grouped.containsKey(day)) {
        grouped[day] = [];
      }
      grouped[day]!.add(session);
    }
    
    // Trier les sessions de chaque jour par heure
    grouped.forEach((day, sessions) {
      sessions.sort((a, b) {
        String timeA = a['heureDebut'] ?? '00:00';
        String timeB = b['heureDebut'] ?? '00:00';
        return timeA.compareTo(timeB);
      });
    });
    
    return grouped;
  }

  Widget _buildDayCard(String day, List<dynamic> sessions, bool isExam) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: Color.fromARGB(255, 40, 141, 0),
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 40, 141, 0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isExam ? Icons.quiz : Icons.schedule,
            size: 26,
            color: Color.fromARGB(255, 40, 141, 0),
          ),
        ),
        title: Text(
          _getDayName(day),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${sessions.length} ${isExam ? 'examen(s)' : 'cours'}',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: sessions.map<Widget>((session) {
                return _buildSessionItem(session, isExam);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionItem(Map<String, dynamic> session, bool isExam) {
    String matiere = session['matiere'] ?? 'Matière non spécifiée';
    String heureDebut = session['heureDebut'] ?? '00:00';
    String heureFin = session['heureFin'] ?? '00:00';
    String salle = session['salle'] ?? 'Salle non spécifiée';
    String professeur = session['professeur'] ?? 'Professeur non spécifié';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  matiere,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 40, 141, 0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$heureDebut - $heureFin',
                  style: TextStyle(
                    color: Color.fromARGB(255, 40, 141, 0),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                salle,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
              if (!isExam) ...[
                SizedBox(width: 16),
                Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    professeur,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (isExam && session['date'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  session['date'].toString(),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamenCard(Map<String, dynamic> examData) {
    String classe = examData['classe'] ?? 'Classe non spécifiée';
    String matiere = examData['matiere'] ?? 'Matière non spécifiée';
    String date = examData['date'] ?? 'Date non spécifiée';
    String heureDebut = examData['heureDebut'] ?? '00:00';
    String heureFin = examData['heureFin'] ?? '00:00';
    String salle = examData['salle'] ?? 'Salle non spécifiée';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.quiz,
                    size: 26,
                    color: Colors.red[600],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matiere,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        classe,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'EXAMEN',
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
                SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '$heureDebut - $heureFin',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  salle,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getDayName(String day) {
    final Map<String, String> dayNames = {
      'Lundi': 'Lundi',
      'Mardi': 'Mardi',
      'Mercredi': 'Mercredi',
      'Jeudi': 'Jeudi',
      'Vendredi': 'Vendredi',
      'Samedi': 'Samedi',
      'Dimanche': 'Dimanche',
    };
    
    return dayNames[day] ?? day;
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, 
               size: 64, 
               color: Colors.red.withOpacity(0.6)),
          SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, 
               size: 64, 
               color: Color(0xFF4285F4).withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}