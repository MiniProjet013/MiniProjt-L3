import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistiquesEtablissementScreen extends StatefulWidget {
  @override
  _StatistiquesEtablissementScreenState createState() => _StatistiquesEtablissementScreenState();
}

class _StatistiquesEtablissementScreenState extends State<StatistiquesEtablissementScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  
  // Couleurs principales
  final orangeColor = Color.fromARGB(255, 218, 64, 3);
  final greenColor = Color.fromARGB(255, 1, 110, 5);
  final lightColor = Colors.white;
  final darkColor = Color(0xFF333333);
  
  // Données statistiques
  Map<String, int> stats = {
    'totalProfs': 0,
    'totalEleves': 0,
    'totalEvenements': 0,
    'totalClasses': 0,
  };
  
  // Données pour les graphiques
  List<Map<String, dynamic>> eventsByType = [];
  
  // Listes pour les dialogues
  List<Map<String, dynamic>> profsList = [];
  List<Map<String, dynamic>> elevesList = [];
  List<Map<String, dynamic>> evenementsList = [];
  List<Map<String, dynamic>> classesList = [];
  
  late TabController _tabController;
  
  // Variables pour la gestion des classes et élèves
  String? selectedClass;
  List<Map<String, dynamic>> classStudentsList = [];
  bool isLoadingClassStudents = false;
  bool isLoadingClasses = true;
  String? selectedClassNumber;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllStatistics();
    _loadClassesForTab();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllStatistics() async {
    setState(() => isLoading = true);
    
    try {
      await Future.wait([
        _loadBasicCounts(),
        _loadEventsByType(),
        _loadListsForDialogs(),
      ]);
    } catch (e) {
      print("Erreur: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<void> _loadBasicCounts() async {
    final counts = await Future.wait([
      _db.collection('profs').count().get(),
      _db.collection('eleves').count().get(),
      _db.collection('evenements').count().get(),
      _db.collection('classes').count().get(),
    ]);
    
    setState(() {
      stats['totalProfs'] = counts[0].count ?? 0;
      stats['totalEleves'] = counts[1].count ?? 0;
      stats['totalEvenements'] = counts[2].count ?? 0;
      stats['totalClasses'] = counts[3].count ?? 0;
    });
  }
  
  Future<void> _loadEventsByType() async {
    final snapshot = await _db.collection('evenements').get();
    Map<String, int> typeCount = {};
    
    for (var doc in snapshot.docs) {
      final type = doc.data()['type'] as String? ?? 'Autre';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    setState(() {
      eventsByType = typeCount.entries
          .map((e) => {'type': e.key, 'count': e.value})
          .toList();
    });
  }
  
  Future<void> _loadListsForDialogs() async {
    final [profs, eleves, evenements, classes] = await Future.wait([
      _db.collection('profs').get(),
      _db.collection('eleves').get(),
      _db.collection('evenements').get(),
      _db.collection('classes').get(),
    ]);
    
    setState(() {
      profsList = profs.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
        };
      }).toList();
      
      elevesList = eleves.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nom': data['nom'] ?? '',
          'prenom': data['prenom'] ?? '',
          'idClasse': data['idClasse'] ?? '',
          'numeroClasse': data['numeroClasse'] ?? '',
        };
      }).toList();
      
      evenementsList = evenements.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'] ?? 'Autre',
          'description': data['description'] ?? '',
        };
      }).toList();
      
      classesList = classes.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'numeroClasse': data['numeroClasse'] ?? '',
          'niveau': data['niveauxEtude']?.first ?? '',
        };
      }).toList();
    });
  }
  
  // Fonctions pour la gestion des classes dans l'onglet Classes
  Future<void> _loadClassesForTab() async {
    setState(() {
      isLoadingClasses = true;
      classesList.clear();
    });

    try {
      QuerySnapshot classesSnapshot = await _db.collection('classes').get();
      
      List<Map<String, dynamic>> classes = classesSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'numeroClasse': data['numeroClasse'] ?? '',
          'niveau': data['niveauxEtude']?.first ?? '',
        };
      }).toList();

      // Trier les classes par numéro
      classes.sort((a, b) => a['numeroClasse'].compareTo(b['numeroClasse']));

      setState(() {
        classesList = classes;
        isLoadingClasses = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des classes: $e");
      setState(() {
        isLoadingClasses = false;
      });
    }
  }

  Future<void> _loadStudentsForClass(String classNumber) async {
    setState(() {
      isLoadingClassStudents = true;
      classStudentsList.clear();
    });

    try {
      QuerySnapshot studentsSnapshot = await _db
          .collection('eleves')
          .where('numeroClasse', isEqualTo: classNumber)
          .get();

      List<Map<String, dynamic>> students = [];

      for (var studentDoc in studentsSnapshot.docs) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

        students.add({
          'id': studentDoc.id,
          'nom': studentData['nom'] ?? '',
          'prenom': studentData['prenom'] ?? '',
          'nomComplet': "${studentData['prenom'] ?? ''} ${studentData['nom'] ?? ''}",
          'numeroClasse': studentData['numeroClasse'] ?? '',
        });
      }

      // Trier les élèves par nom
      students.sort((a, b) => a['nomComplet'].compareTo(b['nomComplet']));

      setState(() {
        classStudentsList = students;
        isLoadingClassStudents = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des élèves: $e");
      setState(() {
        isLoadingClassStudents = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text("Statistiques de l'établissement", style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [orangeColor, greenColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: darkColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: orangeColor,
                tabs: [
                  Tab(text: "Résumé", icon: Icon(Icons.dashboard)),
                  Tab(text: "Événements", icon: Icon(Icons.event)),
                  Tab(text: "Classes", icon: Icon(Icons.school)),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: isLoading
              ? Center(child: CircularProgressIndicator(color: orangeColor))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSummaryTab(),
                    _buildEventsTab(),
                    _buildClassesTab(),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllStatistics,
        backgroundColor: orangeColor,
        child: Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadAllStatistics,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard("Professeurs", stats['totalProfs'].toString(), Icons.person, orangeColor, () {
                  _showProfListDialog();
                }),
                _buildStatCard("Élèves", stats['totalEleves'].toString(), Icons.people, greenColor, () {
                  _showStudentListDialog();
                }),
                _buildStatCard("Événements", stats['totalEvenements'].toString(), Icons.event, orangeColor, () {
                  _showEventListDialog();
                }),
                _buildStatCard("Classes", stats['totalClasses'].toString(), Icons.school, greenColor, () {
                  _showClassListDialog();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text("Répartition des événements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: _buildPieChart(),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6)],
            ),
          ),
          SizedBox(height: 24),
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Détails par type", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: orangeColor)),
                  SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: greenColor.withOpacity(0.1)),
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text("Type", style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.all(8), child: Text("%", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      ...eventsByType.map((event) => TableRow(
                        children: [
                          Padding(padding: EdgeInsets.all(8), child: Text(event['type'])),
                          Padding(padding: EdgeInsets.all(8), child: Text(event['count'].toString())),
                          Padding(padding: EdgeInsets.all(8), child: Text(
                            "${(event['count'] / stats['totalEvenements']! * 100).toStringAsFixed(1)}%",
                          )),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClassesTab() {
    return RefreshIndicator(
      onRefresh: _loadClassesForTab,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Sélecteur de classe
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Sélectionnez une classe",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: orangeColor,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (isLoadingClasses)
                      Center(child: CircularProgressIndicator())
                    else if (classesList.isEmpty)
                      Center(child: Text("Aucune classe disponible"))
                    else
                      _buildClassDropdown(),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Liste des élèves de la classe sélectionnée
            if (selectedClassNumber != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Élèves de la classe $selectedClassNumber",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: orangeColor,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (isLoadingClassStudents)
                        Center(child: CircularProgressIndicator())
                      else if (classStudentsList.isEmpty)
                        Center(child: Text("Aucun élève dans cette classe"))
                      else
                        _buildStudentList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildClassDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: "Choisir une classe",
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      value: selectedClassNumber,
      items: classesList.map<DropdownMenuItem<String>>((classe) => 
        DropdownMenuItem<String>(
          value: classe['numeroClasse'] as String,
          child: Text("Classe ${classe['numeroClasse']} (${classe['niveau']})"),
        )
      ).toList(),
      onChanged: (value) {
        setState(() {
          selectedClassNumber = value;
        });
        if (value != null) {
          _loadStudentsForClass(value);
        }
      },
    );
  }
  
  Widget _buildStudentList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: classStudentsList.length,
      itemBuilder: (context, index) {
        final student = classStudentsList[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: greenColor.withOpacity(0.2),
              child: Icon(Icons.person, color: greenColor),
            ),
            title: Text(
              student['nomComplet'],
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Classe: ${student['numeroClasse']}"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ),
        );
      },
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, Function()? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.4)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              SizedBox(height: 4),
              Text(title, style: TextStyle(fontSize: 14, color: darkColor)),
              if (onTap != null) Icon(Icons.info_outline, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPieChart() {
    return eventsByType.isEmpty
      ? Center(child: Text("Aucune donnée disponible"))
      : PieChart(
          PieChartData(
            sections: eventsByType.map((e) => PieChartSectionData(
              color: _getColorForType(e['type']),
              value: e['count'].toDouble(),
              title: '${e['type']}\n${e['count']}',
              radius: 100,
              titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            )).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        );
  }
  
  Color _getColorForType(String type) {
    switch (type) {
      case 'Réunion': return Colors.blueAccent;
      case 'Examen': return Colors.redAccent;
      case 'Activité': return Colors.greenAccent;
      default: return Colors.purpleAccent;
    }
  }
  
  void _showProfListDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Liste des professeurs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
              SizedBox(height: 16),
              Expanded(
                child: profsList.isEmpty
                  ? Center(child: Text("Aucun professeur"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: profsList.length,
                      itemBuilder: (context, index) {
                        final prof = profsList[index];
                        return ListTile(
                          leading: Icon(Icons.person, color: orangeColor),
                          title: Text("${prof['prenom']} ${prof['nom']}"),
                        );
                      },
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer', style: TextStyle(color: orangeColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStudentListDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Liste des élèves", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
              SizedBox(height: 16),
              Expanded(
                child: elevesList.isEmpty
                  ? Center(child: Text("Aucun élève"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: elevesList.length,
                      itemBuilder: (context, index) {
                        final eleve = elevesList[index];
                        final classe = classesList.firstWhere(
                          (classe) => classe['id'] == eleve['idClasse'],
                          orElse: () => {'numeroClasse': 'N/A', 'niveau': 'N/A'});
                        
                        return ListTile(
                          leading: Icon(Icons.person, color: greenColor),
                          title: Text("${eleve['prenom']} ${eleve['nom']}"),
                          subtitle: Text("Classe: ${classe['numeroClasse']} (${classe['niveau']})"),
                        );
                      },
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer', style: TextStyle(color: orangeColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showEventListDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Liste des événements", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
              SizedBox(height: 16),
              Expanded(
                child: evenementsList.isEmpty
                  ? Center(child: Text("Aucun événement"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: evenementsList.length,
                      itemBuilder: (context, index) {
                        final event = evenementsList[index];
                        return ListTile(
                          leading: Icon(Icons.circle, color: _getColorForType(event['type']), size: 12),
                          title: Text(event['type'], style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: event['description'].isNotEmpty 
                              ? Text(event['description'])
                              : null,
                        );
                      },
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer', style: TextStyle(color: orangeColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showClassListDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Liste des classes", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: orangeColor)),
              SizedBox(height: 16),
              Expanded(
                child: classesList.isEmpty
                  ? Center(child: Text("Aucune classe"))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: classesList.length,
                      itemBuilder: (context, index) {
                        final classe = classesList[index];
                        return ListTile(
                          leading: Icon(Icons.school, color: greenColor),
                          title: Text("Classe ${classe['numeroClasse']}"),
                          subtitle: Text("Niveau: ${classe['niveau']}"),
                        );
                      },
                    ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fermer', style: TextStyle(color: orangeColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}