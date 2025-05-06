import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfesseursScreen extends StatefulWidget {
  @override
  _ProfesseursScreenState createState() => _ProfesseursScreenState();
}

class _ProfesseursScreenState extends State<ProfesseursScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<DocumentSnapshot> professeurs = [];
  String? errorMessage;
  DocumentSnapshot? selectedProfesseur;

  @override
  void initState() {
    super.initState();
    _fetchProfesseurs();
  }

  Future<void> _fetchProfesseurs() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('ARCHIVE_PROFS').get();
      setState(() {
        professeurs = snapshot.docs;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des professeurs: $e';
        isLoading = false;
      });
    }
  }

  void _selectProfesseur(DocumentSnapshot prof) {
    setState(() {
      selectedProfesseur = prof;
    });
  }

  void _clearSelection() {
    setState(() {
      selectedProfesseur = null;
    });
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
                          'PROFESSEURS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Liste des professeurs de l\'établissement',
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
                                onPressed: _fetchProfesseurs,
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
                    : professeurs.isEmpty
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
                                    'Aucun professeur trouvé',
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
                        : selectedProfesseur != null
                            ? SliverList(
                                delegate: SliverChildListDelegate([
                                  _buildProfesseurDetailCard(selectedProfesseur!.data() as Map<String, dynamic>, context),
                                  SizedBox(height: 16),
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: _clearSelection,
                                      icon: Icon(Icons.arrow_back, color: Colors.white),
                                      label: Text('Retour à la liste', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: greenColor,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ]),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final professeur = professeurs[index];
                                    final profData = professeur.data() as Map<String, dynamic>;
                                    return _buildProfesseurCard(professeur, profData, context);
                                  },
                                  childCount: professeurs.length,
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation pour ajouter un nouveau professeur
          // Vous pouvez implémenter cette fonctionnalité si nécessaire
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un professeur',
      ),
    );
  }

  Widget _buildProfesseurCard(DocumentSnapshot doc, Map<String, dynamic> professeur, BuildContext context) {
    final nom = professeur['nom'] ?? 'Non spécifié';
    final prenom = professeur['prenom'] ?? 'Non spécifié';
    final matiere = professeur['matiere'] ?? 'Non spécifiée';
    final email = professeur['email'] ?? 'Non spécifié';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _selectProfesseur(doc),
        splashColor: orangeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      orangeColor.withOpacity(0.7),
                      greenColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$prenom $nom',
                      style: TextStyle(
                        color: darkColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Matière: $matiere',
                      style: TextStyle(
                        color: darkColor.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: darkColor.withOpacity(0.5),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: greenColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfesseurDetailCard(Map<String, dynamic> professeur, BuildContext context) {
    final nom = professeur['nom'] ?? 'Non spécifié';
    final prenom = professeur['prenom'] ?? 'Non spécifié';
    final matiere = professeur['matiere'] ?? 'Non spécifiée';
    final email = professeur['email'] ?? 'Non spécifié';
    final idProf = professeur['idProf'] ?? 'Non spécifié';
    final anneeScolaire = professeur['anneeScolaire'] ?? 'Non spécifiée';
    final classeId = professeur['classeId'] ?? 'Non spécifié';
    final niveauClasse = professeur['niveauClasse'] != null ? 
        professeur['niveauClasse'].toString() : 'Non spécifié';
    final numeroClasse = professeur['numeroClasse'] ?? 'Non spécifié';
    final uid = professeur['uid'] ?? 'Non spécifié';
    final archiveDate = professeur['archiveDate'] ?? 'Non spécifiée';
    final originalId = professeur['originalId'] ?? 'Non spécifié';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte avec gradient
          Container(
            height: 100,
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
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$prenom $nom',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Professeur de $matiere',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu des détails du professeur
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'ID Professeur',
                  idProf,
                  Icons.badge,
                  orangeColor,
                ),
                _buildInfoRow(
                  'Email',
                  email,
                  Icons.email,
                  greenColor,
                ),
                _buildInfoRow(
                  'Année Scolaire',
                  anneeScolaire,
                  Icons.calendar_today,
                  orangeColor,
                ),
                _buildClasseSection(classeId, niveauClasse, numeroClasse),
                Divider(height: 32),
                _buildInfoRow(
                  'Date d\'archivage',
                  archiveDate,
                  Icons.access_time,
                  greenColor,
                ),
                _buildInfoRow(
                  'ID Original',
                  originalId,
                  Icons.fingerprint,
                  orangeColor,
                ),
                _buildInfoRow(
                  'UID',
                  uid,
                  Icons.vpn_key,
                  greenColor,
                ),
              ],
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
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 15,
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

  Widget _buildClasseSection(String classeId, String niveauClasse, String numeroClasse) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.class_,
              size: 18,
              color: orangeColor,
            ),
            SizedBox(width: 8),
            Text(
              'Informations de classe',
              style: TextStyle(
                color: orangeColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClasseInfoRow('ID de classe', classeId),
              SizedBox(height: 8),
              _buildClasseInfoRow('Niveau', niveauClasse),
              SizedBox(height: 8),
              _buildClasseInfoRow('Numéro', numeroClasse),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClasseInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: darkColor.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: darkColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}