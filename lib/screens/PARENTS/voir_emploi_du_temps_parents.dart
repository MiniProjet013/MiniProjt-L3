import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleScreen extends StatefulWidget {
  final String? eleveId;
  final String? classeId;
  final String? anneeScolaire;

  const ScheduleScreen({
    Key? key,
    this.eleveId,
    this.classeId,
    this.anneeScolaire,
  }) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  String? errorMessage;
  
  // بيانات التلميذ
  Map<String, dynamic> eleveInfo = {};
  
  // استعمال الزمن العادي
  Map<String, List<ScheduleItem>> _scheduleItems = {};
  
  // استعمال الزمن للامتحانات
  List<ExamItem> _examItems = [];

  final List<String> _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // تحميل بيانات التلميذ
      if (widget.eleveId != null) {
        DocumentSnapshot eleveDoc = await FirebaseFirestore.instance
            .collection('eleves')
            .doc(widget.eleveId)
            .get();

        if (eleveDoc.exists) {
          eleveInfo = eleveDoc.data() as Map<String, dynamic>;
        }
      }

      // تحميل استعمال الزمن العادي
      await _loadRegularSchedule();
      
      // تحميل استعمال الزمن للامتحانات
      await _loadExamSchedule();

    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des données: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadRegularSchedule() async {
    Map<String, List<ScheduleItem>> loadedSchedule = {};
    
    // تهيئة الأيام بقوائم فارغة
    for (String day in _weekdays) {
      loadedSchedule[day] = [];
    }

    try {
      // البحث في مجموعة emplois_classes
      if (widget.classeId != null && widget.anneeScolaire != null) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('emplois_classes')
            .where('classeId', isEqualTo: widget.classeId)
            .where('anneeScolaire', isEqualTo: widget.anneeScolaire)
            .get();

        print('Found ${querySnapshot.docs.length} schedule documents');

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          
          print('Schedule document data: $data');
          
          // التحقق من وجود حقل sessions
          if (data.containsKey('sessions') && data['sessions'] is List) {
            List<dynamic> sessions = data['sessions'];
            
            for (var session in sessions) {
              if (session is Map<String, dynamic>) {
                String jour = session['jour'] ?? '';
                String matiere = session['matiere'] ?? '';
                String heureDebut = session['heureDebut'] ?? '';
                String heureFin = session['heureFin'] ?? '';
                String salle = session['salle'] ?? '';
                String profId = session['profId'] ?? '';

                print('Processing session: jour=$jour, matiere=$matiere, heureDebut=$heureDebut, heureFin=$heureFin');

                if (jour.isNotEmpty && _weekdays.contains(jour) && matiere.isNotEmpty) {
                  ScheduleItem item = ScheduleItem(
                    title: matiere,
                    timeSlot: '$heureDebut - $heureFin',
                    location: salle.isNotEmpty ? salle : 'Non spécifié',
                    type: 'Cours',
                    profId: profId,
                  );
                  loadedSchedule[jour]!.add(item);
                }
              }
            }
          } else {
            // إذا لم يكن هناك حقل sessions، جرب البنية القديمة
            String jour = data['jour'] ?? '';
            String matiere = data['matiere'] ?? '';
            String heureDebut = data['heureDebut'] ?? '';
            String heureFin = data['heureFin'] ?? '';
            String salle = data['salle'] ?? '';
            String profId = data['profId'] ?? '';

            if (jour.isNotEmpty && _weekdays.contains(jour) && matiere.isNotEmpty) {
              ScheduleItem item = ScheduleItem(
                title: matiere,
                timeSlot: '$heureDebut - $heureFin',
                location: salle.isNotEmpty ? salle : 'Non spécifié',
                type: 'Cours',
                profId: profId,
              );
              loadedSchedule[jour]!.add(item);
            }
          }
        }
      }

      // ترتيب الحصص حسب الوقت
      for (String day in loadedSchedule.keys) {
        loadedSchedule[day]!.sort((a, b) {
          try {
            String timeA = a.timeSlot.split(' - ')[0];
            String timeB = b.timeSlot.split(' - ')[0];
            
            // تحويل الوقت إلى دقائق للمقارنة
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
      print('Erreur lors du chargement de l\'emploi du temps: $e');
      setState(() {
        errorMessage = 'Erreur lors du chargement de l\'emploi du temps: $e';
      });
    }
  }

  int _timeToMinutes(String time) {
    try {
      // إزالة PM/AM إذا وجدت
      String cleanTime = time.replaceAll(RegExp(r'[APM\s]'), '');
      
      List<String> parts = cleanTime.split(':');
      if (parts.length >= 2) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        
        // إذا كان الوقت يحتوي على PM وليس 12، أضف 12 ساعة
        if (time.toUpperCase().contains('PM') && hours != 12) {
          hours += 12;
        }
        // إذا كان الوقت يحتوي على AM و12، حوله إلى 0
        if (time.toUpperCase().contains('AM') && hours == 12) {
          hours = 0;
        }
        
        return hours * 60 + minutes;
      }
    } catch (e) {
      print('Error parsing time: $time - $e');
    }
    return 0;
  }

  Future<void> _loadExamSchedule() async {
    List<ExamItem> loadedExams = [];

    try {
      if (widget.classeId != null && widget.anneeScolaire != null) {
        // أولاً، الحصول على معلومات التلميذ للوصول إلى مستوى الدراسة
        String niveau = '';
        if (eleveInfo.isNotEmpty) {
          niveau = eleveInfo['niveau'] ?? '';
        }
        
        print('Searching for exams with:');
        print('- classeId: ${widget.classeId}');
        print('- anneeScolaire: ${widget.anneeScolaire}');
        print('- niveau: $niveau');

        // البحث في مجموعة examens بطرق مختلفة
        List<QuerySnapshot> queryResults = [];
        
        // البحث الأول: حسب classe
        try {
          QuerySnapshot query1 = await FirebaseFirestore.instance
              .collection('examens')
              .where('classe', isEqualTo: widget.classeId)
              .where('anneeScolaire', isEqualTo: widget.anneeScolaire)
              .get();
          queryResults.add(query1);
          print('Query 1 (classe): Found ${query1.docs.length} documents');
        } catch (e) {
          print('Query 1 failed: $e');
        }

        // البحث الثاني: حسب classeId
        try {
          QuerySnapshot query2 = await FirebaseFirestore.instance
              .collection('examens')
              .where('classeId', isEqualTo: widget.classeId)
              .where('anneeScolaire', isEqualTo: widget.anneeScolaire)
              .get();
          queryResults.add(query2);
          print('Query 2 (classeId): Found ${query2.docs.length} documents');
        } catch (e) {
          print('Query 2 failed: $e');
        }

        // البحث الثالث: حسب niveau فقط (إذا كان متوفراً)
        if (niveau.isNotEmpty) {
          try {
            QuerySnapshot query3 = await FirebaseFirestore.instance
                .collection('examens')
                .where('niveau', isEqualTo: niveau)
                .where('anneeScolaire', isEqualTo: widget.anneeScolaire)
                .get();
            queryResults.add(query3);
            print('Query 3 (niveau): Found ${query3.docs.length} documents');
          } catch (e) {
            print('Query 3 failed: $e');
          }
        }

        // البحث الرابع: حسب anneeScolaire فقط (للحصول على جميع الامتحانات)
        try {
          QuerySnapshot query4 = await FirebaseFirestore.instance
              .collection('examens')
              .where('anneeScolaire', isEqualTo: widget.anneeScolaire)
              .get();
          
          // تصفية النتائج للحصول على الامتحانات المناسبة للطالب
          List<QueryDocumentSnapshot> filteredDocs = query4.docs.where((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            String docClasse = data['classe'] ?? data['classeId'] ?? '';
            String docNiveau = data['niveau'] ?? '';
            
            return docClasse == widget.classeId || 
                   (niveau.isNotEmpty && docNiveau == niveau);
          }).toList();
          
          if (filteredDocs.isNotEmpty) {
            // إنشاء QuerySnapshot وهمي للنتائج المفلترة
            queryResults.add(query4);
          }
          print('Query 4 (filtered): Found ${filteredDocs.length} relevant documents');
        } catch (e) {
          print('Query 4 failed: $e');
        }

        // معالجة جميع النتائج
        Set<String> addedExams = {}; // لتجنب التكرار
        
        for (QuerySnapshot querySnapshot in queryResults) {
          for (QueryDocumentSnapshot doc in querySnapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            
            // التحقق من أن الامتحان مخصص لهذا الطالب
            String docClasse = data['classe'] ?? data['classeId'] ?? '';
            String docNiveau = data['niveau'] ?? '';
            
            bool isRelevant = docClasse == widget.classeId || 
                             (niveau.isNotEmpty && docNiveau == niveau);
            
            if (!isRelevant) continue;
            
            print('Processing exam document: $data');
            
            String matiere = data['matiere'] ?? '';
            String date = data['date'] ?? '';
            String heureDebut = data['heureDebut'] ?? '';
            String heureFin = data['heureFin'] ?? '';
            String salle = data['salle'] ?? '';
            String type = data['type'] ?? 'examen';
            String status = data['status'] ?? '';
            
            // إنشاء مفتاح فريد للامتحان لتجنب التكرار
            String examKey = '$matiere-$date-$heureDebut-$heureFin';
            
            if (matiere.isNotEmpty && !addedExams.contains(examKey)) {
              addedExams.add(examKey);
              
              ExamItem exam = ExamItem(
                subject: matiere,
                date: date.isNotEmpty ? date : 'Date non spécifiée',
                timeSlot: (heureDebut.isNotEmpty && heureFin.isNotEmpty) 
                    ? '$heureDebut - $heureFin' 
                    : 'Horaire non spécifié',
                location: salle.isNotEmpty ? salle : 'Lieu non spécifié',
                type: type,
                niveau: docNiveau,
                status: status,
                classe: docClasse,
              );
              
              loadedExams.add(exam);
              print('Added exam: ${exam.subject} on ${exam.date}');
            }
          }
        }
        
        // ترتيب الامتحانات حسب التاريخ والوقت
        loadedExams.sort((a, b) {
          try {
            // ترتيب حسب التاريخ أولاً
            if (a.date != 'Date non spécifiée' && b.date != 'Date non spécifiée') {
              int dateComparison = a.date.compareTo(b.date);
              if (dateComparison != 0) return dateComparison;
              
              // إذا كان التاريخ نفسه، رتب حسب الوقت
              String timeA = a.timeSlot.split(' - ')[0];
              String timeB = b.timeSlot.split(' - ')[0];
              int minutesA = _timeToMinutes(timeA);
              int minutesB = _timeToMinutes(timeB);
              return minutesA.compareTo(minutesB);
            }
            return a.subject.compareTo(b.subject);
          } catch (e) {
            return a.subject.compareTo(b.subject);
          }
        });
        
        print('Total loaded exams: ${loadedExams.length}');
      }

      setState(() {
        _examItems = loadedExams;
      });

    } catch (e) {
      print('Erreur lors du chargement des examens: $e');
      setState(() {
        errorMessage = 'Erreur lors du chargement des examens: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emploi du temps',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 3, 143, 8),
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
            Tab(text: 'Emploi du temps'),
            Tab(text: 'Examens'),
          ],
        ),
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color.fromARGB(255, 1, 133, 6),
                  ),
                  SizedBox(height: 16),
                  Text('Chargement des données...'),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Erreur',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudentData,
                        child: Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 3, 136, 8),
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
                    _buildExamScheduleTab(),
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
          // معلومات التلميذ
          if (eleveInfo.isNotEmpty) _buildStudentInfo(),
          
          // إضافة معلومات تشخيص
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 235, 134, 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Classe: ${widget.classeId}, Année: ${widget.anneeScolaire}\n'
              'Total des jours avec cours: ${_scheduleItems.values.where((items) => items.isNotEmpty).length}',
              style: TextStyle(fontSize: 12, color: const Color.fromARGB(255, 238, 238, 238)),
            ),
          ),
          
          Expanded(
            child: _scheduleItems.isEmpty || _scheduleItems.values.every((items) => items.isEmpty)
                ? _buildEmptyState('Aucun emploi du temps trouvé')
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

  Widget _buildExamScheduleTab() {
    return Container(
      color: const Color(0xFFFFFDE7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات التلميذ
          if (eleveInfo.isNotEmpty) _buildStudentInfo(),
          
          // إضافة معلومات تشخيص
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations de recherche:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                ),
                Text(
                  'Classe: ${widget.classeId}',
                  style: TextStyle(fontSize: 11, color: const Color.fromARGB(255, 228, 127, 3)),
                ),
                Text(
                  'Année: ${widget.anneeScolaire}',
                  style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                ),
                if (eleveInfo.isNotEmpty && eleveInfo['niveau'] != null)
                  Text(
                    'Niveau: ${eleveInfo['niveau']}',
                    style: TextStyle(fontSize: 11, color: Colors.orange[600]),
                  ),
                Text(
                  'Total des examens trouvés: ${_examItems.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange[700]),
                ),
              ],
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

  Widget _buildStudentInfo() {
    String nom = eleveInfo['nom'] ?? '';
    String prenom = eleveInfo['prenom'] ?? '';
    String classe = eleveInfo['classeId'] ?? widget.classeId ?? '';
    String niveau = eleveInfo['niveau'] ?? '';

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
                "${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}",
                style: TextStyle(
                  color: Color.fromARGB(255, 3, 138, 7),
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
                  '$prenom $nom',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Classe: $classe${niveau.isNotEmpty ? ' - $niveau' : ''}',
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
                child: const Icon(
                  Icons.event_busy,
                  color: Color(0xFFE67E22),
                ),
              ),
              title: Text(
                day,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFFE67E22),
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
          child: const Icon(
            Icons.event_note,
            color: Color(0xFFE67E22),
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
                _buildExamDetail(Icons.access_time, 'Horaire', exam.timeSlot),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.location_on, 'Lieu', exam.location),
                const SizedBox(height: 8),
                _buildExamDetail(Icons.category, 'Type', exam.type),
                if (exam.niveau.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildExamDetail(Icons.school, 'Niveau', exam.niveau),
                ],
                if (exam.classe.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildExamDetail(Icons.class_, 'Classe', exam.classe),
                ],
                if (exam.status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildExamDetail(Icons.info, 'Statut', exam.status),
                ],
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
                        backgroundColor: const Color(0xFFE67E22),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informations copiées'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  Widget _buildScheduleItemTile(ScheduleItem item) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: Color(0xFF4CAF50),
            width: 4,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Color(0xFFE67E22)),
              SizedBox(width: 8),
              Text(
                item.timeSlot,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E22),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.subject, size: 16, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
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
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Color(0xFF4CAF50)),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.type,
                  style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Les données seront affichées ici une fois disponibles',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudentData,
            icon: Icon(Icons.refresh),
            label: Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
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
  final String profId;

  ScheduleItem({
    required this.title,
    required this.timeSlot,
    required this.location,
    required this.type,
    this.profId = '',
  });
}

class ExamItem {
  final String subject;
  final String date;
  final String timeSlot;
  final String location;
  final String type;
  final String niveau;
  final String status;
  final String classe;

  ExamItem({
    required this.subject,
    required this.date,
    required this.timeSlot,
    required this.location,
    required this.type,
    this.niveau = '',
    this.status = '',
    this.classe = '',
  });
}