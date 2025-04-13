import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:intl/intl.dart';

class EmploiDuTempsScreen extends StatefulWidget {
  @override
  _EmploiDuTempsScreenState createState() => _EmploiDuTempsScreenState();
}

final Color primaryColor = Color.fromARGB(232, 238, 128, 2); // Vert plus foncé
final Color accentColor = Color.fromARGB(
    255, 61, 163, 3); // Orange gardé pour certains accents seulement
final Color backgroundColor = Color(0xFFF5F5F5);

class _EmploiDuTempsScreenState extends State<EmploiDuTempsScreen> {
  // Variables de sélection
  String? selectedAnneeScolaire = '2025-2026';
  List<String> selectedLevels = [];
  List<Map<String, dynamic>> selectedProfs = [];
  List<Map<String, dynamic>> selectedClasses = [];

  // Listes de données
  final List<String> anneesScolaires = [
    "2023-2024",
    "2024-2025",
    "2025-2026",
    "2026-2027",
    "2027-2028"
  ];

  final List<String> levels = [
    "1ère année",
    "2ème année",
    "3ème année",
    "4ème année",
    "5ème année",
    "6ème année"
  ];

  final List<String> jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  List<Map<String, dynamic>> availableProfs = [];
  List<Map<String, dynamic>> availableClasses = [];
  List<Map<String, dynamic>> emploiItems = [];

  // États de chargement
  bool isLoadingProfs = false;
  bool isLoadingClasses = false;
  bool isSaving = false;

  // Contrôleurs de formulaire
  final _formKey = GlobalKey<FormState>();
  TextEditingController _jourController = TextEditingController();
  TimeOfDay? _heureDebut;
  TimeOfDay? _heureFin;
  TextEditingController _matiereController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (selectedAnneeScolaire == null || selectedLevels.isEmpty) {
      setState(() {
        availableProfs = [];
        availableClasses = [];
        selectedProfs = [];
        selectedClasses = [];
      });
      return;
    }

    setState(() {
      isLoadingClasses = true;
    });

    try {
      // Récupérer les classes
      final QuerySnapshot classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where('anneeScolaire', isEqualTo: selectedAnneeScolaire)
          .where('niveauxEtude', arrayContainsAny: selectedLevels)
          .get();

      setState(() {
        availableClasses = classesSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'numero': data['numeroClasse'] ?? '0',
            'niveau': data['niveauxEtude'] is List
                ? (data['niveauxEtude'] as List).join(", ")
                : data['niveauxEtude']?.toString() ?? 'Niveau inconnu',
            'displayText':
                'Classe ${data['numeroClasse']} (${data['niveauxEtude']})',
          };
        }).toList();

