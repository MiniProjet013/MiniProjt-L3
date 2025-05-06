import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_evenement_screen.dart';

class ModifierEvenementsScreen extends StatefulWidget {
  @override
  _ModifierEvenementsScreenState createState() => _ModifierEvenementsScreenState();
}

class _ModifierEvenementsScreenState extends State<ModifierEvenementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> evenements = [];
  List<Map<String, dynamic>> filteredEvenements = [];
  String? searchQuery;
  String? selectedType;
  DateTime? selectedDate;
  
  // Colors to match the EleveModifierScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  final List<String> eventTypes = ["Tous", "Réunion", "Examen", "Activité", "Autre"];

  @override
  void initState() {
    super.initState();
    selectedType = "Tous";
    _loadEvenements();
  }

  Future<void> _loadEvenements() async {
    setState(() => isLoading = true);

    try {
      QuerySnapshot querySnapshot;

      if (selectedType == "Tous") {
        querySnapshot = await _db.collection('evenements')
            .orderBy('date', descending: true)
            .get();
      } else {
        querySnapshot = await _db.collection('evenements')
            .where("type", isEqualTo: selectedType)
            .orderBy('date', descending: true)
            .get();
      }

      List<Map<String, dynamic>> loadedEvenements = querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "type": data["type"] ?? "",
          "date": data["date"] as Timestamp,
          "description": data["description"] ?? "",
          "dateCreation": data["dateCreation"] as Timestamp,
          "dateModification": data["dateModification"] as Timestamp?,
        };
      }).toList();

      setState(() {
        evenements = loadedEvenements;
        _applyFilters();
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des événements: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ Échec du chargement des événements"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      filteredEvenements = evenements.where((evenement) {
        bool matchesSearch = true;
        bool matchesDate = true;
        
        // Apply search filter
        if (searchQuery != null && searchQuery!.isNotEmpty) {
          String description = evenement["description"].toString().toLowerCase();
          String type = evenement["type"].toString().toLowerCase();
          String query = searchQuery!.toLowerCase();
          matchesSearch = description.contains(query) || type.contains(query);
        }
        
        // Apply date filter
        if (selectedDate != null) {
          DateTime eventDate = evenement["date"].toDate();
          matchesDate = eventDate.year == selectedDate!.year && 
                        eventDate.month == selectedDate!.month && 
                        eventDate.day == selectedDate!.day;
        }
        
        return matchesSearch && matchesDate;
      }).toList();
    });
  }

  // Formater la date pour l'affichage
  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  // Couleur en fonction du type d'événement
  Color _getColorForEventType(String type) {
    switch (type) {
      case "Réunion": return Colors.blue;
      case "Examen": return Colors.red;
      case "Activité": return Colors.green;
      default: return Colors.orange;
    }
  }

  // Icône en fonction du type d'événement
  IconData _getIconForEventType(String type) {
    switch (type) {
      case "Réunion": return Icons.people;
      case "Examen": return Icons.assignment;
      case "Activité": return Icons.event;
      default: return Icons.event_note;
    }
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        _applyFilters();
      });
    }
  }

  void _resetDateFilter() {
    setState(() {
      selectedDate = null;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar like EleveModifierScreen
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
                    colors: [orangeColor.withOpacity(0.8), greenColor.withOpacity(0.8)],
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
                          'Modifier les événements',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Gérer la liste des événements',
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
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadEvenements,
              ),
            ],
          ),
          
          // Search and Filter Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recherche et filtres",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Rechercher par type ou description",
                        prefixIcon: Icon(Icons.search, color: greenColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text("Type"),
                              value: selectedType,
                              items: eventTypes.map((type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value;
                                });
                                _loadEvenements();
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: _selectDate,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? "Sélectionner une date"
                                        : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                                    style: TextStyle(
                                      color: selectedDate == null ? Colors.grey[600] : darkColor,
                                    ),
                                  ),
                                  Icon(Icons.calendar_today, size: 20, color: greenColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (selectedDate != null)
                        Container(
                          margin: EdgeInsets.only(left: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: orangeColor),
                            onPressed: _resetDateFilter,
                            tooltip: "Effacer la date",
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Events List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
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
                            Icons.event_busy,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Aucun événement trouvé",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: darkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final evenement = filteredEvenements[index];
                        final eventDate = _formatDate(evenement["date"]);
                        final eventColor = _getColorForEventType(evenement["type"]);
                        final eventIcon = _getIconForEventType(evenement["type"]);
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    eventColor.withOpacity(0.2),
                                    eventColor.withOpacity(0.4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                eventIcon,
                                size: 30,
                                color: eventColor,
                              ),
                            ),
                            title: Text(
                              evenement["type"],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: darkColor,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Date: $eventDate",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  evenement["description"],
                                  style: TextStyle(
                                    color: darkColor.withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (evenement["dateModification"] != null)
                                  Text(
                                    "Modifié le: ${_formatDate(evenement["dateModification"])}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ModifierEvenementScreen(
                                            eventId: evenement["id"],
                                          ),
                                        ),
                                      );
                                      
                                      if (result == true) {
                                        _loadEvenements();
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _showDeleteConfirmation(evenement);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filteredEvenements.length,
                    ),
                  ),
          ),
          
          // Bottom padding
          SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: greenColor,
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to add new event screen
          print("Add new event");
        },
      ),
    );
  }
  
  void _showDeleteConfirmation(Map<String, dynamic> evenement) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          "Confirmation",
          style: TextStyle(
            color: darkColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 50,
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Voulez-vous vraiment supprimer cet événement?",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              "\"${evenement["type"]}: ${evenement["description"]}\"",
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Annuler",
              style: TextStyle(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteEvenement(evenement);
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteEvenement(Map<String, dynamic> evenement) async {
  try {
    // 1. Get the event document
    DocumentSnapshot eventDoc = await _db.collection('evenements').doc(evenement["id"]).get();
    
    if (!eventDoc.exists) {
      throw Exception("Event document not found");
    }
    
    // 2. Create archive document with all event data and timestamp
    Map<String, dynamic> archiveData = {
      ...eventDoc.data() as Map<String, dynamic>,
      'archivedAt': FieldValue.serverTimestamp(),
      'originalId': evenement["id"],
      //'deletedBy': _db.doc('users/${_db.app.auth().currentUser?.uid}'), // Optional: track who deleted
    };
    
    // 3. Add to archive collection
    await _db.collection('ARCHIVE_EVENEMENTS').add(archiveData);
    
    // 4. Delete from original collection
    await _db.collection('evenements').doc(evenement["id"]).delete();
    
    // 5. Refresh the list
    _loadEvenements();
    
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("✅ Événement archivé et supprimé avec succès!"),
      backgroundColor: greenColor,
    ));
  } catch (e) {
    print("❌ Error deleting/archiving event: $e");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("❌ Erreur lors de l'archivage/suppression de l'événement!"),
      backgroundColor: Colors.red,
    ));
  }
}
}