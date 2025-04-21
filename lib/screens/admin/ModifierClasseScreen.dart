import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ModifierClasseScreen extends StatefulWidget {
  final String classId; // معرّف القسم المراد تعديله
  
  ModifierClasseScreen({required this.classId});

  @override
  _ModifierClasseScreenState createState() => _ModifierClasseScreenState();
}

class _ModifierClasseScreenState extends State<ModifierClasseScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  bool isSaving = false;

  final List<String> levels = [
    "1ère année", "2ème année", "3ème année",
    "4ème année", "5ème année", "6ème année"
  ];
  List<String> selectedLevels = [];

  final List<String> schoolYears = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];
  String? selectedYear;

  @override
  void initState() {
    super.initState();
    _loadClassData();
  }

  Future<void> _loadClassData() async {
    try {
      setState(() {
        isLoading = true;
      });

      DocumentSnapshot classDoc = await _db.collection('classes').doc(widget.classId).get();
      
      if (classDoc.exists) {
        Map<String, dynamic> data = classDoc.data() as Map<String, dynamic>;
        
        setState(() {
          idController.text = data['idClasse'] ?? '';
          numberController.text = data['numeroClasse'] ?? '';
          selectedYear = data['anneeScolaire'];
          
          // تحميل المستويات المحددة
          if (data['niveauxEtude'] is List) {
            selectedLevels = List<String>.from(data['niveauxEtude']);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ القسم غير موجود!"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("❌ خطأ أثناء تحميل البيانات: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل تحميل بيانات القسم!"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateClass() async {
    String idClasse = idController.text.trim();
    String numeroClasse = numberController.text.trim();

    if (idClasse.isEmpty || numeroClasse.isEmpty || selectedLevels.isEmpty || selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ الرجاء إدخال جميع الحقول!"), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      // تحديث بيانات القسم في مجموعة classes
      await _db.collection('classes').doc(idClasse).update({
        "numeroClasse": numeroClasse,
        "niveauxEtude": selectedLevels,
        "anneeScolaire": selectedYear,
        "lastUpdated": FieldValue.serverTimestamp(),
      });

      // تحديث جميع الوثائق في المجموعات الأخرى التي تحتوي على مرجع لهذا القسم
      // مثال: تحديث بيانات القسم في مجموعة الطلاب
      await _updateRelatedStudents(idClasse, numeroClasse);
      
      // مثال: تحديث بيانات القسم في مجموعة الجداول الدراسية
      await _updateRelatedSchedules(idClasse, numeroClasse);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ تم تعديل القسم بنجاح!"), backgroundColor: Colors.green),
      );

      // العودة للشاشة السابقة
      Navigator.pop(context, true);

    } catch (e) {
      print("❌ خطأ أثناء التعديل: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ فشل تعديل القسم! حاول مجدداً."), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  // دالة لتحديث بيانات القسم في مجموعة الطلاب
  Future<void> _updateRelatedStudents(String classId, String newClassName) async {
    QuerySnapshot studentsSnapshot = await _db.collection('students')
      .where('idClasse', isEqualTo: classId)
      .get();

    // تحديث كل طالب مرتبط بهذا القسم
    WriteBatch batch = _db.batch();
    for (var doc in studentsSnapshot.docs) {
      batch.update(doc.reference, {
        'numeroClasse': newClassName,
        'anneeScolaire': selectedYear,
      });
    }
    
    if (studentsSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  // دالة لتحديث بيانات القسم في مجموعة الجداول الدراسية
  Future<void> _updateRelatedSchedules(String classId, String newClassName) async {
    QuerySnapshot schedulesSnapshot = await _db.collection('schedules')
      .where('idClasse', isEqualTo: classId)
      .get();

    // تحديث كل جدول دراسي مرتبط بهذا القسم
    WriteBatch batch = _db.batch();
    for (var doc in schedulesSnapshot.docs) {
      batch.update(doc.reference, {
        'nomClasse': newClassName,
        'anneeScolaire': selectedYear,
      });
    }
    
    if (schedulesSnapshot.docs.isNotEmpty) {
      await batch.commit();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(232, 2, 196, 34),
          title: Text("تعديل القسم"),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text("تعديل القسم"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // إدخال معرف القسم (للقراءة فقط)
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: "ID Classe", border: OutlineInputBorder()),
              readOnly: true, // لا يمكن تعديل المعرف
            ),
            SizedBox(height: 10),

            // إدخال رقم القسم
            TextField(
              controller: numberController,
              decoration: InputDecoration(labelText: "Numéro de classe", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),

            // اختيار السنة الدراسية
            Text("Sélectionner l'année scolaire", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              value: selectedYear,
              decoration: InputDecoration(border: OutlineInputBorder()),
              items: schoolYears.map((year) {
                return DropdownMenuItem(
                  value: year,
                  child: Text(year),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedYear = value;
                });
              },
            ),
            SizedBox(height: 10),

            // اختيار المراحل الدراسية
            Text("Sélectionner les niveaux d'étude", style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8.0,
              children: levels.map((level) {
                return FilterChip(
                  label: Text(level),
                  selected: selectedLevels.contains(level),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedLevels.add(level);
                      } else {
                        selectedLevels.remove(level);
                      }
                    });
                  },
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.green.shade100,
                  checkmarkColor: Colors.green,
                );
              }).toList(),
            ),
            SizedBox(height: 20),

            // زر التعديل
            ElevatedButton(
              onPressed: isSaving ? null : _updateClass,
              child: isSaving 
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text("جاري الحفظ...", style: TextStyle(color: Colors.white)),
                    ],
                  )
                : Text("تعديل القسم", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}