import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RemarquesParentScreen extends StatefulWidget {
  final String eleveId;

  const RemarquesParentScreen({super.key, required this.eleveId});

  @override
  State<RemarquesParentScreen> createState() => _RemarquesParentScreenState();
}

class _RemarquesParentScreenState extends State<RemarquesParentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
                      "CONVOCATIONS",
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
                : _buildRemarquesList(),
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
        itemCount: 3, // Placeholders pour les remarques
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
                        child: Container(
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 14,
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildRemarquesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('remarques')
          .where('eleveId', isEqualTo: widget.eleveId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingContent();
        }
        
        if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyWidget();
        }

        // Tri des documents par timestamp (du plus récent au plus ancien)
        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            Timestamp ta = a['timestamp'];
            Timestamp tb = b['timestamp'];
            return tb.compareTo(ta); // Ordre décroissant
          });

        return ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          physics: BouncingScrollPhysics(),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            var data = sortedDocs[index].data() as Map<String, dynamic>;
            return _buildRemarqueCard(data);
          },
        );
      },
    );
  }

  Widget _buildRemarqueCard(Map<String, dynamic> data) {
    DateTime date = _parseDate(data);
    String anneeScolaire = data['anneeScolaire'] ?? 'Non spécifié';
    String classe = data['classeNumero']?.toString() ?? 'Non précisé';
    String nomEleve = data['eleveNom'] ?? 'Nom non spécifié';
    
    // Gestion du niveau scolaire (peut être une liste)
    String niveau = (data['classeNiveaux'] is List && (data['classeNiveaux'] as List).isNotEmpty)
        ? data['classeNiveaux'][0].toString()
        : data['classeNiveaux']?.toString() ?? 'Niveau non spécifié';
    
    // Gestion de la remarque (peut être une chaîne ou une liste)
    String remarque;
    if (data['remarque'] is String) {
      remarque = data['remarque'];
    } else if (data['remarque'] is List) {
      List<dynamic> remarquesList = data['remarque'];
      remarque = remarquesList.map((e) => '• $e').join('\n');
    } else {
      remarque = 'Aucune convocation disponible.';
    }

    // Déterminer le type/sévérité de la remarque
    String type = data['type']?.toString().toLowerCase() ?? 'standard';
    bool isImportant = data['important'] == true || type == 'grave' || type == 'urgent';
        
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        iconColor: _getTypeColor(type),
        collapsedIconColor: Colors.grey,
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getTypeColor(type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getTypeIcon(type),
            size: 26,
            color: _getTypeColor(type),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            if (isImportant)
              Container(
                margin: EdgeInsets.only(left: 8),
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
        subtitle: Text(
          nomEleve,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(
                  'Informations:',
                  [
                    _buildInfoRow('Date complète:', DateFormat('dd/MM/yyyy HH:mm').format(date)),
                    _buildInfoRow('Année scolaire:', anneeScolaire),
                    _buildInfoRow('Niveau:', '$niveau - Classe $classe'),
                  ],
                ),
                SizedBox(height: 16),
                _buildInfoSection(
                  'Convocations:',
                  [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        remarque,
                        style: TextStyle(
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                if (data['action'] != null) ...[
                  SizedBox(height: 16),
                  _buildInfoSection(
                    'Action requise:',
                    [
                      Text(
                        data['action'].toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(type),
                        ),
                      ),
                    ],
                  ),
                ],
                if (data['signature'] == true) ...[
                  SizedBox(height: 16),
                  _buildSignatureRequired(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
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

  DateTime _parseDate(Map<String, dynamic> data) {
    Timestamp? timestamp = data['timestamp'];
    if (timestamp != null) {
      return timestamp.toDate();
    } else {
      return DateTime.now();
    }
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

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, 
               size: 64, 
               color: Color(0xFF4285F4).withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            "Aucune convocation trouvée",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Vous n'avez pas encore reçu de convovation",
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    final Map<String, Color> colors = {
      'standard': Color(0xFF4285F4),
      'information': Colors.blue[600]!,
      'avertissement': Colors.orange[700]!,
      'felicitation': Colors.green[600]!,
      'grave': Colors.red[700]!,
      'urgent': Colors.red[700]!,
    };
    
    return colors[type.toLowerCase()] ?? Color(0xFF4285F4);
  }

  IconData _getTypeIcon(String type) {
    final Map<String, IconData> icons = {
      'standard': Icons.comment,
      'information': Icons.info_outline,
      'avertissement': Icons.warning_amber,
      'felicitation': Icons.emoji_events,
      'grave': Icons.priority_high,
      'urgent': Icons.notification_important,
    };
    
    return icons[type.toLowerCase()] ?? Icons.comment;
  }
}