import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:study/screens/admin/convocationdetailsscreen.dart';
//import 'package:intl/intl.dart';

class ConvocationScreen extends StatefulWidget {
  @override
  _ConvocationScreenState createState() => _ConvocationScreenState();
}

class _ConvocationScreenState extends State<ConvocationScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<DocumentSnapshot> convocations = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchConvocations();
  }

  Future<void> _fetchConvocations() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('remarques').get();
      setState(() {
        convocations = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des convocations: $e';
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      // Format d'entrée "dd/MM/yyyy"
      final parts = dateString.split('/');
      if (parts.length != 3) return dateString;
      
      final formattedDate = '${parts[0]}/${parts[1]}/${parts[2]}';
      return formattedDate;
    } catch (e) {
      return dateString;
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
                          'CONVOCATIONS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Liste des convocations des élèves',
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
                                onPressed: _fetchConvocations,
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
                    : convocations.isEmpty
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
                                    'Aucune convocation trouvée',
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
                                final convocation = convocations[index].data() as Map<String, dynamic>;
                                return _buildConvocationCard(convocation, context);
                              },
                              childCount: convocations.length,
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation pour ajouter une nouvelle convocation
          // Vous pouvez implémenter cette fonctionnalité si nécessaire
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildConvocationCard(Map<String, dynamic> convocation, BuildContext context) {
    final anneeScolaire = convocation['anneeScolaire'] ?? '';
    final classeId = convocation['classeId'] ?? '';
    final classeNiveaux = convocation['classeNiveaux'] ?? '';
    final classeNumero = convocation['classeNumero'] ?? '';
    final date = convocation['date'] ?? '';
    final eleveId = convocation['eleveId'] ?? '';
    final eleveNom = convocation['eleveNom'] ?? '';
    final remarque = convocation['remarque'] ?? '';
    final timestamp = convocation['timestamp'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
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
                      Icons.notification_important,
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
                          'Convocation: $eleveNom',
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
                ],
              ),
            ),
          ),
          
          // Contenu de la convocation
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Année Scolaire',
                  anneeScolaire,
                  Icons.calendar_today,
                  orangeColor,
                ),
                _buildInfoRow(
                  'Classe',
                  'ID: $classeId - $classeNiveaux (Numéro: $classeNumero)',
                  Icons.class_,
                  greenColor,
                ),
                _buildInfoRow(
                  'Élève',
                  'ID: $eleveId - $eleveNom',
                  Icons.person,
                  orangeColor,
                ),
                Divider(height: 32),
                _buildRemarkSection(remarque),
                Divider(height: 32),
                Text(
                  'Enregistré le: $timestamp',
                  style: TextStyle(
                    color: darkColor.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Boutons d'actions
        ],
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

  Widget _buildRemarkSection(String remark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.comment,
              size: 18,
              color: orangeColor,
            ),
            SizedBox(width: 8),
            Text(
              'convocation',
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
            remark,
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