/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConvocationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> convocation;
  
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);

  ConvocationDetailsScreen({required this.convocation});

  @override
  Widget build(BuildContext context) {
    final anneeScolaire = convocation['anneeScolaire'] ?? '';
    final classeId = convocation['classeId'] ?? '';
    final classeNiveaux = convocation['classeNiveaux'] ?? '';
    final classeNumero = convocation['classeNumero'] ?? '';
    final date = convocation['date'] ?? '';
    final eleveId = convocation['eleveId'] ?? '';
    final eleveNom = convocation['eleveNom'] ?? '';
    final remarque = convocation['remarque'] ?? '';
    final timestamp = convocation['timestamp'] ?? '';

    return Scaffold(
      backgroundColor: lightColor,
      appBar: AppBar(
        title: Text('Détails de la convocation'),
        backgroundColor: orangeColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // En-tête avec gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    orangeColor,
                    orangeColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        radius: 40,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        eleveNom,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: $eleveId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 16),
                      Chip(
                        backgroundColor: Colors.white,
                        label: Text(
                          'Convocation du $date',
                          style: TextStyle(
                            color: orangeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        avatar: Icon(
                          Icons.event,
                          color: orangeColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Informations principales
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations scolaires',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: greenColor,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildDetailRow('Année scolaire', anneeScolaire, Icons.calendar_today),
                      _buildDivider(),
                      _buildDetailRow('Classe ID', classeId, Icons.class_),
                      _buildDivider(),
                      _buildDetailRow('Niveau', classeNiveaux, Icons.school),
                      _buildDivider(),
                      _buildDetailRow('Numéro de classe', classeNumero, Icons.format_list_numbered),
                    ],
                  ),
                ),
              ),
            ),
            
            // Section remarque
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ' la convocation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: orangeColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: orangeColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: orangeColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          remarque,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: darkColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: darkColor.withOpacity(0.6),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Enregistré le: $timestamp',
                            style: TextStyle(
                              color: darkColor.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Boutons d'actions
           
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData iconData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: greenColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              iconData,
              color: greenColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: darkColor.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Divider(
        color: darkColor.withOpacity(0.1),
        height: 1,
      ),
    );
  }
}*/