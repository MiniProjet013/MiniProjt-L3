import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomeworkScreen extends StatefulWidget {
  final String studentId;

  const HomeworkScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  
  String? _selectedMatiere;
  List<Map<String, dynamic>> _allDevoirs = [];
  Map<String, dynamic>? _studentInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentInfoAndDevoirs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudentInfoAndDevoirs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger les informations de l'élève pour obtenir sa classe
      await _loadStudentInfo();
      
      if (_studentInfo != null) {
        // Charger les devoirs de la classe de l'élève
        await _loadDevoirs();
      }
      
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

  Future<void> _loadStudentInfo() async {
    try {
      final studentSnapshot = await _firestore
          .collection('eleves')
          .doc(widget.studentId)
          .get();

      if (studentSnapshot.exists) {
        _studentInfo = studentSnapshot.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Erreur lors du chargement des informations de l\'élève: $e');
    }
  }

  Future<void> _loadDevoirs() async {
    if (_studentInfo == null) return;

    final studentClass = _studentInfo!['classe'] ?? _studentInfo!['idClasse'];
    final currentYear = _studentInfo!['anneeScolaire'] ?? DateTime.now().year.toString();

    try {
      final devoirsSnapshot = await _firestore
          .collection('devoir')
          .where('classe', isEqualTo: studentClass)
          .where('anneeScolaire', isEqualTo: currentYear)
          .orderBy('timestamp', descending: true)
          .get();

      _allDevoirs = devoirsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

    } catch (e) {
      print('Erreur lors du chargement des devoirs: $e');
      // Essayer sans le orderBy si l'index n'existe pas
      final devoirsSnapshot = await _firestore
          .collection('devoir')
          .where('classe', isEqualTo: studentClass)
          .where('anneeScolaire', isEqualTo: currentYear)
          .get();

      _allDevoirs = devoirsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Trier manuellement par timestamp
      _allDevoirs.sort((a, b) {
        final aTime = a['timestamp'];
        final bTime = b['timestamp'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        
        final aDate = aTime is Timestamp ? aTime.toDate() : DateTime.tryParse(aTime.toString());
        final bDate = bTime is Timestamp ? bTime.toDate() : DateTime.tryParse(bTime.toString());
        
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        
        return bDate.compareTo(aDate);
      });
    }
  }

  List<String> get _matieres {
    final Set<String> matieres = _allDevoirs.map((devoir) => devoir['matiere'] as String? ?? 'Autre').toSet();
    final List<String> matieresList = matieres.toList()..sort();
    return ['Toutes les matières', ...matieresList];
  }

  List<Map<String, dynamic>> get _filteredDevoirs {
    if (_selectedMatiere == null || _selectedMatiere == 'Toutes les matières') {
      return _allDevoirs;
    }
    
    return _allDevoirs.where((devoir) {
      final matiere = devoir['matiere'] ?? 'Autre';
      return matiere == _selectedMatiere;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête fixe avec gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 40, 141, 0), Color.fromARGB(255, 63, 136, 3)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "DEVOIRS DE LA CLASSE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadStudentInfoAndDevoirs,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? _buildLoadingContent()
                : _error != null
                    ? _buildErrorWidget()
                    : _allDevoirs.isEmpty
                        ? _buildEmptyWidget()
                        : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: 5, // Placeholders pour les devoirs
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 54,
                    height: 54,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
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

  Widget _buildContent() {
    final filteredDevoirs = _filteredDevoirs;
    
    return Column(
      children: [
        // Informations sur la classe
        if (_studentInfo != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4285F4).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.class_, color: Color(0xFF4285F4)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classe: ${_studentInfo!['classe'] ?? _studentInfo!['idClasse'] ?? 'Non définie'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Année scolaire: ${_studentInfo!['anneeScolaire'] ?? 'Non définie'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Filtre par matière
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
        
        // Liste des devoirs
        Expanded(
          child: filteredDevoirs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, 
                         size: 64, 
                         color: const Color(0xFF4285F4).withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      _selectedMatiere == null || _selectedMatiere == 'Toutes les matières'
                        ? "Aucun devoir disponible pour cette classe"
                        : "Aucun devoir en $_selectedMatiere",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: filteredDevoirs.length,
                itemBuilder: (context, index) {
                  return _buildAssignmentCard(filteredDevoirs[index]);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final Color subjectColor = _getSubjectColor(assignment['matiere'] ?? 'Autre');
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: subjectColor,
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: subjectColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.assignment,
            size: 28,
            color: subjectColor,
          ),
        ),
        title: Text(
          "${assignment['matiere'] ?? 'Matière'} - ${assignment['subject'] ?? 'Sujet non défini'}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "Classe: ${assignment['classe'] ?? 'Non définie'}",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Date de création:',
                  _formatDate(assignment['timestamp']),
                  Icons.calendar_today,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Matière:',
                  assignment['matiere'] ?? 'Non précisée',
                  Icons.book,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Sujet:',
                  assignment['subject'] ?? 'Sujet non défini',
                  Icons.topic,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Classe:',
                  assignment['classe'] ?? 'Non définie',
                  Icons.class_,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  'Année scolaire:',
                  assignment['anneeScolaire'] ?? 'Non précisée',
                  Icons.school,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Non précisé';
    
    try {
      final DateTime date = timestamp is Timestamp 
          ? timestamp.toDate() 
          : DateTime.parse(timestamp.toString());
      
      return DateFormat('dd/MM/yyyy à HH:mm').format(date);
    } catch (e) {
      return 'Date invalide';
    }
  }

  Color _getSubjectColor(String subject) {
    final Map<String, Color> colors = {
      'Mathématiques': Colors.blue[700]!,
      'Français': Colors.green[700]!,
      'SVT': Colors.orange[700]!,
      'Histoire': Colors.brown[600]!,
      'Physique': Colors.purple[600]!,
      'Anglais': Colors.red[600]!,
      'Géographie': Colors.teal[600]!,
      'Musique': Colors.pink[400]!,
      'Arts': Colors.amber[600]!,
      'Informatique': Colors.indigo[600]!,
    };
    
    return colors[subject] ?? const Color(0xFF4285F4);
  }

  Widget _buildErrorWidget() {
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
              _error ?? 'Une erreur inconnue s\'est produite',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudentInfoAndDevoirs,
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
            'Aucun devoir disponible',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pour la classe: ${_studentInfo?['classe'] ?? _studentInfo?['idClasse'] ?? 'Non définie'}',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadStudentInfoAndDevoirs,
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