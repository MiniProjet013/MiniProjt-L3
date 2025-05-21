import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final CollectionReference devoirsCollection = FirebaseFirestore.instance.collection('devoir');
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Simuler un chargement initial
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isLoading = false;
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
                colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
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
                      "DEVOIRS",
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
                          _isLoading = true;
                        });
                        _loadData();
                      },
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
                : _buildHomeworkList(),
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
        itemCount: 5, // Placeholders pour les devoirs
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
                        SizedBox(height: 8),
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

  Widget _buildHomeworkList() {
    return StreamBuilder<QuerySnapshot>(
      stream: devoirsCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, 
                     size: 64, 
                     color: Color(0xFF4285F4).withOpacity(0.5)),
                SizedBox(height: 16),
                Text(
                  "Aucun devoir disponible",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          physics: BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var assignment = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return _buildAssignmentCard(assignment);
          },
        );
      },
    );
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final Color subjectColor = _getSubjectColor(assignment['subject'] ?? 'Autre');
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: subjectColor,
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: EdgeInsets.all(8),
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
          "${assignment['subject'] ?? 'Matière'} - ${assignment['nomEleve'] ?? 'Élève'}",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          assignment['task'] ?? 'Tâche non définie',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Date:',
                  _formatDate(assignment['timestamp']),
                  Icons.calendar_today,
                ),
                SizedBox(height: 8),
                _buildDetailRow(
                  'Instructions:',
                  assignment['instructions'] ?? 'Aucune instruction',
                  Icons.info_outline,
                ),
                if (assignment['deadlineDate'] != null) ...[
                  SizedBox(height: 8),
                  _buildDetailRow(
                    'À rendre avant:',
                    _formatDate(assignment['deadlineDate']),
                    Icons.event_available,
                  ),
                ],
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
        SizedBox(width: 8),
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
              SizedBox(height: 4),
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
      
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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
    
    return colors[subject] ?? Color(0xFF4285F4);
  }
}