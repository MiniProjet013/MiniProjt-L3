import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';
import 'ModifierClasseScreen.dart'; // Importamos la pantalla de edición individual

class ModifierClassesScreen extends StatefulWidget {
  @override
  _ModifierClassesScreenState createState() => _ModifierClassesScreenState();
}

class _ModifierClassesScreenState extends State<ModifierClassesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> classes = [];
  String? selectedYear;

  // Lista de años escolares disponibles
  final List<String> schoolYears = [
    "Tous", // Opción para mostrar todas las clases
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];

  @override
  void initState() {
    super.initState();
    selectedYear = "Tous"; // Por defecto mostramos todas las clases
    _loadClasses();
  }

  // Cargar las clases desde Firestore
  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot snapshot;
      
      // Filtrar por año escolar si se ha seleccionado uno específico
      if (selectedYear != null && selectedYear != "Tous") {
        snapshot = await _db.collection('classes')
            .where('anneeScolaire', isEqualTo: selectedYear)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        snapshot = await _db.collection('classes')
            .orderBy('timestamp', descending: true)
            .get();
      }

      List<Map<String, dynamic>> loadedClasses = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        loadedClasses.add({
          'id': doc.id,
          'idClasse': data['idClasse'] ?? '',
          'numeroClasse': data['numeroClasse'] ?? '',
          'anneeScolaire': data['anneeScolaire'] ?? '',
          'niveauxEtude': data['niveauxEtude'] is List 
              ? List<String>.from(data['niveauxEtude']) 
              : <String>[],
        });
      }

      setState(() {
        classes = loadedClasses;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error al cargar las clases: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al cargar las clases"), backgroundColor: Colors.red),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Eliminar una clase
  Future<void> _deleteClass(String classId) async {
    try {
      // Verificar si hay estudiantes asociados a esta clase
      QuerySnapshot studentsSnapshot = await _db.collection('students')
          .where('idClasse', isEqualTo: classId)
          .limit(1)
          .get();
      
      if (studentsSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ No se puede eliminar: hay estudiantes asignados a esta clase"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Verificar si hay horarios asociados a esta clase
      QuerySnapshot schedulesSnapshot = await _db.collection('schedules')
          .where('idClasse', isEqualTo: classId)
          .limit(1)
          .get();
      
      if (schedulesSnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⚠️ No se puede eliminar: hay horarios asignados a esta clase"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Si no hay dependencias, eliminar la clase
      await _db.collection('classes').doc(classId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Clase eliminada con éxito"), backgroundColor: Colors.green),
      );
      
      // Recargar la lista
      _loadClasses();
    } catch (e) {
      print("❌ Error al eliminar la clase: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al eliminar la clase"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text("Modifier Classes"),
        actions: [
          // Botón para recargar la lista
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadClasses,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro por año escolar
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: selectedYear,
                  hint: Text("Filtrar por año escolar"),
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
                    _loadClasses();
                  },
                ),
              ),
            ),
          ),
          
          // Lista de clases
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : classes.isEmpty
                    ? Center(child: Text("No hay clases disponibles"))
                    : ListView.builder(
                        itemCount: classes.length,
                        itemBuilder: (context, index) {
                          final classData = classes[index];
                          
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            elevation: 3,
                            child: ListTile(
                              title: Text(
                                "Classe: ${classData['numeroClasse']}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("ID: ${classData['idClasse']}"),
                                  Text("Année: ${classData['anneeScolaire']}"),
                                  Text(
                                    "Niveaux: ${classData['niveauxEtude'].join(', ')}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Botón de editar
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ModifierClasseScreen(
                                            classId: classData['idClasse'],
                                          ),
                                        ),
                                      );
                                      
                                      // Si se editó la clase, recargar la lista
                                      if (result == true) {
                                        _loadClasses();
                                      }
                                    },
                                  ),
                                  
                                  // Botón de eliminar
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      // Mostrar diálogo de confirmación
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Confirmar eliminación"),
                                            content: Text("¿Está seguro de que desea eliminar esta clase?"),
                                            actions: [
                                              TextButton(
                                                child: Text("Cancelar"),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: Text("Eliminar", style: TextStyle(color: Colors.red)),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  _deleteClass(classData['idClasse']);
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
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