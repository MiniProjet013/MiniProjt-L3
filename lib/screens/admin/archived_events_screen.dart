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
  final TextEditingController _searchController = TextEditingController();
  
  bool isLoading = true;
  bool isSearchVisible = false;
  List<DocumentSnapshot> evenements = [];
  List<DocumentSnapshot> filteredEvenements = [];
  String? errorMessage;
  int? selectedEvenementIndex;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEvenements();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = _searchController.text;
      _filterEvenements();
    });
  }

  void _filterEvenements() {
    if (searchQuery.isEmpty) {
      filteredEvenements = List.from(evenements);
    } else {
      filteredEvenements = evenements.where((doc) {
        final evenement = doc.data() as Map<String, dynamic>;
        final type = (evenement['type'] ?? '').toString().toLowerCase();
        final description = (evenement['description'] ?? '').toString().toLowerCase();
        final date = _formatDate(evenement['date']).toLowerCase();
        final query = searchQuery.toLowerCase();
        
        return type.contains(query) || 
               description.contains(query) || 
               date.contains(query);
      }).toList();
    }
    selectedEvenementIndex = null; // Reset selection when filtering
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
        _filterEvenements();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des événements: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteEvenement(DocumentSnapshot evenementDoc) async {
    try {
      await evenementDoc.reference.delete();
      
      setState(() {
        evenements.removeWhere((doc) => doc.id == evenementDoc.id);
        _filterEvenements();
        selectedEvenementIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Événement supprimé définitivement'),
          backgroundColor: greenColor,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(DocumentSnapshot evenementDoc) async {
    final evenement = evenementDoc.data() as Map<String, dynamic>;
    final type = evenement['type'] ?? 'Activité';
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Confirmer ',
                style: TextStyle(
                  color: darkColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Êtes-vous sûr de vouloir supprimer définitivement cet événement ?',
                style: TextStyle(color: darkColor),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Événement: $type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                      ),
                    ),
                    Text(
                      'Date: ${_formatDate(evenement['date'])}',
                      style: TextStyle(color: darkColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text(
                '⚠️ Cette action est irréversible !',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(color: greenColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Supprimer',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvenement(evenementDoc);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(dynamic dateValue) {
    try {
      if (dateValue == null) {
        return 'Non spécifié';
      }
      
      if (dateValue is Timestamp) {
        DateTime dateTime = dateValue.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
      
      if (dateValue is String) {
        if (dateValue.contains('UTC')) {
          return dateValue;
        }
        return dateValue;
      }
      
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
            expandedHeight: isSearchVisible ? 200.0 : 150.0,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    'Liste des événements archivés (${filteredEvenements.length})',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isSearchVisible = !isSearchVisible;
                                  if (!isSearchVisible) {
                                    _searchController.clear();
                                    searchQuery = '';
                                    _filterEvenements();
                                  }
                                });
                              },
                              icon: Icon(
                                isSearchVisible ? Icons.close : Icons.search,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        if (isSearchVisible) ...[
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Rechercher par type, description ou date...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                suffixIcon: searchQuery.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                        },
                                        icon: Icon(
                                          Icons.clear,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                    : filteredEvenements.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    searchQuery.isNotEmpty 
                                        ? Icons.search_off 
                                        : Icons.info_outline,
                                    color: greenColor,
                                    size: 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    searchQuery.isNotEmpty
                                        ? 'Aucun résultat pour "$searchQuery"'
                                        : 'Aucun événement trouvé',
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (searchQuery.isNotEmpty) ...[
                                    SizedBox(height: 12),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                      child: Text(
                                        'Effacer la recherche',
                                        style: TextStyle(color: orangeColor),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final evenementDoc = filteredEvenements[index];
                                final evenement = evenementDoc.data() as Map<String, dynamic>;
                                final bool isSelected = selectedEvenementIndex == index;
                                return Column(
                                  children: [
                                    _buildEvenementCard(evenement, evenementDoc, context, index, isSelected),
                                    if (isSelected)
                                      _buildEvenementDetails(evenement, evenementDoc)
                                  ],
                                );
                              },
                              childCount: filteredEvenements.length,
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

  Widget _buildEvenementCard(Map<String, dynamic> evenement, DocumentSnapshot evenementDoc, BuildContext context, int index, bool isSelected) {
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
                    // Bouton de suppression
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(evenementDoc),
                      icon: Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Supprimer définitivement',
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

  Widget _buildEvenementDetails(Map<String, dynamic> evenement, DocumentSnapshot evenementDoc) {
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
            // Bouton de suppression en haut des détails
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showDeleteConfirmation(evenementDoc),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(Icons.delete_forever, color: Colors.white),
                label: Text(
                  'Supprimer définitivement',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
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