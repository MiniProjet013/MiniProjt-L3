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
  
  // Couleurs qui correspondent au thème de ModifierEleveScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

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
          timeController.text = "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: greenColor,
              onPrimary: Colors.white,
              onSurface: darkColor,
            ),
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: greenColor,
              onPrimary: Colors.white,
              onSurface: darkColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _updateEvent() async {
    // Vérifier si tous les champs sont remplis
    if (selectedType == null || selectedDate == null || selectedTime == null || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Veuillez remplir tous les champs."), backgroundColor: Colors.red),
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
        SnackBar(content: Text("✅ Événement mis à jour avec succès !"), backgroundColor: greenColor),
      );

      // Retourner à l'écran précédent avec un résultat
      Navigator.pop(context, true);
    } catch (e) {
      // Gérer les erreurs
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur lors de la mise à jour: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      // Désactiver l'indicateur de chargement
      setState(() {
        isSaving = false;
      });
    }
  }

  // Custom input field avec le style de ModifierEleveScreen
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              maxLines: label == "Description" ? 4 : 1,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffixIcon,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom dropdown field avec le style de ModifierEleveScreen
  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: darkColor.withOpacity(0.7),
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                style: TextStyle(
                  fontSize: 16,
                  color: darkColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 150.0,
            floating: false,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
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
                          'Modifier l\'événement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          selectedType != null ? "Type: $selectedType" : "Détails de l'événement",
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
          
          // Loading indicator or Form content
          isLoading
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
                          "Chargement des données...",
                          style: TextStyle(
                            fontSize: 16,
                            color: darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Event Type Section Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: orangeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.category,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Type d'événement",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Type dropdown
                              _buildDropdownField<String>(
                                label: "Type d'événement",
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
                            ],
                          ),
                        ),
                        
                        // Date and Time Section Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: greenColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.date_range,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Date et heure",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Date input
                              _buildInputField(
                                controller: dateController,
                                label: "Date de l'événement",
                                readOnly: true,
                                suffixIcon: Icon(Icons.calendar_today, color: greenColor),
                                onTap: _selectDate,
                              ),
                              
                              // Time input
                              _buildInputField(
                                controller: timeController,
                                label: "Heure de l'événement",
                                readOnly: true,
                                suffixIcon: Icon(Icons.access_time, color: greenColor),
                                onTap: _selectTime,
                              ),
                            ],
                          ),
                        ),
                        
                        // Description Section Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(20),
                          margin: EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: orangeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.description,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Description input
                              _buildInputField(
                                controller: descriptionController,
                                label: "Description",
                              ),
                            ],
                          ),
                        ),
                        
                        // Save Button
                        Container(
                          height: 55,
                          margin: EdgeInsets.only(bottom: 30),
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _updateEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: orangeColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Sauvegarde en cours...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  "Enregistrer les modifications",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}