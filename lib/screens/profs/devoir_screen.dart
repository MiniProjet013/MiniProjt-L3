import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkScreen extends StatefulWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  bool _isLoadingData = true;
  List<QueryDocumentSnapshot> _homeworks = [];

  // Variables pour stocker les sélections
  String? selectedYear;
  String? selectedTrimestre;
  String? selectedClasse;
  String? selectedMatiere;
  
  // Variables pour stocker les listes de données
  List<String> anneesScolaires = [];
  List<String> trimestres = ["1er trimestre", "2ème trimestre", "3ème trimestre"];
  List<String> classes = [];
  List<String> matieres = ["Mathématiques", "Français", "Physique", "Histoire", "Sport", "Sciences"];

  // Couleurs pour correspondre au style AjouterProfScreen
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  // Charger les données initiales (années scolaires et classes)
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });
    
    try {
      // Récupérer les années scolaires
      QuerySnapshot yearSnapshot = await _firestore.collection('classes').get();
      Set<String> years = {};
      
      for (var doc in yearSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('anneeScolaire')) {
          years.add(data['anneeScolaire']);
        }
      }
      anneesScolaires = years.toList();
      
      // Récupérer les classes
      QuerySnapshot classSnapshot = await _firestore.collection('classes').get();
      List<String> classesList = [];
      
      for (var doc in classSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('numeroClasse')) {
          classesList.add(data['numeroClasse']);
        }
      }
      classes = classesList;
      
      setState(() {
        _isLoadingData = false;
      });
    } catch (e) {
      print("Erreur lors du chargement des données: $e");
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  // Charger les devoirs depuis Firestore selon les critères sélectionnés
  Future<void> _loadHomeworks() async {
    if (!_canViewHomeworks()) return;
    
    try {
      Query query = _firestore.collection('devoir');
      
      // Ajouter les filtres selon les sélections
      if (selectedYear != null) {
        query = query.where('anneeScolaire', isEqualTo: selectedYear);
      }
      if (selectedTrimestre != null) {
        query = query.where('trimestre', isEqualTo: selectedTrimestre);
      }
      if (selectedClasse != null) {
        query = query.where('classe', isEqualTo: selectedClasse);
      }
      if (selectedMatiere != null) {
        query = query.where('matiere', isEqualTo: selectedMatiere);
      }
      
      QuerySnapshot querySnapshot = await query.get();
      setState(() {
        _homeworks = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de chargement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour ajouter un devoir à Firestore
  Future<void> _addHomework() async {
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Veuillez écrire un sujet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_canViewHomeworks()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Veuillez sélectionner tous les critères'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Créer un nouveau document dans la collection "devoir"
      await _firestore.collection('devoir').add({
        'subject': _subjectController.text,
        'anneeScolaire': selectedYear,
        'trimestre': selectedTrimestre,
        'classe': selectedClasse,
        'matiere': selectedMatiere,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Devoir ajouté avec succès!'),
          backgroundColor: greenColor,
        ),
      );
      _subjectController.clear();
      _loadHomeworks(); // Actualiser la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour supprimer un devoir de Firestore
  Future<void> _deleteHomework(String homeworkId) async {
    try {
      await _firestore.collection('devoir').doc(homeworkId).delete();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Devoir supprimé avec succès!'),
          backgroundColor: greenColor,
        ),
      );
      
      _loadHomeworks(); // Actualiser la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la suppression: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialogue de confirmation pour la suppression
  Future<void> _showDeleteDialog(String homeworkId, String subject) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete, color: Colors.red),
            ),
            SizedBox(width: 12),
            Text('Confirmer'),
          ],
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer définitivement ce devoir ?\n\n"$subject"',
          style: TextStyle(color: darkColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteHomework(homeworkId);
            },
            child: Text(
              'Supprimer',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Widget de champ de sélection personnalisé avec cadre
  Widget _buildDropdown(String label, List<String> items, String? selectedValue, Function(String?) onChanged) {
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
            DropdownButtonFormField<String>(
              value: selectedValue,
              isExpanded: true,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              icon: Icon(Icons.arrow_drop_down, color: greenColor),
              items: items.map((item) => DropdownMenuItem(
                value: item, 
                child: Text(item)
              )).toList(),
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 16,
                color: darkColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget de champ de saisie personnalisé avec cadre
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    Icon? suffixIcon,
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
              maxLines: maxLines,
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

  // Vérifier si on peut voir les devoirs (tous les critères sélectionnés)
  bool _canViewHomeworks() {
    return selectedYear != null && 
           selectedTrimestre != null && 
           selectedClasse != null && 
           selectedMatiere != null;
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
                        Row(
                          children: [
                            Icon(Icons.assignment, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'DEVOIRS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Gestion des devoirs de classe",
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
          
          // Contenu principal
          SliverToBoxAdapter(
            child: _isLoadingData 
              ? Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: orangeColor),
                ))
              : Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section de sélection des critères
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
                                    Icons.filter_list,
                                    color: greenColor,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  "Sélection des critères",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            
                            // Champs de sélection
                            _buildDropdown(
                              "ANNÉE SCOLAIRE", 
                              anneesScolaires,
                              selectedYear,
                              (value) {
                                setState(() {
                                  selectedYear = value;
                                  if (_canViewHomeworks()) {
                                    _loadHomeworks();
                                  }
                                });
                              }
                            ),
                            _buildDropdown(
                              "TRIMESTRE", 
                              trimestres,
                              selectedTrimestre,
                              (value) {
                                setState(() {
                                  selectedTrimestre = value;
                                  if (_canViewHomeworks()) {
                                    _loadHomeworks();
                                  }
                                });
                              }
                            ),
                            _buildDropdown(
                              "CLASSE", 
                              classes,
                              selectedClasse,
                              (value) {
                                setState(() {
                                  selectedClasse = value;
                                  if (_canViewHomeworks()) {
                                    _loadHomeworks();
                                  }
                                });
                              }
                            ),
                            _buildDropdown(
                              "MATIÈRE", 
                              matieres,
                              selectedMatiere,
                              (value) {
                                setState(() {
                                  selectedMatiere = value;
                                  if (_canViewHomeworks()) {
                                    _loadHomeworks();
                                  }
                                });
                              }
                            ),
                          ],
                        ),
                      ),
                      
                      // Section d'ajout de devoir (visible seulement si critères sélectionnés)
                      if (_canViewHomeworks()) ...[
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
                                      Icons.assignment_add,
                                      color: orangeColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Ajouter un nouveau devoir",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Champ de saisie pour le sujet
                              _buildInputField(
                                controller: _subjectController,
                                label: "Sujet du devoir",
                                maxLines: 3,
                                suffixIcon: Icon(Icons.subject, color: greenColor),
                              ),
                              
                              SizedBox(height: 20),
                              
                              // Bouton pour ajouter un devoir
                              Container(
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _addHomework,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: orangeColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isLoading
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              "Ajouter le devoir",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Section des devoirs récents
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
                                      Icons.list_alt,
                                      color: greenColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Liste des devoirs",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              
                              // Liste des devoirs
                              _homeworks.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(32.0),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.assignment_outlined,
                                              size: 64,
                                              color: darkColor.withOpacity(0.3),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              "Aucun devoir disponible",
                                              style: TextStyle(
                                                color: darkColor.withOpacity(0.6),
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Ajoutez votre premier devoir ci-dessus",
                                              style: TextStyle(
                                                color: darkColor.withOpacity(0.4),
                                                fontSize: 14,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: _homeworks.length,
                                      itemBuilder: (context, index) {
                                        final homework = _homeworks[index];
                                        
                                        return Container(
                                          margin: EdgeInsets.only(bottom: 12),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: darkColor.withOpacity(0.1),
                                              width: 1,
                                            ),
                                            color: Colors.grey.shade50,
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            title: Text(
                                              homework['subject'] ?? 'Sujet non spécifié',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: darkColor,
                                                fontSize: 16,
                                              ),
                                            ),
                                            subtitle: Padding(
                                              padding: EdgeInsets.only(top: 4),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${homework['classe']} - ${homework['matiere']}",
                                                    style: TextStyle(
                                                      color: orangeColor,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    "${homework['trimestre']} • ${homework['anneeScolaire']}",
                                                    style: TextStyle(
                                                      color: darkColor.withOpacity(0.6),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            leading: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: orangeColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.assignment,
                                                color: orangeColor,
                                                size: 20,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: Colors.red.shade400,
                                                size: 22,
                                              ),
                                              onPressed: () => _showDeleteDialog(
                                                homework.id,
                                                homework['subject'] ?? 'Sujet non spécifié',
                                              ),
                                              tooltip: 'Supprimer le devoir',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Section informative quand les critères ne sont pas tous sélectionnés
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    "Information",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Veuillez sélectionner tous les critères ci-dessus (Année scolaire, Trimestre, Classe et Matière) pour commencer à gérer les devoirs. Une fois tous les champs remplis, vous pourrez ajouter, consulter et supprimer les devoirs.",
                                style: TextStyle(
                                  color: darkColor.withOpacity(0.7),
                                  fontSize: 14,
                                  height: 1.5,
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
        ],
      ),
    );
  }
}