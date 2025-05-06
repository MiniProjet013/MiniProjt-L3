import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EvenementScreen extends StatefulWidget {
  @override
  _EvenementScreenState createState() => _EvenementScreenState();
}

class _EvenementScreenState extends State<EvenementScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<DocumentSnapshot> evenements = [];
  String? errorMessage;
  int? selectedEvenementIndex;

  @override
  void initState() {
    super.initState();
    _fetchEvenements();
  }

  Future<void> _fetchEvenements() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('ARCHIVE_EVENEMENTS').get();
      setState(() {
        evenements = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des événements: $e';
        isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return 'Non spécifié';
      }
      
      // Si c'est un Timestamp Firestore
      if (dateValue is Timestamp) {
        DateTime dateTime = dateValue.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      
      // Si c'est déjà une chaîne
      if (dateValue is String) {
        // Si la date est au format UTC comme "6 mai 2025 à 07:05:25 UTC+1"
        if (dateValue.contains('UTC')) {
          return dateValue; // Déjà formaté correctement
        }
        return dateValue;
      }
      
      // Par défaut
      return dateValue.toString();
    } catch (e) {
      return 'Format inconnu';
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
                    colors: [
                      orangeColor.withOpacity(0.8),
                      greenColor.withOpacity(0.8)
                    ],
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
                          'ÉVÉNEMENTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Liste des événements de l\'école',
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
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                      ),
                    ),
                  )
                : errorMessage != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: orangeColor,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: TextStyle(color: darkColor),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _fetchEvenements,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: greenColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Réessayer',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : evenements.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: greenColor,
                                    size: 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucun événement trouvé',
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final evenement = evenements[index].data() as Map<String, dynamic>;
                                final bool isSelected = selectedEvenementIndex == index;
                                return Column(
                                  children: [
                                    _buildEvenementCard(evenement, context, index, isSelected),
                                    if (isSelected)
                                      _buildEvenementDetails(evenement)
                                  ],
                                );
                              },
                              childCount: evenements.length,
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation pour ajouter un nouvel événement
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEvenementCard(Map<String, dynamic> evenement, BuildContext context, int index, bool isSelected) {
    final type = evenement['type'] ?? 'Activité';
    final date = evenement['date'];
    final description = evenement['description'] ?? '';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedEvenementIndex = null;
          } else {
            selectedEvenementIndex = index;
          }
        });
      },
      child: Card(
        margin: EdgeInsets.only(bottom: isSelected ? 0 : 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
            bottomLeft: isSelected ? Radius.circular(0) : Radius.circular(15),
            bottomRight: isSelected ? Radius.circular(0) : Radius.circular(15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la carte avec gradient
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    orangeColor.withOpacity(0.8),
                    greenColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.event,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Événement: $type',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
            
            // Affichage court de la description
            if (!isSelected)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description:',
                      style: TextStyle(
                        color: darkColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: darkColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvenementDetails(Map<String, dynamic> evenement) {
    final type = evenement['type'] ?? 'Activité';
    final date = evenement['date'];
    final dateCreation = evenement['dateCreation'];
    final archivedAt = evenement['archivedAt'];
    final description = evenement['description'] ?? '';
    final originalId = evenement['originalId'] ?? '';
    
    return Card(
      margin: EdgeInsets.only(top: 0, bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Type d\'événement',
              type,
              Icons.category,
              orangeColor,
            ),
            _buildInfoRow(
              'Date de l\'événement',
              _formatDate(date),
              Icons.calendar_today,
              greenColor,
            ),
            _buildInfoRow(
              'Date de création',
              _formatDate(dateCreation),
              Icons.create,
              orangeColor,
            ),
            _buildInfoRow(
              'Date d\'archivage',
              _formatDate(archivedAt),
              Icons.archive,
              greenColor,
            ),
            _buildInfoRow(
              'ID Original',
              originalId,
              Icons.fingerprint,
              orangeColor,
            ),
            Divider(height: 32),
            _buildDescriptionSection(description),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: darkColor.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description,
              size: 18,
              color: orangeColor,
            ),
            SizedBox(width: 8),
            Text(
              'Description de l\'événement',
              style: TextStyle(
                color: orangeColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: orangeColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: orangeColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            description,
            style: TextStyle(
              color: darkColor,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}