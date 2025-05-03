import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmploiExamensScreen extends StatefulWidget {
  @override
  _EmploiExamensScreenState createState() => _EmploiExamensScreenState();
}

final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
final Color greenColor = Color.fromARGB(255, 1, 110, 5);
final Color lightColor = Color.fromARGB(255, 255, 255, 255);
final Color darkColor = Color(0xFF333333);

class _EmploiExamensScreenState extends State<EmploiExamensScreen> {
  String? selectedAnneeScolaire = '2024-2025';
  String? selectedLevel;
  String? selectedClass;
  String? selectedSubject;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  
  final List<String> anneesScolaires = ["2023-2024", "2024-2025", "2025-2026"];
  final List<String> levels = [
    "1ère année", 
    "2ème année", 
    "3ème année",
    "4ème année",
    "5ème année",
    "6ème année"
  ];
  final List<String> primarySubjects = [
    "Français",
    "Mathématiques",
    "Sciences",
    "Histoire-Géographie",
    "Anglais",
    "Arabe",
    "Éducation Islamique",
    "Activités Artistiques"
  ];
  
  List<String> classes = [];
  List<Map<String, dynamic>> examsSchedule = [];
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  bool isLoadingClasses = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    if (selectedLevel == null) return;
    
    setState(() {
      isLoadingClasses = true;
      classes = [];
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('niveauxEtude', arrayContains: selectedLevel)
          .get();

      setState(() {
        classes = snapshot.docs.map((doc) {
          final data = doc.data();
          return 'Classe ${data['numeroClasse']}';
        }).toList();
      });
    } catch (e) {
      print("Erreur de chargement des classes: $e");
    } finally {
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [orangeColor.withOpacity(0.8), greenColor.withOpacity(0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Gestion des Examens',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Planification des examens par niveau',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: _saveSchedule,
                tooltip: 'Enregistrer',
              ),
              IconButton(
                icon: Icon(Icons.print, color: Colors.white),
                onPressed: _printSchedule,
                tooltip: 'Imprimer',
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Le reste du code UI reste inchangé...
                // Calendrier pour sélectionner la date
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Sélectionnez le jour de l\'examen',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: orangeColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(Duration(days: 60)),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                            selectedDate = selectedDay;
                          });
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonDecoration: BoxDecoration(
                            color: orangeColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          formatButtonTextStyle: TextStyle(color: Colors.white),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: orangeColor,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: greenColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Sélection de l'année scolaire
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Année Scolaire',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: DropdownButtonFormField<String>(
                          value: selectedAnneeScolaire,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: anneesScolaires.map((annee) {
                            return DropdownMenuItem(
                              value: annee,
                              child: Text(annee),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedAnneeScolaire = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Sélection du niveau et classe
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Niveau et Classe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedLevel,
                              decoration: InputDecoration(
                                labelText: 'Niveau',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: levels.map((level) {
                                return DropdownMenuItem(
                                  value: level,
                                  child: Text(level),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedLevel = value;
                                  selectedClass = null;
                                  _loadClasses();
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: selectedClass,
                              decoration: InputDecoration(
                                labelText: 'Classe',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: classes.map((classe) {
                                return DropdownMenuItem(
                                  value: classe,
                                  child: Text(classe),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedClass = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Détails de l'examen
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: orangeColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Text(
                          'Détails de l\'examen',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedSubject,
                              decoration: InputDecoration(
                                labelText: 'Matière',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              items: primarySubjects.map((subject) {
                                return DropdownMenuItem(
                                  value: subject,
                                  child: Text(subject),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSubject = value;
                                });
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Salle',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                hintText: selectedClass ?? 'Sélectionnez une classe d\'abord',
                              ),
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, true),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Heure de début',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        prefixIcon: Icon(Icons.access_time, color: orangeColor),
                                      ),
                                      child: Text(
                                        startTime != null
                                            ? startTime!.format(context)
                                            : 'Sélectionner',
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _selectTime(context, false),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Heure de fin',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        prefixIcon: Icon(Icons.access_time, color: orangeColor),
                                      ),
                                      child: Text(
                                        endTime != null
                                            ? endTime!.format(context)
                                            : 'Sélectionner',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _addExam,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Ajouter l\'examen',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: greenColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste des examens programmés
                if (examsSchedule.isNotEmpty) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: orangeColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Examens programmés (${examsSchedule.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              if (isSaving)
                                CircularProgressIndicator(color: Colors.white)
                              else
                                ElevatedButton(
                                  onPressed: _saveSchedule,
                                  child: Text(
                                    'Enregistrer',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: greenColor,
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: examsSchedule.length,
                            separatorBuilder: (context, index) => Divider(height: 1),
                            itemBuilder: (context, index) {
                              final exam = examsSchedule[index];
                              return ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                title: Text(
                                  exam['subject'],
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text("${exam['date']}"),
                                    Text("${exam['startTime']} - ${exam['endTime']}"),
                                    Text("Salle: ${exam['salle']}"),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeExam(exam),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  void _addExam() {
    if (selectedAnneeScolaire == null ||
        selectedLevel == null ||
        selectedClass == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs requis")),
      );
      return;
    }

    setState(() {
      examsSchedule.add({
        'anneeScolaire': selectedAnneeScolaire,
        'level': selectedLevel,
        'class': selectedClass,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'startTime': startTime!.format(context),
        'endTime': endTime!.format(context),
        'subject': selectedSubject,
        'salle': selectedClass, // La salle est automatiquement remplie avec la classe
        'timestamp': DateTime.now(),
      });

      // Réinitialiser les champs
      startTime = null;
      endTime = null;
    });
  }

  void _removeExam(Map<String, dynamic> exam) {
    setState(() {
      examsSchedule.remove(exam);
    });
  }

  // Méthode modifiée pour la nouvelle structure Firestore
  Future<void> _saveSchedule() async {
    if (examsSchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucun examen à enregistrer")),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Regrouper les examens par matière
      Map<String, List<Map<String, dynamic>>> examsBySubject = {};
      
      for (final exam in examsSchedule) {
        final String subject = exam['subject'];
        if (!examsBySubject.containsKey(subject)) {
          examsBySubject[subject] = [];
        }
        examsBySubject[subject]!.add(exam);
      }
      
      // Sauvegarder les examens avec la nouvelle structure
      for (final exam in examsSchedule) {
        // Chemin: school_years/{anneeScolaire}/levels/{niveau}/exams/{examId}
        final schoolYearRef = FirebaseFirestore.instance
            .collection('school_years')
            .doc(exam['anneeScolaire']);
            
        final levelRef = schoolYearRef
            .collection('levels')
            .doc(exam['level']);
            
        final examRef = levelRef
            .collection('exams')
            .doc(); // Firestore génère un ID unique
        
        // Données de l'examen
        final examData = {
          'matiere': exam['subject'],
          'classe': exam['class'],
          'date': exam['date'],
          'heureDebut': exam['startTime'],
          'heureFin': exam['endTime'],
          'salle': exam['salle'],
          'timestamp': FieldValue.serverTimestamp(),
        };
        
        batch.set(examRef, examData);
      }

      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Emploi des examens enregistré avec succès")),
      );
      
      // Vider la liste après sauvegarde réussie
      setState(() {
        examsSchedule = [];
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement: $e")),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  // Méthode pour récupérer les examens d'un niveau spécifique
  Future<List<Map<String, dynamic>>> getExamsByLevel(String anneeScolaire, String niveau) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('school_years')
          .doc(anneeScolaire)
          .collection('levels')
          .doc(niveau)
          .collection('exams')
          .orderBy('date')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print("Erreur lors de la récupération des examens: $e");
      return [];
    }
  }

  // Méthode pour récupérer les examens d'une matière spécifique
  Future<List<Map<String, dynamic>>> getExamsBySubject(String anneeScolaire, String niveau, String matiere) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('school_years')
          .doc(anneeScolaire)
          .collection('levels')
          .doc(niveau)
          .collection('exams')
          .where('matiere', isEqualTo: matiere)
          .orderBy('date')
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print("Erreur lors de la récupération des examens: $e");
      return [];
    }
  }

  void _printSchedule() {
    if (examsSchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Aucun examen à imprimer")),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Préparation de l'impression...")),
    );
  }
}