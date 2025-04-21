import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModifierEvenementScreen extends StatefulWidget {
  final String eventId; // ID de l'événement à modifier

  ModifierEvenementScreen({required this.eventId});

  @override
  _ModifierEvenementScreenState createState() => _ModifierEvenementScreenState();
}

class _ModifierEvenementScreenState extends State<ModifierEvenementScreen> {
  String? selectedType;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  bool isLoading = true;
  bool isSaving = false;

  final List<String> eventTypes = ["Réunion", "Examen", "Activité", "Autre"];

  // Référence à la collection Firestore
  final CollectionReference evenementsCollection = FirebaseFirestore.instance.collection('evenements');

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  // Charger les données de l'événement existant
  Future<void> _loadEventData() async {
    try {
      final DocumentSnapshot eventDoc = await evenementsCollection.doc(widget.eventId).get();
      
      if (eventDoc.exists) {
        final eventData = eventDoc.data() as Map<String, dynamic>;
        
        // Récupérer la date/heure de l'événement
        final Timestamp timestamp = eventData['date'] as Timestamp;
        final DateTime eventDateTime = timestamp.toDate();
        
        setState(() {
          selectedType = eventData['type'];
          selectedDate = eventDateTime;
          selectedTime = TimeOfDay(hour: eventDateTime.hour, minute: eventDateTime.minute);
          descriptionController.text = eventData['description'];
          dateController.text = "${eventDateTime.day}/${eventDateTime.month}/${eventDateTime.year}";
          timeController.text = "${selectedTime!.hour}:${selectedTime!.minute.toString().padLeft(2, '0')}";
          isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Événement non trouvé!"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement: ${e.toString()}"), backgroundColor: Colors.red),
      );
      setState(() {
        isLoading = false;
      });
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
        dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _updateEvent() async {
    // Vérifier si tous les champs sont remplis
    if (selectedType == null || selectedDate == null || selectedTime == null || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs."), backgroundColor: Colors.red),
      );
      return;
    }

    // Activer l'indicateur de chargement
    setState(() {
      isSaving = true;
    });

    try {
      // Créer un objet DateTime combinant la date et l'heure sélectionnées
      final DateTime eventDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Créer l'objet à mettre à jour dans Firestore
      final Map<String, dynamic> eventData = {
        'type': selectedType,
        'date': Timestamp.fromDate(eventDateTime),
        'description': descriptionController.text,
        'dateModification': Timestamp.now(), // Ajouter une date de modification
      };

      // Mettre à jour l'événement principal
      await evenementsCollection.doc(widget.eventId).update(eventData);

      // Mettre à jour l'événement dans toutes les collections associées
      // Par exemple, si vous avez une collection "usersEvents" qui fait référence aux événements
      final QuerySnapshot userEventsSnapshot = await FirebaseFirestore.instance
          .collection('usersEvents')
          .where('eventId', isEqualTo: widget.eventId)
          .get();
          
      // Mettre à jour en batch pour plus d'efficacité
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      userEventsSnapshot.docs.forEach((doc) {
        batch.update(doc.reference, {
          'eventData': {
            'type': selectedType,
            'date': Timestamp.fromDate(eventDateTime),
            'description': descriptionController.text,
          }
        });
      });
      
      // Exécuter le batch
      if (userEventsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Événement mis à jour avec succès !"), backgroundColor: Colors.green),
      );

      // Retourner à l'écran précédent avec un résultat
      Navigator.pop(context, true);
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      // Désactiver l'indicateur de chargement
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Modifier l'événement"),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView(
              children: [
                // Type d'événement
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: "Type d'événement", border: OutlineInputBorder()),
                  value: selectedType,
                  items: eventTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
                SizedBox(height: 10),

                // Date de l'événement
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "📅 Sélectionner une date",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _selectDate,
                ),
                SizedBox(height: 10),

                // Heure de l'événement
                TextField(
                  controller: timeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "🕒 Sélectionner une heure",
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.access_time),
                  ),
                  onTap: _selectTime,
                ),
                SizedBox(height: 10),

                // Description de l'événement
                TextField(
                  controller: descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Bouton de mise à jour
                ElevatedButton(
                  onPressed: isSaving ? null : _updateEvent,
                  child: isSaving 
                    ? CircularProgressIndicator() 
                    : Text("Mettre à jour", style: TextStyle(color: Colors.deepOrangeAccent)),
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                ),
                
                SizedBox(height: 10),
                
                // Bouton d'annulation
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annuler", style: TextStyle(color: Colors.grey)),
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                ),
              ],
            ),
          ),
    );
  }
}