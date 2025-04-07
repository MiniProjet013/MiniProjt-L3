import 'package:flutter/material.dart';

class PublierEvenementScreen extends StatefulWidget {
  @override
  _PublierEvenementScreenState createState() => _PublierEvenementScreenState();
}

class _PublierEvenementScreenState extends State<PublierEvenementScreen> {
  String? selectedType;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dateController = TextEditingController(); // ✅ إضافة متحكم للنص
  final TextEditingController timeController = TextEditingController();

  final List<String> eventTypes = ["Réunion", "Examen", "Activité", "Autre"];

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
        dateController.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}"; // ✅ تنسيق التاريخ وعرضه في الخانة
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
        timeController.text = pickedTime.format(context); // ✅ عرض التوقيت في الخانة
      });
    }
  }

  void _publishEvent() {
    if (selectedType == null || selectedDate == null || selectedTime == null || descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez remplir tous les champs."), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Événement publié avec succès !"), backgroundColor: Colors.green),
      );
      // 🚀 هنا يمكنك إرسال البيانات إلى قاعدة بيانات أو API
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("Publier un événement")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // ✅ اختيار نوع الحدث
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

            // ✅ اختيار تاريخ الحدث
            TextField(
              controller: dateController, // ✅ التحكم في النص
              readOnly: true,
              decoration: InputDecoration(
                labelText: "📅 Sélectionner une date",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _selectDate,
            ),
            SizedBox(height: 10),

            // ✅ اختيار توقيت الحدث
            TextField(
              controller: timeController, // ✅ التحكم في النص
              readOnly: true,
              decoration: InputDecoration(
                labelText: "🕒 Sélectionner une heure",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time),
              ),
              onTap: _selectTime,
            ),
            SizedBox(height: 10),

            // ✅ وصف الحدث
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // ✅ زر النشر
            ElevatedButton(
              onPressed: _publishEvent,
              child: Text("Publier",style:TextStyle(color: Colors.deepOrangeAccent),),
              style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
