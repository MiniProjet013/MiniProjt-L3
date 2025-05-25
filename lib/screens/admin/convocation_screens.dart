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
  final TextEditingController _searchController = TextEditingController();
  
  bool isLoading = true;
  bool isSearchVisible = false;
  List<DocumentSnapshot> convocations = [];
  List<DocumentSnapshot> filteredConvocations = [];
  String? errorMessage;
  String selectedFilter = 'Tous'; // Tous, Aujourd'hui, Cette semaine, Ce mois
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchConvocations();
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
      _applyFilters();
    });
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
        filteredConvocations = convocations;
        isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des convocations: $e';
        isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<DocumentSnapshot> tempList = convocations;

    // Filtrage par recherche textuelle
    if (searchQuery.isNotEmpty) {
      tempList = tempList.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final eleveNom = (data['eleveNom'] ?? '').toString().toLowerCase();
        final remarque = (data['remarque'] ?? '').toString().toLowerCase();
        final classeNiveaux = (data['classeNiveaux'] ?? '').toString().toLowerCase();
        final anneeScolaire = (data['anneeScolaire'] ?? '').toString().toLowerCase();
        
        return eleveNom.contains(searchQuery.toLowerCase()) ||
               remarque.contains(searchQuery.toLowerCase()) ||
               classeNiveaux.contains(searchQuery.toLowerCase()) ||
               anneeScolaire.contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Filtrage par date
    if (selectedFilter != 'Tous') {
      final now = DateTime.now();
      tempList = tempList.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final dateString = data['date'] ?? '';
        final docDate = _parseDate(dateString);
        
        if (docDate == null) return false;
        
        switch (selectedFilter) {
          case 'Aujourd\'hui':
            return docDate.year == now.year &&
                   docDate.month == now.month &&
                   docDate.day == now.day;
          case 'Cette semaine':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(Duration(days: 6));
            return docDate.isAfter(weekStart.subtract(Duration(days: 1))) &&
                   docDate.isBefore(weekEnd.add(Duration(days: 1)));
          case 'Ce mois':
            return docDate.year == now.year && docDate.month == now.month;
          default:
            return true;
        }
      }).toList();
    }

    // Trier par date (plus récent en premier)
    tempList.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final dateA = _parseDate(dataA['date'] ?? '');
      final dateB = _parseDate(dataB['date'] ?? '');
      
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      
      return dateB.compareTo(dateA);
    });

    setState(() {
      filteredConvocations = tempList;
    });
  }

  DateTime? _parseDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(String dateString) {
    try {
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
            expandedHeight: isSearchVisible ? 280.0 : 150.0,
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
                              child: Text(
                                'CONVOCATIONS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  isSearchVisible = !isSearchVisible;
                                  if (!isSearchVisible) {
                                    _searchController.clear();
                                    searchQuery = '';
                                    selectedFilter = 'Tous';
                                    _applyFilters();
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
                        SizedBox(height: 8),
                        Text(
                          'Liste des convocations des élèves (${filteredConvocations.length} résultats)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        
                        // Section de recherche et filtres
                        if (isSearchVisible) ...[
                          SizedBox(height: 20),
                          // Barre de recherche
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
                                hintText: 'Rechercher par nom d\'élève, classe, remarque...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Filtres par date
                          Row(
                            children: [
                              Text(
                                'Filtrer par: ',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      'Tous',
                                      'Aujourd\'hui',
                                      'Cette semaine',
                                      'Ce mois',
                                    ].map((filter) => Padding(
                                      padding: EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        label: Text(
                                          filter,
                                          style: TextStyle(
                                            color: selectedFilter == filter
                                                ? orangeColor
                                                : const Color.fromARGB(255, 255, 97, 5).withOpacity(0.9),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        selected: selectedFilter == filter,
                                        onSelected: (selected) {
                                          setState(() {
                                            selectedFilter = filter;
                                            _applyFilters();
                                          });
                                        },
                                        backgroundColor: Colors.white.withOpacity(0.2),
                                        selectedColor: Colors.white.withOpacity(0.9),
                                        checkmarkColor: orangeColor,
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Bouton de rafraîchissement
              IconButton(
                onPressed: _fetchConvocations,
                icon: Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),
          
          SliverPadding(
            padding: EdgeInsets.all(16.0),
            sliver: isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chargement des convocations...',
                            style: TextStyle(
                              color: darkColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
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
                    : filteredConvocations.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    searchQuery.isNotEmpty || selectedFilter != 'Tous'
                                        ? Icons.search_off
                                        : Icons.info_outline,
                                    color: greenColor,
                                    size: 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    searchQuery.isNotEmpty || selectedFilter != 'Tous'
                                        ? 'Aucune convocation trouvée\npour votre recherche'
                                        : 'Aucune convocation trouvée',
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (searchQuery.isNotEmpty || selectedFilter != 'Tous') ...[
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          searchQuery = '';
                                          selectedFilter = 'Tous';
                                          _applyFilters();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: orangeColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Effacer les filtres',
                                        style: TextStyle(color: Colors.white),
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
                                final convocation = filteredConvocations[index].data() as Map<String, dynamic>;
                                return _buildConvocationCard(convocation, context);
                              },
                              childCount: filteredConvocations.length,
                            ),
                          ),
          ),
        ],
      ),
     /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation pour ajouter une nouvelle convocation
          // Vous pouvez implémenter cette fonctionnalité si nécessaire
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),*/
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
              'Convocation',
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