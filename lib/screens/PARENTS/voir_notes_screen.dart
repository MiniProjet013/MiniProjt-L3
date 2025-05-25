import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notes_devoirs_screen.dart';
import 'notes_examens_screen.dart';
import 'moyenne_annuelle_screen.dart';

class VoirNotesScreen extends StatefulWidget {
  final String studentId;

  const VoirNotesScreen({super.key, required this.studentId});

  @override
  State<VoirNotesScreen> createState() => _VoirNotesScreenState();
}

class _VoirNotesScreenState extends State<VoirNotesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;
  int _devoirsCount = 0;
  int _examensCount = 0;
  double _moyenne = 0.0;
  ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
    _fetchCounts();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentData() async {
    try {
      final doc = await _firestore.collection('eleves').doc(widget.studentId).get();
      if (doc.exists) {
        setState(() {
          _studentData = doc.data();
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement des données élève: $e");
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final devoirsQuery = await _firestore.collection('note_devoir')
          .where('eleves', arrayContains: widget.studentId)
          .get();

      final examensQuery = await _firestore.collection('note_examen')
          .where('eleves', arrayContains: widget.studentId)
          .get();

      setState(() {
        _devoirsCount = devoirsQuery.docs.length;
        _examensCount = examensQuery.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Erreur de comptage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {
        "title": "Notes de Devoirs",
        "icon": Icons.assignment,
        "route": NotesDevoirsScreen(studentId: widget.studentId),
        "color": Colors.blue,
      },
      {
        "title": "Notes d'Examens",
        "icon": Icons.quiz,
        "route": NotesExamensScreen(studentId: widget.studentId),
        "color": Colors.purple,
      },
      {
        "title": "Moyenne Annuelle",
        "icon": Icons.bar_chart,
        "route": MoyenneAnnuelleScreen(studentId: widget.studentId),
        "value": _moyenne.toStringAsFixed(2),
        "color": Colors.orange,
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête fixe 
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 40, 141, 0), Color.fromARGB(255, 63, 136, 3)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      "VOIR LES NOTES",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(width: 48), // Pour équilibrer le layout
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading 
                ? _buildLoadingContent() 
                : _buildMainContent(categories),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: 3, // Placeholders pour les 3 catégories
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 54,
                    height: 54,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(List<Map<String, dynamic>> categories) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: BouncingScrollPhysics(),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => category["route"]),
          );
        },
        child: Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category["color"].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category["icon"],
                  size: 30,
                  color: category["color"],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  category["title"],
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}