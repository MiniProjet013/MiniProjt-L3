import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PublierEvenementScreen extends StatefulWidget {
  @override
  _PublierEvenementScreenState createState() => _PublierEvenementScreenState();
}

class _PublierEvenementScreenState extends State<PublierEvenementScreen> {
  String? selectedType;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  bool isLoading = false;

  final List<String> eventTypes = ["Réunion", "Examen", "Activité", "Autre"];

  // Référence à la collection Firestore
  final CollectionReference evenementsCollection = FirebaseFirestore.instance.collection('evenements');

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _publishEvent() async {
    // Vérifier si tous les champs sont remplis
    if (selectedType == null || selectedDate == null || selectedTime == null || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs."), backgroundColor: Colors.red),
      );
      return;
    }

    // Activer l'indicateur de chargement
    setState(() {
      isLoading = true;
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

      // Créer l'objet à enregistrer dans Firestore
      final Map<String, dynamic> eventData = {
        'type': selectedType,
        'date': Timestamp.fromDate(eventDateTime),
        'description': descriptionController.text,
        'dateCreation': Timestamp.now(),
      };

      // Enregistrer les données dans Firestore
      await evenementsCollection.add(eventData);

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Événement publié avec succès !"), backgroundColor: Colors.green),
      );

      // Réinitialiser le formulaire
      _resetForm();
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la publication: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      // Désactiver l'indicateur de chargement
      setState(() {
        isLoading = false;
      });
    }
  }

  // Méthode pour réinitialiser le formulaire
  void _resetForm() {
    setState(() {
      selectedType = null;
      selectedDate = null;
      selectedTime = null;
      descriptionController.clear();
      dateController.clear();
      timeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Publier un événement"),
      ),
      body: Padding(
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

            // Bouton de publication
            ElevatedButton(
              onPressed: isLoading ? null : _publishEvent,
              child: isLoading 
                ? CircularProgressIndicator() 
                : Text("Publier", style: TextStyle(color: Colors.deepOrangeAccent)),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
            ),
          ],
        ),
      ),
    );
  }
}