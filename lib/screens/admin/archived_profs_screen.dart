import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArchiveProfesseursScreen extends StatefulWidget {
  @override
  _ArchiveProfesseursScreenState createState() => _ArchiveProfesseursScreenState();
}

class _ArchiveProfesseursScreenState extends State<ArchiveProfesseursScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<DocumentSnapshot> professeurs = [];
  String? errorMessage;
  DocumentSnapshot? selectedProfesseur;
  String? filterAnneeScolaire;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    // Scroll to top when selecting a professor
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _clearSelection() {
    setState(() {
      selectedProfesseur = null;
    });
  }

  Future<void> _restoreProfesseur(DocumentSnapshot doc) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la restauration'),
        content: Text('Voulez-vous vraiment restaurer ce professeur vers la collection profs? Cette action est réversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: darkColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: greenColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmer', style: TextStyle(color: lightColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final profData = doc.data() as Map<String, dynamic>;
        await _firestore.collection('profs').doc(doc.id).set(profData);
        await doc.reference.delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Professeur restauré avec succès!'),
            backgroundColor: greenColor,
          )
        );
        
        _fetchProfesseurs();
        _clearSelection();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration: $e'),
            backgroundColor: orangeColor,
          )
        );
      }
    }
  }

  Future<void> _deleteProfesseur(DocumentSnapshot doc) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer définitivement ce professeur?'),
            SizedBox(height: 8),
            Text('Cette action est irréversible et toutes les données seront perdues!', 
              style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: darkColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: orangeColor),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: TextStyle(color: lightColor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await doc.reference.delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Professeur supprimé définitivement!'),
            backgroundColor: greenColor,
          )
        );
        
        _fetchProfesseurs();
        _clearSelection();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: orangeColor,
          )
        );
      }
    }
  }

  List<DocumentSnapshot> get _filteredProfesseurs {
    return professeurs.where((doc) {
      final prof = doc.data() as Map<String, dynamic>;
      final nomComplet = '${prof['prenom']} ${prof['nom']}'.toLowerCase();
      final annee = prof['anneeScolaire'] ?? '';
      
      final matchesSearch = nomComplet.contains(searchQuery.toLowerCase());
      final matchesAnnee = filterAnneeScolaire == null || 
                          filterAnneeScolaire!.isEmpty || 
                          annee == filterAnneeScolaire;
      
      return matchesSearch && matchesAnnee;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProfesseurs = _filteredProfesseurs;
    final anneesScolaires = professeurs
        .map((doc) => (doc.data() as Map<String, dynamic>)['anneeScolaire'] as String?)
        .where((annee) => annee != null)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: lightColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
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
                            'ARCHIVE DES PROFESSEURS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestion des professeurs archivés',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Search and Filter Section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[100],
                      hintText: 'Rechercher par nom...',
                      prefixIcon: Icon(Icons.search, color: darkColor.withOpacity(0.6)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        SizedBox(width: 8),
                        ChoiceChip(
                          label: Text('Toutes les années'),
                          selected: filterAnneeScolaire == null,
                          onSelected: (_) {
                            setState(() {
                              filterAnneeScolaire = null;
                            });
                          },
                          selectedColor: greenColor,
                          labelStyle: TextStyle(
                            color: filterAnneeScolaire == null ? lightColor : darkColor,
                          ),
                        ),
                        ...anneesScolaires.map((annee) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: ChoiceChip(
                              label: Text(annee!),
                              selected: filterAnneeScolaire == annee,
                              onSelected: (_) {
                                setState(() {
                                  filterAnneeScolaire = annee;
                                });
                              },
                              selectedColor: greenColor,
                              labelStyle: TextStyle(
                                color: filterAnneeScolaire == annee ? lightColor : darkColor,
                              ),
                            ),
                          );
                        }).toList(),
                        SizedBox(width: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            // Professeurs List
            Expanded(
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                      ),
                    )
                  : errorMessage != null
                      ? Center(
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
                        )
                      : filteredProfesseurs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
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
                                  SizedBox(height: 8),
                                  if (searchQuery.isNotEmpty || filterAnneeScolaire != null)
                                    Text(
                                      'Essayez de modifier vos critères de recherche',
                                      style: TextStyle(
                                        color: darkColor.withOpacity(0.6),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : selectedProfesseur != null
                              ? SingleChildScrollView(
                                  padding: EdgeInsets.all(16),
                                  child: _buildProfesseurDetailCard(selectedProfesseur!, context),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: filteredProfesseurs.length,
                                  itemBuilder: (context, index) {
                                    final professeur = filteredProfesseurs[index];
                                    final profData = professeur.data() as Map<String, dynamic>;
                                    return _buildProfesseurCard(professeur, profData, context);
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfesseurCard(DocumentSnapshot doc, Map<String, dynamic> professeur, BuildContext context) {
    final nom = professeur['nom'] ?? 'Non spécifié';
    final prenom = professeur['prenom'] ?? 'Non spécifié';
    final matiere = professeur['matiere'] ?? 'Non spécifiée';
    final anneeScolaire = professeur['anneeScolaire'] ?? 'Non spécifiée';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectProfesseur(doc),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      orangeColor.withOpacity(0.7),
                      greenColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
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
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: greenColor),
                        SizedBox(width: 4),
                        Text(
                          anneeScolaire,
                          style: TextStyle(
                            color: greenColor,
                            fontSize: 13,
                          ),
                        ),
                      ],
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

  Widget _buildProfesseurDetailCard(DocumentSnapshot doc, BuildContext context) {
  final professeur = doc.data() as Map<String, dynamic>;
  final nom = professeur['nom'] ?? 'Non spécifié';
  final prenom = professeur['prenom'] ?? 'Non spécifié';
  final matiere = professeur['matiere'] ?? 'Non spécifiée';
  final email = professeur['email'] ?? 'Non spécifié';
  final idProf = professeur['idProf'] ?? 'Non spécifié';
  final anneeScolaire = professeur['anneeScolaire'] ?? 'Non spécifiée';
  final classeId = professeur['classeId'] ?? 'Non spécifié';
  final niveauClasse = professeur['niveauClasse']?.toString() ?? 'Non spécifié';
  final numeroClasse = professeur['numeroClasse'] ?? 'Non spécifié';
  final uid = professeur['uid'] ?? 'Non spécifié';
  final archiveDate = professeur['archiveDate'] ?? 'Non spécifiée';
  final originalId = professeur['originalId'] ?? 'Non spécifié';

  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 0.8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
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
                          Icons.school,
                          color: Colors.white,
                          size: 24,
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
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Professeur de $matiere',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
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
                    Divider(height: 24),
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
        ),
        
        // Boutons d'actions - تم تعديلها لتجنب الـ overflow
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // حساب عرض الشاشة لتحديد تخطيط الأزرار
              if (constraints.maxWidth > 400) {
                // للشاشات الكبيرة - أزرار في صف واحد
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionButton(
                      icon: Icons.arrow_back,
                      label: 'Retour',
                      color: darkColor,
                      onPressed: _clearSelection,
                      isOutlined: true,
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.restore,
                      label: 'Restaurer',
                      color: greenColor,
                      onPressed: () => _restoreProfesseur(doc),
                    ),
                    SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete_forever,
                      label: 'Supprimer',
                      color: orangeColor,
                      onPressed: () => _deleteProfesseur(doc),
                    ),
                  ],
                );
              } else {
                // للشاشات الصغيرة - أزرار في عمود
                return Column(
                  children: [
                    _buildActionButton(
                      icon: Icons.restore,
                      label: 'Restaurer',
                      color: greenColor,
                      onPressed: () => _restoreProfesseur(doc),
                    ),
                    SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.delete_forever,
                      label: 'Supprimer',
                      color: orangeColor,
                      onPressed: () => _deleteProfesseur(doc),
                    ),
                    SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.arrow_back,
                      label: 'Retour à la liste',
                      color: darkColor,
                      onPressed: _clearSelection,
                      isOutlined: true,
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ],
    ),
  );
}

// دالة مساعدة لإنشاء أزرار متسقة
Widget _buildActionButton({
  required IconData icon,
  required String label,
  required Color color,
  required VoidCallback onPressed,
  bool isOutlined = false,
}) {
  return SizedBox(
    width: double.infinity, // تأخذ العرض الكامل
    child: isOutlined
        ? OutlinedButton.icon(
            icon: Icon(icon, size: 20, color: color),
            label: Text(label, style: TextStyle(color: color)),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: color),
            ),
            onPressed: onPressed,
          )
        : ElevatedButton.icon(
            icon: Icon(icon, size: 20, color: Colors.white),
            label: Text(label, style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onPressed,
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