import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotesDevoirsScreen extends StatefulWidget {
  final String studentId;

  const NotesDevoirsScreen({super.key, required this.studentId});

  @override
  State<NotesDevoirsScreen> createState() => _NotesDevoirsScreenState();
}

class _NotesDevoirsScreenState extends State<NotesDevoirsScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  String? _selectedMatiere;
  List<Map<String, dynamic>> _allNotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await _firestore
          .collection('note_devoir')
          .orderBy('dateCreation', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _allNotes = [];
          _isLoading = false;
        });
        return;
      }

      _allNotes = _extractNotes(snapshot.docs);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractNotes(List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> notes = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Vérifie les trois trimestres possibles
      final trimestres = ['1er trimestre', '2ème trimestre', '3ème trimestre'];
      
      for (String trimestre in trimestres) {
        if (data.containsKey(trimestre)) {
          final trimestreData = data[trimestre];
          if (trimestreData is Map<String, dynamic> && 
              trimestreData.containsKey(widget.studentId)) {
            
            final studentNoteData = trimestreData[widget.studentId];
            if (studentNoteData is Map<String, dynamic>) {
              notes.add({
                'note': studentNoteData['note'],
                'nomComplet': studentNoteData['nomComplet'] ?? 'Inconnu',
                'date': _parseDate(data),
                'matiere': data['matiere'] ?? 'Matière inconnue',
                'trimestre': trimestre,
                'classe': data['classe'] ?? 'Inconnue',
                'anneeScolaire': data['anneeScolaire'] ?? data['anneSocialre'] ?? '',
                'appreciation': studentNoteData['appreciation'] ?? '',
              });
            }
          }
        }
      }
    }

    return notes;
  }

  DateTime _parseDate(Map<String, dynamic> data) {
    try {
      if (data['dateCreation'] is Timestamp) {
        return (data['dateCreation'] as Timestamp).toDate();
      } else if (data['dateCreation'] is String) {
        return DateFormat('d MMMM yyyy', 'fr_FR')
            .parse(data['dateCreation'].split(' à ')[0]);
      }
    } catch (e) {
      debugPrint('Erreur parsing date: $e');
    }
    return DateTime.now();
  }

  List<String> get _matieres {
    final Set<String> matieres = _allNotes.map((note) => note['matiere'] as String).toSet();
    final List<String> matieresList = matieres.toList()..sort();
    return ['Toutes les matières', ...matieresList];
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_selectedMatiere == null || _selectedMatiere == 'Toutes les matières') {
      return _allNotes.where((note) {
        final trimestre = note['trimestre'];
        if (_tabController.index == 0) return trimestre == '1er trimestre';
        if (_tabController.index == 1) return trimestre == '2ème trimestre';
        return trimestre == '3ème trimestre';
      }).toList();
    }
    
    return _allNotes.where((note) {
      final matiere = note['matiere'];
      final trimestre = note['trimestre'];
      
      bool correctTrimestre = false;
      if (_tabController.index == 0) correctTrimestre = trimestre == '1er trimestre';
      else if (_tabController.index == 1) correctTrimestre = trimestre == '2ème trimestre';
      else correctTrimestre = trimestre == '3ème trimestre';
      
      return matiere == _selectedMatiere && correctTrimestre;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête avec dégradé comme dans VoirNotesScreen
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              colors: [Color.fromARGB(255, 40, 141, 0), Color.fromARGB(255, 63, 136, 3)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Barre supérieure avec titre et bouton retour
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "NOTES DE DEVOIRS",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(width: 48), // Pour équilibrer le layout
                      ],
                    ),
                  ),
                  
                  // TabBar pour les trimestres
                  Container(
                    padding: const EdgeInsets.only(top: 8),
                    alignment: Alignment.center,
                    child: TabBar(
                      controller: _tabController,
                      onTap: (_) => setState(() {}),
                      tabs: const [
                        Tab(text: "1er Trimestre"),
                        Tab(text: "2ème Trimestre"),
                        Tab(text: "3ème Trimestre"),
                      ],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      indicatorColor: Colors.white,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? _buildLoadingContent()
                : _error != null
                    ? _buildErrorWidget(_error!)
                    : _allNotes.isEmpty
                        ? _buildEmptyWidget()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 66, 84, 244)),
          ),
          const SizedBox(height: 16),
          Text(
            'Chargement des notes...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final filteredNotes = _filteredNotes;
    
    return Column(
      children: [
        // Filtre par matière (redessiné)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Filtrer par matière',
              labelStyle: TextStyle(color: Colors.grey[700]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            value: _selectedMatiere ?? 'Toutes les matières',
            items: _matieres.map((matiere) {
              return DropdownMenuItem<String>(
                value: matiere,
                child: Text(matiere),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMatiere = value;
              });
            },
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4285F4)),
            elevation: 2,
            dropdownColor: Colors.white,
          ),
        ),
        
        // Liste des notes
        Expanded(
          child: filteredNotes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune note disponible pour ${_selectedMatiere ?? 'ce trimestre'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredNotes.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) => _buildNoteCard(filteredNotes[index]),
              ),
        ),
      ],
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final noteValue = note['note']?.toDouble() ?? 0;
    final noteColor = _getNoteColor(noteValue);
    final DateTime noteDate = note['date'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icône pour la matière
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.book,
                    color: Color(0xFF4285F4),
                    size: 24,
                  ),
                ),
                
                // Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: noteColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${noteValue.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      color: noteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Matière - avec un style plus moderne
            Text(
              note['matiere'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF333333),
              ),
            ),
            
            const Divider(height: 24),
            
            // Informations sur la note
            _buildInfoRow("Élève", note['nomComplet']),
            _buildInfoRow("Classe", note['classe']),
            _buildInfoRow("Date du devoir", DateFormat('dd/MM/yyyy').format(noteDate)),
            _buildInfoRow("Année scolaire", note['anneeScolaire']),
            
            // Appréciation du professeur
            if (note['appreciation'] != null && note['appreciation'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.comment, size: 18, color: Color(0xFF5B6AF0)),
                      const SizedBox(width: 8),
                      const Text(
                        "Appréciation du professeur",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF5B6AF0),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Text(
                      note['appreciation'],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNoteColor(double note) {
    if (note >= 8) return const Color(0xFF4CAF50); // Vert
    if (note >= 6) return const Color(0xFF8BC34A); // Vert clair
    if (note >= 5) return const Color(0xFFFFA726);  // Orange
    return const Color(0xFFF44336);  // Rouge
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF44336), size: 60),
          const SizedBox(height: 20),
          const Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Color(0xFF4285F4),
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune note disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pour l\'élève: ${widget.studentId}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4285F4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}