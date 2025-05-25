import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AbsencesScreen extends StatefulWidget {
  @override
  _AbsencesScreenState createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  bool isLoading = true;
  List<DocumentSnapshot> absences = [];
  List<DocumentSnapshot> filteredAbsences = [];
  String? errorMessage;
  
  // Filtres
  String selectedClasse = '';
  String selectedMatiere = '';
  String selectedPeriode = '';
  DateTime? selectedDate;
  bool showFilters = false;
  
  // Listes pour les filtres
  Set<String> classes = {};
  Set<String> matieres = {};

  @override
  void initState() {
    super.initState();
    _fetchAbsences();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  Future<void> _fetchAbsences() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final QuerySnapshot snapshot = await _firestore.collection('absences').get();
      setState(() {
        absences = snapshot.docs;
        filteredAbsences = absences;
        _extractFilterOptions();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des absences: $e';
        isLoading = false;
      });
    }
  }

  void _extractFilterOptions() {
    classes.clear();
    matieres.clear();
    
    for (var doc in absences) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['classeId'] != null && data['classeId'].toString().isNotEmpty) {
        classes.add(data['classeId'].toString());
      }
      if (data['matiere'] != null && data['matiere'].toString().isNotEmpty) {
        matieres.add(data['matiere'].toString());
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredAbsences = absences.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Filtre par recherche (nom, prénom, ID élève)
        final searchTerm = _searchController.text.toLowerCase();
        if (searchTerm.isNotEmpty) {
          final nom = (data['nom'] ?? '').toString().toLowerCase();
          final prenom = (data['prenom'] ?? '').toString().toLowerCase();
          final eleveId = (data['eleveId'] ?? '').toString().toLowerCase();
          
          if (!nom.contains(searchTerm) && 
              !prenom.contains(searchTerm) && 
              !eleveId.contains(searchTerm)) {
            return false;
          }
        }
        
        // Filtre par classe
        if (selectedClasse.isNotEmpty && data['classeId'] != selectedClasse) {
          return false;
        }
        
        // Filtre par matière
        if (selectedMatiere.isNotEmpty && data['matiere'] != selectedMatiere) {
          return false;
        }
        
        // Filtre par période (matin/après-midi)
        if (selectedPeriode.isNotEmpty) {
          final heure = data['heure'] ?? '';
          bool isMorning = true;
          try {
            final hourMinute = heure.split(':');
            if (hourMinute.length > 0) {
              final hour = int.tryParse(hourMinute[0]) ?? 8;
              if (hour >= 12) {
                isMorning = false;
              }
            }
          } catch (e) {
            // Garde la valeur par défaut
          }
          
          if (selectedPeriode == 'matin' && !isMorning) return false;
          if (selectedPeriode == 'apres-midi' && isMorning) return false;
        }
        
        // Filtre par date
        if (selectedDate != null) {
          final absenceDate = data['date'] ?? '';
          final selectedDateStr = DateFormat('yyyy-MM-dd').format(selectedDate!);
          if (absenceDate != selectedDateStr) {
            return false;
          }
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      selectedClasse = '';
      selectedMatiere = '';
      selectedPeriode = '';
      selectedDate = null;
      _searchController.clear();
      filteredAbsences = absences;
    });
  }

  String _formatDate(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length != 3) return dateString;
      
      final formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
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
            expandedHeight: 200.0,
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
                          'ABSENCES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Liste des absences des élèves',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              '${filteredAbsences.length} absence(s) trouvée(s)',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            IconButton(
                              onPressed: () => setState(() => showFilters = !showFilters),
                              icon: Icon(
                                showFilters ? Icons.filter_list_off : Icons.filter_list,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Barre de recherche
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, prénom ou ID élève...',
                    prefixIcon: Icon(Icons.search, color: orangeColor),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () => _searchController.clear(),
                            icon: Icon(Icons.clear, color: darkColor.withOpacity(0.5)),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
          
          // Section des filtres
          if (showFilters)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, color: orangeColor),
                        SizedBox(width: 8),
                        Text(
                          'Filtres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: _clearFilters,
                          child: Text(
                            'Effacer tout',
                            style: TextStyle(color: orangeColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Filtre par classe
                    _buildFilterDropdown(
                      'Classe',
                      selectedClasse,
                      [''] + classes.toList(),
                      (value) => setState(() {
                        selectedClasse = value ?? '';
                        _applyFilters();
                      }),
                      Icons.class_,
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Filtre par matière
                    _buildFilterDropdown(
                      'Matière',
                      selectedMatiere,
                      [''] + matieres.toList(),
                      (value) => setState(() {
                        selectedMatiere = value ?? '';
                        _applyFilters();
                      }),
                      Icons.book,
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Filtre par période
                    _buildFilterDropdown(
                      'Période',
                      selectedPeriode,
                      ['', 'matin', 'apres-midi'],
                      (value) => setState(() {
                        selectedPeriode = value ?? '';
                        _applyFilters();
                      }),
                      Icons.access_time,
                      customLabels: {
                        '': 'Toutes les périodes',
                        'matin': 'Matin',
                        'apres-midi': 'Après-midi',
                      },
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Filtre par date
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: greenColor),
                        title: Text(
                          selectedDate != null 
                              ? 'Date: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                              : 'Sélectionner une date',
                          style: TextStyle(color: darkColor),
                        ),
                        trailing: selectedDate != null
                            ? IconButton(
                                onPressed: () => setState(() {
                                  selectedDate = null;
                                  _applyFilters();
                                }),
                                icon: Icon(Icons.clear, color: orangeColor),
                              )
                            : Icon(Icons.arrow_drop_down, color: darkColor),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: orangeColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: darkColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (showFilters) SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Liste des absences
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                                onPressed: _fetchAbsences,
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
                    : filteredAbsences.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    color: greenColor,
                                    size: 60,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    absences.isEmpty 
                                        ? 'Aucune absence trouvée'
                                        : 'Aucune absence ne correspond aux critères de recherche',
                                    style: TextStyle(
                                      color: darkColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (absences.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _clearFilters,
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
                                final absence = filteredAbsences[index].data() as Map<String, dynamic>;
                                return _buildAbsenceCard(absence, context);
                              },
                              childCount: filteredAbsences.length,
                            ),
                          ),
          ),
          
          // Espacement en bas
          //SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
     /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation pour ajouter une nouvelle absence
        },
        backgroundColor: orangeColor,
        child: Icon(Icons.add, color: Colors.white),
      ),*/
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon, {
    Map<String, String>? customLabels,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonFormField<String>(
        value: selectedValue.isEmpty ? null : selectedValue,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: greenColor),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        items: options.map((option) {
          String displayText = option.isEmpty ? 'Tous' : option;
          if (customLabels != null && customLabels.containsKey(option)) {
            displayText = customLabels[option]!;
          }
          return DropdownMenuItem<String>(
            value: option.isEmpty ? null : option,
            child: Text(displayText),
          );
        }).toList(),
        onChanged: onChanged,
        isExpanded: true,
      ),
    );
  }

  Widget _buildAbsenceCard(Map<String, dynamic> absence, BuildContext context) {
    final classeId = absence['classeId'] ?? '';
    final date = absence['date'] ?? '';
    final eleveId = absence['eleveId'] ?? '';
    final heure = absence['heure'] ?? '';
    final matiere = absence['matiere'] ?? '';
    final nom = absence['nom'] ?? '';
    final prenom = absence['prenom'] ?? '';
    final timestamp = absence['timestamp'] ?? '';
    
    // Détermine si c'est une absence du matin ou de l'après-midi basé sur l'heure
    bool isMorning = true;
    try {
      final hourMinute = heure.split(':');
      if (hourMinute.length > 0) {
        final hour = int.tryParse(hourMinute[0]) ?? 8;
        if (hour >= 12) {
          isMorning = false;
        }
      }
    } catch (e) {
      // En cas d'erreur de format, on garde la valeur par défaut (matin)
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec gradient
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isMorning ? orangeColor.withOpacity(0.8) : greenColor.withOpacity(0.8),
                  isMorning ? greenColor.withOpacity(0.5) : orangeColor.withOpacity(0.5),
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
                      isMorning ? Icons.wb_sunny : Icons.nights_stay,
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
                          '$prenom $nom',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatDate(date) + ' - ' + heure,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      matiere,
                      style: TextStyle(
                        color: isMorning ? orangeColor : greenColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenu détaillé
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'ID Élève',
                  eleveId,
                  Icons.person,
                  orangeColor,
                ),
                _buildInfoRow(
                  'Classe',
                  classeId,
                  Icons.class_,
                  greenColor,
                ),
                _buildInfoRow(
                  'Date',
                  _formatDate(date),
                  Icons.calendar_today,
                  orangeColor,
                ),
                _buildInfoRow(
                  'Heure',
                  heure,
                  Icons.access_time,
                  greenColor,
                ),
                _buildInfoRow(
                  'Matière',
                  matiere,
                  Icons.book,
                  orangeColor,
                ),
                Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 16,
                      color: darkColor.withOpacity(0.5),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enregistré le: $timestamp',
                        style: TextStyle(
                          color: darkColor.withOpacity(0.5),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Boutons d'actions
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // Fonction pour justifier l'absence
                  },
                  icon: Icon(Icons.fact_check, color: greenColor),
                  label: Text(
                    'Justifiée',
                    style: TextStyle(color: greenColor),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // Fonction pour notifier les parents
                  },
                  icon: Icon(Icons.notifications_active, color: orangeColor),
                  label: Text(
                    'Notifier',
                    style: TextStyle(color: orangeColor),
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
}