import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'profs/home_screen.dart';
import 'admin/admin_home_screen.dart';
import 'PARENTS/parent_home_screen.dart';

class CombinedRoleLoginScreen extends StatefulWidget {
  @override
  _CombinedRoleLoginScreenState createState() => _CombinedRoleLoginScreenState();
}

class _CombinedRoleLoginScreenState extends State<CombinedRoleLoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String? selectedRole;

  // Variables pour la section parent
  Map<String, String> enfants = {};
  List<TextEditingController> parentIdControllers = [TextEditingController()];
  final Map<String, String> enfantsDatabase = {
    "123": "Ahmed",
    "456": "Yasmine",
    "789": "Omar",
    "101": "Fatima",
  };

  void _login() async {
    if (selectedRole == null) {
      _showError("⚠️ Veuillez sélectionner un rôle d'abord!");
      return;
    }

    // Cas spécial pour les parents
    if (selectedRole == "parent") {
      if (enfants.isEmpty) {
        _showError("⚠️ Veuillez entrer au moins un ID enfant valide!");
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentHomeScreen(enfants: enfants)),
      );
      return;
    }

    // Pour les profs et admin
    setState(() => isLoading = true);

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("⚠️ Veuillez entrer votre e-mail et mot de passe!");
      setState(() => isLoading = false);
      return;
    }

    String? roleFromFirebase = await _authService.signInWithEmailAndRole(email, password);

    setState(() => isLoading = false);

    if (roleFromFirebase != null) {
      if (roleFromFirebase == selectedRole) {
        Widget nextScreen;
        if (selectedRole == "admin") {
          nextScreen = AdminHomeScreen();
        } else if (selectedRole == "prof") {
          nextScreen = EnseignantHomeScreen ();
        } else {
          _showError("⚠️ Rôle non supporté!");
          return;
        }
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => nextScreen));
      } else {
        _showError("⚠️ Vous ne pouvez pas vous connecter avec ce rôle!");
      }
    } else {
      _showError("⚠️ Échec de connexion. Vérifiez vos données!");
    }
  }

  void _validateEnfantsIds() {
    Map<String, String> enteredEnfants = {};
    for (var controller in parentIdControllers) {
      String id = controller.text.trim();
      if (id.isNotEmpty && enfantsDatabase.containsKey(id)) {
        enteredEnfants[id] = enfantsDatabase[id]!;
      }
    }

    if (enteredEnfants.isNotEmpty) {
      setState(() => enfants = enteredEnfants);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ParentHomeScreen(enfants: enteredEnfants)),
      );
    } else {
      _showError("⚠️ Aucun ID valide n'a été entré");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 6, 63, 1),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                Center(
                  child: Text(
                    "Connexion",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                
                // Section de sélection de rôle
                Center(
                  child: Text(
                    "QUI ÊTES-VOUS?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRoleCircle(
                      title: "PARENT",
                      icon: Icons.family_restroom,
                      role: "parent",
                      color: Color.fromARGB(255, 255, 193, 7),
                    ),
                    _buildRoleCircle(
                      title: "ADMIN",
                      icon: Icons.admin_panel_settings,
                      role: "admin",
                      color: Color.fromARGB(213, 230, 122, 0),
                    ),
                    _buildRoleCircle(
                      title: "PROF",
                      icon: Icons.school,
                      role: "prof",
                      color: Color.fromARGB(255, 33, 150, 243),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Interface dynamique selon le rôle sélectionné
                if (selectedRole == "parent") ...[
                  Text(
                    "Veuillez entrer les ID de vos enfants",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  
                  Column(
                    children: List.generate(
                      parentIdControllers.length,
                      (index) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: parentIdControllers[index],
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "ID de l'enfant ${index + 1}",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white54),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            if (parentIdControllers.length > 1)
                              IconButton(
                                icon: Icon(Icons.remove_circle, color: Colors.red),
                                onPressed: () {
                                  setState(() => parentIdControllers.removeAt(index));
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => parentIdControllers.add(TextEditingController())),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text("Ajouter un autre ID", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(213, 230, 122, 0)),
                  ),
                  
                  SizedBox(height: 30),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(213, 230, 122, 0),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton(
                      onPressed: _validateEnfantsIds,
                      child: Text(
                        "VALIDER",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],

                if (selectedRole == "admin" || selectedRole == "prof") ...[
                  _buildLoginField(
                    controller: emailController,
                    hint: "Email",
                    icon: Icons.email_outlined,
                  ),
                  SizedBox(height: 15),
                  _buildLoginField(
                    controller: passwordController,
                    hint: "Mot de passe",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  SizedBox(height: 30),
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: Colors.white))
                      : Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(213, 230, 122, 0),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextButton(
                            onPressed: _login,
                            child: Text(
                              "SE CONNECTER",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCircle({
    required String title,
    required IconData icon,
    required String role,
    required Color color,
  }) {
    bool isSelected = selectedRole == role;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
          if (role == "parent") {
            enfants.clear();
            parentIdControllers = [TextEditingController()];
          } else {
            enfants.clear();
            parentIdControllers = [TextEditingController()];
            emailController.clear();
            passwordController.clear();
          }
        });
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected ? [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 10,
                )
              ] : null,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 35),
            ),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            SizedBox(width: 15),
            Expanded(
              child: TextField(
                controller: controller,
                obscureText: isPassword,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}