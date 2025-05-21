import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ConvocationScreen extends StatefulWidget {
  const ConvocationScreen({Key? key}) : super(key: key);

  @override
  State<ConvocationScreen> createState() => _ConvocationScreenState();
}

class _ConvocationScreenState extends State<ConvocationScreen> {
  final CollectionReference convocations = FirebaseFirestore.instance.collection('convocation');
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

  // Fonction pour formater la date
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date non précisée';
    
    try {
      DateTime date = timestamp is Timestamp 
          ? timestamp.toDate() 
          : DateTime.parse(timestamp.toString());
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Date invalide';
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
                      "REMARQUES",
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
                : _buildConvocationList(),
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
        itemCount: 5, // Placeholders pour les convocations
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
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
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

  Widget _buildConvocationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: convocations.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, 
                     size: 64, 
                     color: Colors.red.withOpacity(0.6)),
                SizedBox(height: 16),
                Text(
                  "Erreur de chargement des données",
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
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, 
                     size: 64, 
                     color: Color(0xFF4285F4).withOpacity(0.5)),
                SizedBox(height: 16),
                Text(
                  "Aucune remarque disponible",
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
            var doc = snapshot.data!.docs[index];
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return _buildConvocationCard(data);
          },
        );
      },
    );
  }

  Widget _buildConvocationCard(Map<String, dynamic> data) {
    // Déterminer le type/catégorie de la remarque
    final String category = data['type'] ?? 'standard';
    final Color cardColor = _getCategoryColor(category);
    final String teacherName = data['teacherName'] ?? 'Enseignant';
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: cardColor,
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getCategoryIcon(category),
            size: 28,
            color: cardColor,
          ),
        ),
        title: Text(
          data['title'] ?? 'Remarque de $teacherName',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${formatDate(data['timestamp'])}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            if (data['importance'] != null && data['importance'] == 'high')
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Important',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem(
                  'Message:',
                  data['message'] ?? 'Aucun message',
                  Icons.message,
                ),
                SizedBox(height: 12),
                _buildDetailItem(
                  'Classe:',
                  data['className'] ?? data['classId'] ?? 'Non précisé',
                  Icons.class_,
                ),
                if (data['response'] != null) ...[
                  SizedBox(height: 12),
                  _buildDetailItem(
                    'Réponse:',
                    data['response'],
                    Icons.reply,
                  ),
                ],
                SizedBox(height: 16),
                if (data['requiresParentSignature'] == true) 
                  _buildSignatureRequired(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String content, IconData icon) {
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
                content,
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

  Widget _buildSignatureRequired() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber[800]),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Signature des parents requise',
              style: TextStyle(
                color: Colors.amber[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final Map<String, Color> colors = {
      'comportement': Colors.red[700]!,
      'devoir': Colors.blue[700]!,
      'absence': Colors.orange[700]!,
      'félicitation': Colors.green[700]!,
      'standard': Color(0xFF4285F4),
    };
    
    return colors[category.toLowerCase()] ?? Color(0xFF4285F4);
  }

  IconData _getCategoryIcon(String category) {
    final Map<String, IconData> icons = {
      'comportement': Icons.warning,
      'devoir': Icons.assignment,
      'absence': Icons.timer_off,
      'félicitation': Icons.emoji_events,
      'standard': Icons.notifications,
    };
    
    return icons[category.toLowerCase()] ?? Icons.notifications;
  }
}