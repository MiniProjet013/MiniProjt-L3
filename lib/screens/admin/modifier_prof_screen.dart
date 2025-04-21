import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/constants.dart';

class ModifierProfScreen extends StatefulWidget {
  final String idProf; // معرف الأستاذ الذي سيتم تعديل بياناته

  const ModifierProfScreen({Key? key, required this.idProf}) : super(key: key);

  @override
  _ModifierProfScreenState createState() => _ModifierProfScreenState();
}

class _ModifierProfScreenState extends State<ModifierProfScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController idProfController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  List<String> selectedLevels = [];
  List<Map<String, dynamic>> availableClasses = [];
  Map<String, dynamic>? selectedClass;
  bool isLoading = false;
  bool dataLoaded = false;
  String? originalEmail;
  String? oldClassId;
  bool passwordChanged = false;

  final List<String> levels = [
    "1ère année",
    "2ème année",
    "3ème année",
    "4ème année",
    "5ème année",
    "6ème année"
  ];

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
    _loadProfessorData();
  }

  Future<void> _loadProfessorData() async {
    setState(() => isLoading = true);

    try {
      // جلب بيانات الأستاذ من Firestore
      DocumentSnapshot profDoc = 
          await _db.collection('profs').doc(widget.idProf).get();

      if (profDoc.exists) {
        Map<String, dynamic> profData = profDoc.data() as Map<String, dynamic>;
        
        // تعبئة الحقول بالبيانات الحالية
        idProfController.text = profData['idProf'] ?? '';
        nameController.text = profData['nom'] ?? '';
        surnameController.text = profData['prenom'] ?? '';
        emailController.text = profData['email'] ?? '';
        subjectController.text = profData['matiere'] ?? '';
        
        // حفظ البريد الإلكتروني الأصلي ومعرف الفصل للاستخدام لاحقاً
        originalEmail = profData['email'];
        oldClassId = profData['classeId'];
        
        // تعيين السنة الدراسية
        selectedYear = profData['anneeScolaire'];
        
        // استخراج مستوى الصف من البيانات
        if (profData['niveauClasse'] is List) {
          selectedLevels = List<String>.from(profData['niveauClasse']);
        } else if (profData['niveauClasse'] != null) {
          selectedLevels = [profData['niveauClasse'].toString()];
        }
        
        // جلب الفصول المتاحة بناءً على المستويات المحددة
        await _fetchClassesForSelectedLevels();
        
        // اختيار الفصل الحالي للأستاذ
        for (var classe in availableClasses) {
          if (classe['idClasse'] == profData['classeId']) {
            selectedClass = classe;
            break;
          }
        }
        
        setState(() => dataLoaded = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ لم يتم العثور على بيانات الأستاذ!"),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print("❌ خطأ أثناء تحميل البيانات: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ حدث خطأ أثناء تحميل البيانات: $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchClassesForSelectedLevels() async {
    if (selectedLevels.isEmpty || selectedYear == null) {
      setState(() {
        availableClasses = [];
        selectedClass = null;
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await _db
          .collection('classes')
          .where("niveauxEtude", arrayContainsAny: selectedLevels)
          .where("anneeScolaire", isEqualTo: selectedYear)
          .get();

      List<Map<String, dynamic>> classes = snapshot.docs.map((doc) {
        return {
          "idClasse": doc.id,
          "numeroClasse": doc["numeroClasse"],
          "niveau": doc["niveauxEtude"],
        };
      }).toList();

      setState(() {
        availableClasses = classes;
        // الحفاظ على الفصل المحدد إذا كان لا يزال متاحًا
        if (selectedClass != null) {
          bool classStillExists = classes.any((c) => c["idClasse"] == selectedClass!["idClasse"]);
          if (!classStillExists) {
            selectedClass = null;
          }
        }
      });
    } catch (e) {
      print("❌ خطأ في جلب الأقسام: $e");
    }
  }

  Future<void> _updateProfessor() async {
    String idProf = idProfController.text.trim();
    String name = nameController.text.trim();
    String surname = surnameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String subject = subjectController.text.trim();

    if (name.isEmpty ||
        surname.isEmpty ||
        email.isEmpty ||
        subject.isEmpty ||
        selectedLevels.isEmpty ||
        selectedClass == null ||
        selectedYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("⚠️ الرجاء إدخال جميع الحقول المطلوبة!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. تحديث بيانات المستخدم في Firebase Authentication إذا تغير البريد الإلكتروني أو كلمة المرور
      if (email != originalEmail || passwordChanged) {
        // الحصول على معرف المستخدم
        DocumentSnapshot profDoc = await _db.collection('profs').doc(idProf).get();
        String uid = (profDoc.data() as Map<String, dynamic>)['uid'];
        
        // جلب المستخدم الحالي
        User? user = _auth.currentUser;
        
        // إذا كان المستخدم هو نفسه الذي يقوم بالتعديل، نستخدم الجلسة الحالية
        if (user != null && user.uid == uid) {
          if (email != originalEmail) {
            await user.updateEmail(email);
          }
          if (passwordChanged && password.isNotEmpty) {
            await user.updatePassword(password);
          }
        } else {
          // إذا كان مدير يقوم بالتعديل، نستخدم Firebase Admin SDK (مثال)
          // هذا الجزء يتطلب عادة خدمة خلفية أو Cloud Functions
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("⚠️ تغيير البريد الإلكتروني/كلمة المرور يتطلب صلاحيات خاصة"),
            backgroundColor: Colors.orange,
          ));
        }
      }

      // 2. تحديث بيانات الأستاذ في مجموعة profs
      Map<String, dynamic> profData = {
        "nom": name,
        "prenom": surname,
        "email": email,
        "matiere": subject,
        "classeId": selectedClass!["idClasse"],
        "anneeScolaire": selectedYear,
        "numeroClasse": selectedClass!["numeroClasse"],
        "niveauClasse": selectedClass!["niveau"],
      };

      await _db.collection('profs').doc(idProf).update(profData);

      // 3. إذا تغير الفصل، نحتاج لتحديث معلومات الأستاذ في الفصل القديم والجديد
      if (oldClassId != selectedClass!["idClasse"]) {
        // حذف الأستاذ من الفصل القديم
        await _db.collection('classes').doc(oldClassId).update({
          "profs.$idProf": FieldValue.delete()
        });
        
        // إضافة الأستاذ للفصل الجديد
        await _db.collection('classes').doc(selectedClass!["idClasse"]).set({
          "profs": {
            idProf: {
              "nom": name,
              "prenom": surname,
              "matiere": subject,
            }
          }
        }, SetOptions(merge: true));
      } else {
        // تحديث بيانات الأستاذ في نفس الفصل
        await _db.collection('classes').doc(selectedClass!["idClasse"]).update({
          "profs.$idProf": {
            "nom": name,
            "prenom": surname,
            "matiere": subject,
          }
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("✅ تم تحديث بيانات الأستاذ بنجاح!"),
        backgroundColor: Colors.green,
      ));
      
      // العودة إلى الشاشة السابقة بعد التحديث الناجح
      Navigator.pop(context, true);
      
    } catch (e) {
      print("❌ خطأ أثناء تحديث البيانات: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("❌ فشل تحديث بيانات الأستاذ! $e"),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("تعديل بيانات الأستاذ"),
      ),
      body: isLoading && !dataLoaded
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  TextField(
                    controller: idProfController,
                    decoration: InputDecoration(
                      labelText: "رقم تعريف الأستاذ",
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "الاسم",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: surnameController,
                    decoration: InputDecoration(
                      labelText: "اللقب",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: "البريد الإلكتروني",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور (اتركها فارغة إذا لم ترغب بتغييرها)",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        passwordChanged = value.isNotEmpty;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: subjectController,
                    decoration: InputDecoration(
                      labelText: "المادة",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "تحديد السنة الدراسية",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                      _fetchClassesForSelectedLevels();
                    },
                  ),
                  SizedBox(height: 10),
                  Text(
                    "تحديد المستويات الدراسية",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: levels.map((level) {
                      return FilterChip(
                        label: Text(level),
                        selected: selectedLevels.contains(level),
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? selectedLevels.add(level)
                                : selectedLevels.remove(level);
                          });
                          _fetchClassesForSelectedLevels();
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "تحديد رقم الفصل",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  availableClasses.isEmpty
                      ? Text("لا توجد فصول متاحة للمستويات المحددة")
                      : Wrap(
                          spacing: 8.0,
                          children: availableClasses.map((classe) {
                            return ChoiceChip(
                              label: Text("فصل ${classe["numeroClasse"]}"),
                              selected: selectedClass != null &&
                                  selectedClass!["idClasse"] == classe["idClasse"],
                              onSelected: (selected) {
                                setState(() {
                                  selectedClass = selected ? classe : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 20),
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _updateProfessor,
                          child: Text(
                            "حفظ التغييرات",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}