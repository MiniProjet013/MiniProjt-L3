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
  DocumentSnapshot? selectedEleve;
  String? filterAnneeScolaire;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    });
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _clearSelection() {
    setState(() {
      selectedEleve = null;
    });
  }

  Future<void> _restoreEleve(DocumentSnapshot doc) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la restauration'),
        content: Text('Voulez-vous vraiment restaurer cet élève vers la collection élèves? Cette action est réversible.'),
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
        final eleveData = doc.data() as Map<String, dynamic>;
        await _firestore.collection('ELEVES').doc(doc.id).set(eleveData);
        await doc.reference.delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Élève restauré avec succès!'),
            backgroundColor: greenColor,
          )
        );
        
        _fetchEleves();
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

  Future<void> _deleteEleve(DocumentSnapshot doc) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer définitivement cet élève?'),
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
            content: Text('Élève supprimé définitivement!'),
            backgroundColor: greenColor,
          )
        );
        
        _fetchEleves();
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

  List<DocumentSnapshot> get _filteredEleves {
    return eleves.where((doc) {
      final eleve = doc.data() as Map<String, dynamic>;
      final nomComplet = '${eleve['prenom']} ${eleve['nom']}'.toLowerCase();
      final annee = eleve['anneeScolaire'] ?? '';
      
      final matchesSearch = nomComplet.contains(searchQuery.toLowerCase());
      final matchesAnnee = filterAnneeScolaire == null || 
                          filterAnneeScolaire!.isEmpty || 
                          annee == filterAnneeScolaire;
      
      return matchesSearch && matchesAnnee;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEleves = _filteredEleves;
    final anneesScolaires = eleves
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
                            'ARCHIVE DES ÉLÈVES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestion des élèves archivés',
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
            // Students List
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
                        )
                      : filteredEleves.isEmpty
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
                                    'Aucun élève trouvé',
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
                          : selectedEleve != null
                              ? SingleChildScrollView(
                                  padding: EdgeInsets.all(16),
                                  child: _buildEleveDetailCard(selectedEleve!, context),
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.all(16),
                                  itemCount: filteredEleves.length,
                                  itemBuilder: (context, index) {
                                    final eleve = filteredEleves[index];
                                    final eleveData = eleve.data() as Map<String, dynamic>;
                                    return _buildEleveCard(eleve, eleveData, context);
                                  },
                                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEleveCard(DocumentSnapshot doc, Map<String, dynamic> eleve, BuildContext context) {
    final nom = eleve['nom'] ?? 'Non spécifié';
    final prenom = eleve['prenom'] ?? 'Non spécifié';
    final classe = eleve['classe'] ?? 'Non spécifiée';
    final anneeScolaire = eleve['anneeScolaire'] ?? 'Non spécifiée';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectEleve(doc),
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
                      'Classe: $classe',
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

  Widget _buildEleveDetailCard(DocumentSnapshot doc, BuildContext context) {
    final eleve = doc.data() as Map<String, dynamic>;
    final nom = eleve['nom'] ?? 'Non spécifié';
    final prenom = eleve['prenom'] ?? 'Non spécifié';
    final classe = eleve['classe'] ?? 'Non spécifiée';
    final dateNaissance = eleve['dateNaissance'] ?? 'Non spécifiée';
    final lieuNaissance = eleve['lieuNaissance'] ?? 'Non spécifié';
    final adresse = eleve['adresse'] ?? 'Non spécifié';
    final telephone = eleve['telephone'] ?? 'Non spécifié';
    final email = eleve['email'] ?? 'Non spécifié';
    final anneeScolaire = eleve['anneeScolaire'] ?? 'Non spécifiée';
    final dateInscription = eleve['dateInscription'] ?? 'Non spécifiée';
    final dateSortie = eleve['dateSortie'] ?? 'Non spécifiée';
    final motifSortie = eleve['motifSortie'] ?? 'Non spécifié';
    final nomParent = eleve['nomParent'] ?? 'Non spécifié';
    final telephoneParent = eleve['telephoneParent'] ?? 'Non spécifié';
    final archiveDate = eleve['archiveDate'] ?? 'Non spécifiée';

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
                            Icons.person,
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
                                'Classe: $classe',
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
                        'Date de Naissance',
                        '$dateNaissance à $lieuNaissance',
                        Icons.cake,
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
                      _buildInfoRow(
                        'Année Scolaire',
                        anneeScolaire,
                        Icons.calendar_today,
                        orangeColor,
                      ),
                      Divider(height: 24),
                      _buildInfoRow(
                        'Date d\'Inscription',
                        dateInscription,
                        Icons.date_range,
                        greenColor,
                      ),
                      _buildInfoRow(
                        'Date de Sortie',
                        dateSortie,
                        Icons.exit_to_app,
                        orangeColor,
                      ),
                      _buildRemarkSection('Motif de Sortie', motifSortie),
                      Divider(height: 24),
                      _buildInfoRow(
                        'Parent/Tuteur',
                        nomParent,
                        Icons.family_restroom,
                        greenColor,
                      ),
                      _buildInfoRow(
                        'Téléphone Parent',
                        telephoneParent,
                        Icons.phone_android,
                        orangeColor,
                      ),
                      Divider(height: 24),
                      _buildInfoRow(
                        'Date d\'archivage',
                        archiveDate,
                        Icons.access_time,
                        greenColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 400) {
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
                        onPressed: () => _restoreEleve(doc),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_forever,
                        label: 'Supprimer',
                        color: orangeColor,
                        onPressed: () => _deleteEleve(doc),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.restore,
                        label: 'Restaurer',
                        color: greenColor,
                        onPressed: () => _restoreEleve(doc),
                      ),
                      SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.delete_forever,
                        label: 'Supprimer',
                        color: orangeColor,
                        onPressed: () => _deleteEleve(doc),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
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
          child: Text(
            content,
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