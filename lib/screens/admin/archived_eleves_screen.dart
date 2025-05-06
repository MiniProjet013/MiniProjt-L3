import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchiveElevesScreen extends StatefulWidget {
  @override
  _ArchiveElevesScreenState createState() => _ArchiveElevesScreenState();
}

class _ArchiveElevesScreenState extends State<ArchiveElevesScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<DocumentSnapshot> eleves = [];
  String? errorMessage;
  
  // Pour stocker l'élève sélectionné
  DocumentSnapshot? selectedEleve;
  bool showDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchEleves();
  }

  Future<void> _fetchEleves() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('ARCHIVE_ELEVES').get();
      setState(() {
        eleves = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des élèves: $e';
        isLoading = false;
      });
    }
  }

  void _selectEleve(DocumentSnapshot eleve) {
    setState(() {
      selectedEleve = eleve;
      showDetails = true;
    });
  }

  void _closeDetails() {
    setState(() {
      showDetails = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: Stack(
        children: [
          // Contenu principal
          CustomScrollView(
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
                              'ARCHIVES DES ÉLÈVES',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Liste des anciens élèves de l\'établissement',
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
                                    onPressed: _fetchEleves,
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
                        : eleves.isEmpty
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
                                        'Aucun élève trouvé dans les archives',
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
                                    final eleve = eleves[index].data() as Map<String, dynamic>;
                                    return _buildEleveCard(eleve, context, eleves[index]);
                                  },
                                  childCount: eleves.length,
                                ),
                              ),
              ),
            ],
          ),
          
          // Panneau de détails qui apparaît quand on clique sur un élève
          if (showDetails && selectedEleve != null)
            _buildDetailsPanel(selectedEleve!.data() as Map<String, dynamic>),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fonctionnalité pour ajouter un nouvel élève aux archives
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEleveCard(Map<String, dynamic> eleve, BuildContext context, DocumentSnapshot eleveDoc) {
    final nom = eleve['nom'] ?? '';
    final prenom = eleve['prenom'] ?? '';
    final nomComplet = '$prenom $nom';
    final dateNaissance = eleve['dateNaissance'] ?? '';
    final classe = eleve['classe'] ?? '';
    final anneeScholaire = eleve['anneeScholaire'] ?? '';

    return GestureDetector(
      onTap: () => _selectEleve(eleveDoc),
      child: Card(
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
                    greenColor.withOpacity(0.8),
                    orangeColor.withOpacity(0.8),
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
                        Icons.person,
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
                            nomComplet,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Né(e) le: $dateNaissance',
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
            
            // Contenu de base de l'élève
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Année Scolaire',
                    anneeScholaire,
                    Icons.calendar_today,
                    orangeColor,
                  ),
                  _buildInfoRow(
                    'Classe',
                    classe,
                    Icons.class_,
                    greenColor,
                  ),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _selectEleve(eleveDoc),
                        icon: Icon(Icons.visibility, color: greenColor),
                        label: Text(
                          'Voir les détails',
                          style: TextStyle(color: greenColor),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsPanel(Map<String, dynamic> eleve) {
    final nom = eleve['nom'] ?? '';
    final prenom = eleve['prenom'] ?? '';
    final nomComplet = '$prenom $nom';
    final dateNaissance = eleve['dateNaissance'] ?? '';
    final lieuNaissance = eleve['lieuNaissance'] ?? '';
    final adresse = eleve['adresse'] ?? '';
    final telephone = eleve['telephone'] ?? '';
    final email = eleve['email'] ?? '';
    final classe = eleve['classe'] ?? '';
    final anneeScholaire = eleve['anneeScholaire'] ?? '';
    final dateInscription = eleve['dateInscription'] ?? '';
    final dateSortie = eleve['dateSortie'] ?? '';
    final motifSortie = eleve['motifSortie'] ?? '';
    final nomParent = eleve['nomParent'] ?? '';
    final telephoneParent = eleve['telephoneParent'] ?? '';
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // En-tête
              Container(
                padding: EdgeInsets.all(20),
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
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
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DÉTAILS DE L\'ÉLÈVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            nomComplet,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: _closeDetails,
                    ),
                  ],
                ),
              ),
              
              // Contenu détaillé avec défilement
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Informations Personnelles
                      _buildSectionTitle('Informations Personnelles', Icons.person_outline),
                      _buildInfoRow(
                        'Nom Complet',
                        nomComplet,
                        Icons.person,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Date de Naissance',
                        dateNaissance,
                        Icons.cake,
                        greenColor,
                      ),
                      _buildInfoRow(
                        'Lieu de Naissance',
                        lieuNaissance,
                        Icons.location_on,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Adresse',
                        adresse,
                        Icons.home,
                        greenColor,
                      ),
                      _buildInfoRow(
                        'Téléphone',
                        telephone,
                        Icons.phone,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Email',
                        email,
                        Icons.email,
                        greenColor,
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Section Informations Scolaires
                      _buildSectionTitle('Informations Scolaires', Icons.school),
                      _buildInfoRow(
                        'Classe',
                        classe,
                        Icons.class_,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Année Scolaire',
                        anneeScholaire,
                        Icons.calendar_today,
                        greenColor,
                      ),
                      _buildInfoRow(
                        'Date d\'Inscription',
                        dateInscription,
                        Icons.date_range,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Date de Sortie',
                        dateSortie,
                        Icons.exit_to_app,
                        greenColor,
                      ),
                      _buildRemarkSection('Motif de Sortie', motifSortie),
                      
                      SizedBox(height: 24),
                      
                      // Section Parent/Tuteur
                      _buildSectionTitle('Information Parent/Tuteur', Icons.family_restroom),
                      _buildInfoRow(
                        'Nom du Parent/Tuteur',
                        nomParent,
                        Icons.person_outline,
                        orangeColor,
                      ),
                      _buildInfoRow(
                        'Téléphone du Parent',
                        telephoneParent,
                        Icons.phone,
                        greenColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Boutons d'action en bas
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _closeDetails,
                      icon: Icon(Icons.close, color: darkColor),
                      label: Text('Fermer', style: TextStyle(color: darkColor)),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Action pour imprimer ou exporter les détails
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: greenColor,
                        foregroundColor: Colors.white,
                      ),
                      icon: Icon(Icons.print),
                      label: Text('Imprimer'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: greenColor),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: greenColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Divider(
              indent: 16,
              color: greenColor.withOpacity(0.3),
            ),
          ),
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

  Widget _buildRemarkSection(String title, String content) {
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
              title,
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
            content,
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