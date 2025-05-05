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

  // Couleurs pour correspondre aux autres écrans
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  // Référence à la collection Firestore
  final CollectionReference evenementsCollection = FirebaseFirestore.instance.collection('evenements');

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      initialTime: TimeOfDay.now(),
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
        SnackBar(content: Text("Événement publié avec succès !"), backgroundColor: greenColor),
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

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    Icon? suffixIcon,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
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
              maxLines: maxLines,
              onTap: onTap,
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

  // Widget de menu déroulant personnalisé avec cadre
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
        border: Border.all(
          color: darkColor.withOpacity(0.2),
          width: 1.0,
        ),
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
          // AppBar avec gradient
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
                          'Publier un événement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Nouvel événement",
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
          
          // Contenu du formulaire
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section des informations de l'événement
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
                                Icons.event,
                                color: orangeColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Détails de l'événement",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        
                        // Type d'événement
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
                  
                  // Section de la date et l'heure
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
                                Icons.calendar_today,
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
                        
                        // Date de l'événement
                        _buildInputField(
                          controller: dateController,
                          label: "📅 Date de l'événement",
                          readOnly: true,
                          suffixIcon: Icon(Icons.calendar_today, color: greenColor),
                          onTap: _selectDate,
                        ),
                        
                        // Heure de l'événement
                        _buildInputField(
                          controller: timeController,
                          label: "🕒 Heure de l'événement",
                          readOnly: true,
                          suffixIcon: Icon(Icons.access_time, color: greenColor),
                          onTap: _selectTime,
                        ),
                      ],
                    ),
                  ),
                  
                  // Section de la description
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
                        
                        // Description de l'événement
                        _buildInputField(
                          controller: descriptionController,
                          label: "Description détaillée",
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton de publication
                  Container(
                    height: 55,
                    margin: EdgeInsets.only(bottom: 30),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _publishEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orangeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "Publier l'événement",
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