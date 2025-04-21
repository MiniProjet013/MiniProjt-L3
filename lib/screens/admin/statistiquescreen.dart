import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../utils/constants.dart';

class StatistiquesEtablissementScreen extends StatefulWidget {
  @override
  _StatistiquesEtablissementScreenState createState() => _StatistiquesEtablissementScreenState();
}

class _StatistiquesEtablissementScreenState extends State<StatistiquesEtablissementScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  
  // Données statistiques
  Map<String, int> stats = {
    'totalProfs': 0,
    'totalEleves': 0,
    'totalEvenements': 0,
    'totalClasses': 0,
    'modificationsRecentes': 0,
    'ajoutsRecents': 0,
  };
  
  // Données pour les graphiques
  List<Map<String, dynamic>> eventsByType = [];
  List<Map<String, dynamic>> studentsPerClass = [];
  List<Map<String, dynamic>> activityByMonth = [];
  
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllStatistics();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllStatistics() async {
    setState(() => isLoading = true);
    
    try {
      // Chargement des compteurs de base
      await _loadBasicCounts();
      
      // Chargement des données pour les graphiques
      await Future.wait([
        _loadEventsByType(),
        _loadStudentsPerClass(),
        _loadActivityByMonth(),
      ]);
      
    } catch (e) {
      print("❌ Erreur lors du chargement des statistiques: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des statistiques"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }
  
  Future<void> _loadBasicCounts() async {
    // Nombre total de professeurs
    final profsSnapshot = await _db.collection('profs').count().get();
    
    // Nombre total d'élèves
    final elevesSnapshot = await _db.collection('eleves').count().get();
    
    // Nombre total d'événements
    final evenementsSnapshot = await _db.collection('evenements').count().get();
    
    // Nombre total de classes
    final classesSnapshot = await _db.collection('classes').count().get();
    
    // Nombre de modifications récentes (30 derniers jours)
    final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
    final modificationsSnapshot = await _db.collection('evenements')
        .where('dateModification', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .count().get();
    
    // Nombre d'ajouts récents (30 derniers jours)
    final ajoutsSnapshot = await _db.collection('evenements')
        .where('dateCreation', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .count().get();
    
    setState(() {
      stats['totalProfs'] = profsSnapshot.count ?? 0;
      stats['totalEleves'] = elevesSnapshot.count ?? 0;
      stats['totalEvenements'] = evenementsSnapshot.count ?? 0;
      stats['totalClasses'] = classesSnapshot.count ?? 0;
      stats['modificationsRecentes'] = modificationsSnapshot.count ?? 0;
      stats['ajoutsRecents'] = ajoutsSnapshot.count ?? 0;
    });
  }
  
  Future<void> _loadEventsByType() async {
    final snapshot = await _db.collection('evenements').get();
    
    Map<String, int> typeCount = {
      'Réunion': 0,
      'Examen': 0,
      'Activité': 0,
      'Autre': 0,
    };
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String? ?? 'Autre';
      typeCount[type] = (typeCount[type] ?? 0) + 1;
    }
    
    List<Map<String, dynamic>> result = [];
    typeCount.forEach((key, value) {
      result.add({
        'type': key,
        'count': value,
      });
    });
    
    setState(() {
      eventsByType = result;
    });
  }
  
  Future<void> _loadStudentsPerClass() async {
    // Charger les classes depuis Firestore
    final classesSnapshot = await _db.collection('classes').get();
    
    List<Map<String, dynamic>> result = [];
    
    for (var classeDoc in classesSnapshot.docs) {
      final classeData = classeDoc.data();
      final className = '${classeData['niveauxEtude']?.first ?? 'N/A'} ${classeData['numeroClasses'] ?? ''}';
      
      // Compter les élèves dans cette classe
      final studentsCount = await _db.collection('eleves')
          .where('idClasses', isEqualTo: classeDoc.id)
          .count()
          .get();
      
      result.add({
        'classe': className,
        'count': studentsCount.count ?? 0,
      });
    }
    
    setState(() {
      studentsPerClass = result;
    });
  }
  
  Future<void> _loadActivityByMonth() async {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 6, 1);
    
    // Récupérer les événements des 6 derniers mois
    final eventsSnapshot = await _db.collection('evenements')
        .where('dateCreation', isGreaterThan: Timestamp.fromDate(sixMonthsAgo))
        .get();
    
    Map<String, Map<String, int>> monthlyData = {};
    
    for (var doc in eventsSnapshot.docs) {
      final data = doc.data();
      final date = (data['dateCreation'] as Timestamp).toDate();
      final monthKey = '${_getMonthAbbreviation(date.month)} ${date.year}';
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {'events': 0, 'modifications': 0};
      }
      
      monthlyData[monthKey]!['events'] = monthlyData[monthKey]!['events']! + 1;
      
      // Vérifier si l'événement a été modifié
      if (data['dateModification'] != null) {
        monthlyData[monthKey]!['modifications'] = monthlyData[monthKey]!['modifications']! + 1;
      }
    }
    
    // Convertir en liste et trier par date
    List<Map<String, dynamic>> result = [];
    monthlyData.forEach((key, value) {
      result.add({
        'month': key,
        'events': value['events'],
        'modifications': value['modifications'],
      });
    });
    
    // Trier par date
    result.sort((a, b) {
      final aParts = a['month'].split(' ');
      final bParts = b['month'].split(' ');
      final aMonth = _getMonthNumber(aParts[0]);
      final bMonth = _getMonthNumber(bParts[0]);
      final aYear = int.parse(aParts[1]);
      final bYear = int.parse(bParts[1]);
      
      if (aYear != bYear) return aYear.compareTo(bYear);
      return aMonth.compareTo(bMonth);
    });
    
    setState(() {
      activityByMonth = result;
    });
  }
  
  String _getMonthAbbreviation(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }
  
  int _getMonthNumber(String monthAbbr) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months.indexOf(monthAbbr) + 1;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Statistiques de l'établissement"),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: "Résumé", icon: Icon(Icons.dashboard)),
            Tab(text: "Événements", icon: Icon(Icons.event)),
            Tab(text: "Classes", icon: Icon(Icons.school)),
          ],
        ),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildEventsTab(),
              _buildClassesTab(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllStatistics,
        child: Icon(Icons.refresh),
        tooltip: "Actualiser les statistiques",
      ),
    );
  }
  
  Widget _buildSummaryTab() {
    return RefreshIndicator(
      onRefresh: _loadAllStatistics,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Résumé général",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            
            // Cartes des statistiques principales
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard("Professeurs", stats['totalProfs'].toString(), Icons.person, Colors.blue),
                _buildStatCard("Élèves", stats['totalEleves'].toString(), Icons.people, Colors.green),
                _buildStatCard("Événements", stats['totalEvenements'].toString(), Icons.event, Colors.orange),
                _buildStatCard("Classes", stats['totalClasses'].toString(), Icons.school, Colors.purple),
              ],
            ),
            
            SizedBox(height: 24),
            Text(
              "Activité récente (30 derniers jours)",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Ajouts", stats['ajoutsRecents'].toString(), Icons.add_circle, Colors.green),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard("Modifications", stats['modificationsRecentes'].toString(), Icons.edit, Colors.amber),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            Text(
              "Activité mensuelle",
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: _buildActivityChart(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Répartition des événements",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            padding: EdgeInsets.all(8),
            child: _buildPieChart(),
          ),
          SizedBox(height: 24),
          
          // Tableau des événements par type
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Détails des événements par type",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Type d'événement", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Pourcentage", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...eventsByType.map((event) {
                        final percentage = stats['totalEvenements']! > 0 
                            ? (event['count'] / stats['totalEvenements']! * 100).toStringAsFixed(1)
                            : '0.0';
                        return TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(event['type']),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(event['count'].toString()),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text("$percentage%"),
                            ),
                          ],
                        );
                      }).toList(),
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Élèves par classe",
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            child: _buildBarChart(),
          ),
          SizedBox(height: 24),
          
          // Tableau des classes
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Détails des classes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 10),
                  Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Classe", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("Nombre d'élèves", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...studentsPerClass.map((classData) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(classData['classe']),
                            ),
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(classData['count'].toString()),
                            ),
                          ],
                        );
                      }).toList(),
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
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPieChart() {
    return eventsByType.isEmpty
      ? Center(child: Text("Aucune donnée disponible"))
      : PieChart(
          PieChartData(
            sections: eventsByType.asMap().entries.map((entry) {
              int idx = entry.key;
              var data = entry.value;
              List<Color> colors = [
                Colors.blueAccent,
                Colors.redAccent,
                Colors.greenAccent,
                Colors.orangeAccent,
              ];
              return PieChartSectionData(
                color: colors[idx % colors.length],
                value: data['count'].toDouble(),
                title: '${data['type']}\n${data['count']}',
                radius: 100,
                titleStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
            sectionsSpace: 2,
            centerSpaceRadius: 40,
          ),
        );
  }
  
  Widget _buildBarChart() {
    return studentsPerClass.isEmpty
      ? Center(child: Text("Aucune donnée disponible"))
      : BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: studentsPerClass.isNotEmpty 
                ? (studentsPerClass.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b) * 1.2)
                : 100,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                // ignore: deprecated_member_use
               //rection:Colors.blueGrey.withOpacity(0.9),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${studentsPerClass[groupIndex]['classe']}: ${rod.toY.round()} élèves',
                    TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        studentsPerClass[value.toInt()]['classe'],
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: false,
            ),
            barGroups: studentsPerClass.asMap().entries.map((entry) {
              int idx = entry.key;
              var data = entry.value;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: data['count'].toDouble(),
                    color: Colors.purpleAccent,
                    width: 20,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                ],
              );
            }).toList(),
          ),
        );
  }
  
  Widget _buildActivityChart() {
    return activityByMonth.isEmpty
      ? Center(child: Text("Aucune donnée disponible"))
      : LineChart(
          LineChartData(
            gridData: FlGridData(show: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        activityByMonth[value.toInt()]['month'],
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: activityByMonth.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var data = entry.value;
                  return FlSpot(idx.toDouble(), data['events'].toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
              LineChartBarData(
                spots: activityByMonth.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var data = entry.value;
                  return FlSpot(idx.toDouble(), data['modifications'].toDouble());
                }).toList(),
                isCurved: true,
                color: Colors.amberAccent,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        );
  }
}