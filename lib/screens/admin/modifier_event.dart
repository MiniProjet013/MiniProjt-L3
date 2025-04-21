import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'modifier_evenement_screen.dart'; // Import de l'écran de modification d'un événement spécifique

class ModifierEvenementsScreen extends StatefulWidget {
  @override
  _ModifierEvenementsScreenState createState() => _ModifierEvenementsScreenState();
}

class _ModifierEvenementsScreenState extends State<ModifierEvenementsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = false;
  List<Map<String, dynamic>> evenements = [];
  List<Map<String, dynamic>> filteredEvenements = [];
  TextEditingController searchController = TextEditingController();
  String? selectedType;
  DateTime? selectedDate;

  final List<String> eventTypes = ["Tous", "Réunion", "Examen", "Activité", "Autre"];

  @override
  void initState() {
    super.initState();
    selectedType = "Tous";
    _loadEvenements();
    searchController.addListener(_filterEvenements);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        _filterEvenements();
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

  void _filterEvenements() {
    String query = searchController.text.toLowerCase();

    setState(() {
      filteredEvenements = evenements.where((evenement) {
        return evenement["description"].toLowerCase().contains(query) ||
            evenement["type"].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Formater la date pour l'affichage
  String _formatDate(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
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
        _filterByDate();
      });
    }
  }

  void _filterByDate() {
    if (selectedDate == null) return;

    setState(() {
      filteredEvenements = evenements.where((evenement) {
        DateTime eventDate = evenement["date"].toDate();
        return eventDate.year == selectedDate!.year && 
               eventDate.month == selectedDate!.month && 
               eventDate.day == selectedDate!.day;
      }).toList();
    });
  }

  void _resetDateFilter() {
    setState(() {
      selectedDate = null;
      _filterEvenements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Modifier Événements"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Rechercher",
                    hintText: "Type, description...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("Type d'événement: ", 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: eventTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedType = value;
                          });
                          _loadEvenements();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Text("Filtrer par date: ", 
                      style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.calendar_today),
                        label: Text(selectedDate == null 
                          ? "Sélectionner une date" 
                          : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
                        onPressed: _selectDate,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (selectedDate != null)
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _resetDateFilter,
                        tooltip: "Effacer le filtre de date",
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : filteredEvenements.isEmpty
                    ? Center(
                        child: Text(
                          "Aucun événement trouvé",
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredEvenements.length,
                        itemBuilder: (context, index) {
                          final evenement = filteredEvenements[index];
                          final eventDate = _formatDate(evenement["date"]);
                          final eventColor = _getColorForEventType(evenement["type"]);
                          
                          return Card(
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: eventColor,
                                child: Icon(
                                  evenement["type"] == "Réunion" ? Icons.people :
                                  evenement["type"] == "Examen" ? Icons.assignment :
                                  evenement["type"] == "Activité" ? Icons.event :
                                  Icons.event_note,
                                  color: Colors.white
                                ),
                              ),
                              title: Text(
                                evenement["type"],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Date: $eventDate"),
                                  Text(
                                    evenement["description"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  evenement["dateModification"] != null
                                      ? Text(
                                          "Modifié le: ${_formatDate(evenement["dateModification"])}",
                                          style: TextStyle(fontSize: 11, color: Colors.grey),
                                        )
                                      : SizedBox(),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
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
                                  
                                  // Si les données ont été mises à jour, on recharge la liste
                                  if (result == true) {
                                    _loadEvenements();
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}