        isLoadingClasses = false;
      });
    } catch (e) {
      setState(() {
        isLoadingClasses = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des classes: $e')),
      );
    }
  }

  Future<void> _fetchProfsForSelectedClasses() async {
    if (selectedClasses.isEmpty) {
      setState(() {
        availableProfs = [];
        selectedProfs = [];
      });
      return;
    }

    setState(() {
      isLoadingProfs = true;
    });

    try {
      // Get the IDs of selected classes
      final List<String> selectedClassIds =
          selectedClasses.map((c) => c['id'] as String).toList();

      // First get the classes to find their professors
      final QuerySnapshot classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .where(FieldPath.documentId, whereIn: selectedClassIds)
          .get();

      // Extract professor IDs from these classes
      final List<String> profIds = [];
      for (final doc in classesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['profs'] != null) {
          final profsData = data['profs'] as Map<String, dynamic>;
          profIds.addAll(profsData.keys.toList());
        }
      }

      if (profIds.isEmpty) {
        setState(() {
          availableProfs = [];
          isLoadingProfs = false;
        });
        return;
      }

      // Now get the professors data
      final QuerySnapshot profsSnapshot = await FirebaseFirestore.instance
          .collection('profs')
          .where(FieldPath.documentId, whereIn: profIds)
          .get();

      setState(() {
        availableProfs = profsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'prenom': data['prenom'] ?? 'Prénom inconnu',
            'nom': data['nom'] ?? 'Nom inconnu',
            'matiere': data['matiere'] ?? 'Matière non spécifiée',
            'displayText':
                '${data['prenom']} ${data['nom']} - ${data['matiere']}',
          };
        }).toList();

        isLoadingProfs = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des professeurs: $e");
      setState(() {
        isLoadingProfs = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement des professeurs: $e')),
      );
    }
  }

  void _updateMatiereForSelectedProf() {
    if (selectedProfs.isNotEmpty) {
      final firstProf = selectedProfs.first;
      _matiereController.text = firstProf['matiere'] ?? '';
    } else {
      _matiereController.clear();
    }
  }

  Future<void> _selectHeureDebut() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _heureDebut ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _heureDebut = picked;
      });
    }
  }

  Future<void> _selectHeureFin() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime:
          _heureFin ?? (_heureDebut ?? TimeOfDay.now()).replacing(minute: 30),
    );
    if (picked != null) {
      setState(() {
        _heureFin = picked;
      });
    }
  }

  void _ajouterEmploiItem() {
    if (_formKey.currentState!.validate() &&
        _heureDebut != null &&
        _heureFin != null &&
        selectedProfs.isNotEmpty &&
        selectedClasses.isNotEmpty) {
      setState(() {
        emploiItems.add({
          'jour': _jourController.text,
          'heureDebut': _heureDebut!.format(context),
          'heureFin': _heureFin!.format(context),
          'matiere': _matiereController.text,
          'profs':
              List<Map<String, dynamic>>.from(selectedProfs.map((p) => {...p})),
          'classes': List<Map<String, dynamic>>.from(
              selectedClasses.map((c) => {...c})),
          'timestamp': DateTime.now(),
        });

        // Réinitialiser les champs
        _jourController.clear();
        _heureDebut = null;
        _heureFin = null;
        _matiereController.clear();
        selectedProfs.clear();
      });
    }
  }

  void _supprimerEmploiItem(int index) {
    setState(() {
      emploiItems.removeAt(index);
    });
  }

  Future<void> _saveToFirestore() async {
    if (selectedAnneeScolaire == null ||
        selectedLevels.isEmpty ||
        selectedProfs.isEmpty ||
        selectedClasses.isEmpty ||
        emploiItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Enregistrer pour chaque professeur
      for (final prof in selectedProfs) {
        final docRef = FirebaseFirestore.instance
            .collection('emplois_profs')
            .doc(prof['id']);

        batch.set(
            docRef,
            {
              'anneeScolaire': selectedAnneeScolaire,
              'niveaux': selectedLevels,
              'prof': prof,
              'classes': selectedClasses,
              'emploi': emploiItems,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      // Enregistrer pour chaque classe
      for (final classe in selectedClasses) {
        final docRef = FirebaseFirestore.instance
            .collection('emplois_classes')
            .doc(classe['id']);

        batch.set(
            docRef,
            {
              'anneeScolaire': selectedAnneeScolaire,
              'niveaux': selectedLevels,
              'classe': classe,
              'profs': selectedProfs,
              'emploi': emploiItems,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Emploi du temps enregistré avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _genererPDF() async {
    if (selectedAnneeScolaire == null ||
        selectedLevels.isEmpty ||
        selectedProfs.isEmpty ||
        selectedClasses.isEmpty ||
        emploiItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez sélectionner tous les champs requis')),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Emploi du Temps',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Année scolaire: $selectedAnneeScolaire'),
              pw.Text('Niveaux: ${selectedLevels.join(", ")}'),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Professeurs: ${selectedProfs.map((p) => p['displayText']).join(", ")}'),
              pw.Text(
                  'Classes: ${selectedClasses.map((c) => c['displayText']).join(", ")}'),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Jour', 'Heure', 'Matière', 'Professeurs', 'Classes'],
                  ...emploiItems
                      .map((item) => [
                            item['jour'],
                            '${item['heureDebut']} - ${item['heureFin']}',
                            item['matiere'],
                            (item['profs'] as List<Map<String, dynamic>>)
                                .map((p) => p['displayText'])
                                .join(", "),
                            (item['classes'] as List<Map<String, dynamic>>)
                                .map((c) => c['displayText'])
                                .join(", "),
                          ])
                      .toList(),
                ],
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                style:
                    pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'emploi_du_temps_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emploi du Temps',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: accentColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: Icon(Icons.save, color: Colors.white),
            onPressed: _saveToFirestore,
            tooltip: 'Enregistrer',
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _genererPDF,
            tooltip: 'Générer PDF',
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sélection de l'année scolaire
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Année scolaire',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: DropdownButtonFormField<String>(
                        value: selectedAnneeScolaire,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        items: anneesScolaires.map((annee) {
                          return DropdownMenuItem(
                            value: annee,
                            child: Text(annee),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedAnneeScolaire = value;
                            _fetchData();
                          });
                        },
                        validator: (value) => value == null
                            ? 'Veuillez sélectionner une année'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              // Sélection des niveaux
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Niveaux scolaires',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
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
                                selectedClasses.clear();
                                selectedProfs.clear();
                                _matiereController.clear();
                                _fetchData();
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: primaryColor,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: selectedLevels.contains(level)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: selectedLevels.contains(level)
                                    ? primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Sélection des classes (avec même style)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Classes',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: isLoadingClasses
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: primaryColor))
                          : availableClasses.isEmpty
                              ? Text('Aucune classe disponible')
                              : Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: availableClasses.map((classe) {
                                    bool isSelected = selectedClasses
                                        .any((c) => c['id'] == classe['id']);
                                    return InputChip(
                                      label: Text(classe['displayText']),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedClasses.add(classe);
                                          } else {
                                            selectedClasses.removeWhere(
                                                (c) => c['id'] == classe['id']);
                                          }
                                          _fetchProfsForSelectedClasses();
                                        });
                                      },
                                      backgroundColor: Colors.white,
                                      selectedColor: primaryColor,
                                      checkmarkColor: Colors.white,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                      avatar: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? Colors.white
                                            : Color(0xFFECEFF1),
                                        child: Icon(Icons.school,
                                            size: 18,
                                            color: isSelected
                                                ? primaryColor
                                                : Colors.black54),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                    ),
                  ],
                ),
              ),

              // Sélection des professeurs (avec même style)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Professeurs',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: Icon(Icons.refresh,
                                color: primaryColor, size: 16),
                            label: Text('Charger',
                                style: TextStyle(color: primaryColor)),
                            onPressed: _fetchProfsForSelectedClasses,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: isLoadingProfs
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: primaryColor))
                          : selectedClasses.isEmpty
                              ? Text(
                                  'Veuillez sélectionner des classes d\'abord')
                              : availableProfs.isEmpty
                                  ? Text(
                                      'Aucun professeur trouvé pour ces classes')
                                  : Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: availableProfs.length,
                                        itemBuilder: (context, index) {
                                          final prof = availableProfs[index];
                                          final isSelected = selectedProfs.any(
                                              (p) => p['id'] == prof['id']);
                                          return CheckboxListTile(
                                            title: Text(
                                                '${prof['prenom']} ${prof['nom']}'),
                                            subtitle:
                                                Text('${prof['matiere']}'),
                                            value: isSelected,
                                            onChanged: (bool? selected) {
                                              setState(() {
                                                if (selected == true) {
                                                  selectedProfs.clear();
                                                  selectedProfs.add(prof);
                                                  _updateMatiereForSelectedProf();
                                                } else {
                                                  selectedProfs.removeWhere(
                                                      (p) =>
                                                          p['id'] ==
                                                          prof['id']);
                                                  _matiereController.clear();
                                                }
                                              });
                                            },
                                            activeColor: primaryColor,
                                            checkColor: Colors.white,
                                            tileColor: isSelected
                                                ? primaryColor.withOpacity(0.1)
                                                : null,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(0),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),

              // Formulaire pour ajouter un cours (avec même style)
              Container(
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Ajouter un cours',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _jourController.text.isNotEmpty
                                  ? _jourController.text
                                  : null,
                              decoration: InputDecoration(
                                labelText: 'Jour',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade700),
                              ),
                              items: jours.map((jour) {
                                return DropdownMenuItem(
                                  value: jour,
                                  child: Text(jour),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _jourController.text = value!;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Veuillez sélectionner un jour'
                                  : null,
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectHeureDebut,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Heure de début',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                        ),
                                        labelStyle: TextStyle(
                                            color: Colors.grey.shade700),
                                        suffixIcon: Icon(Icons.access_time,
                                            color: primaryColor),
                                      ),
                                      child: Text(
                                        _heureDebut != null
                                            ? _heureDebut!.format(context)
                                            : 'Sélectionner',
                                        style: TextStyle(
                                          color: _heureDebut != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _selectHeureFin,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Heure de fin',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: primaryColor, width: 2),
                                        ),
                                        labelStyle: TextStyle(
                                            color: Colors.grey.shade700),
                                        suffixIcon: Icon(Icons.access_time,
                                            color: primaryColor),
                                      ),
                                      child: Text(
                                        _heureFin != null
                                            ? _heureFin!.format(context)
                                            : 'Sélectionner',
                                        style: TextStyle(
                                          color: _heureFin != null
                                              ? Colors.black
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _matiereController,
                              decoration: InputDecoration(
                                labelText: 'Matière',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: primaryColor, width: 2),
                                ),
                                labelStyle:
                                    TextStyle(color: Colors.grey.shade700),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              readOnly: true,
                              validator: (value) => value!.isEmpty
                                  ? 'Veuillez sélectionner un professeur pour définir la matière'
                                  : null,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _ajouterEmploiItem,
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Ajouter le cours',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Liste des cours ajoutés (avec même style)
              if (emploiItems.isNotEmpty) ...[
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cours programmés (${emploiItems.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            if (isSaving)
                              CircularProgressIndicator(color: Colors.white)
                            else
                              ElevatedButton(
                                onPressed: _saveToFirestore,
                                child: Text('Enregistrer',
                                    style: TextStyle(color: primaryColor)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: emploiItems.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = emploiItems[index];
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Text(
                                '${item['jour']} - ${item['heureDebut']} à ${item['heureFin']}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 4),
                                  Text('Matière: ${item['matiere']}'),
                                  Text(
                                      'Professeurs: ${(item['profs'] as List<Map<String, dynamic>>).map((p) => "${p['prenom']} ${p['nom']}").join(", ")}'),
                                  Text(
                                      'Classes: ${(item['classes'] as List<Map<String, dynamic>>).map((c) => c['displayText']).join(", ")}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _supprimerEmploiItem(index),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}