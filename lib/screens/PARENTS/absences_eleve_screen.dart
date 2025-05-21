import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AbsencesScreen extends StatefulWidget {
  final String eleveId;
  
  const AbsencesScreen({Key? key, required this.eleveId}) : super(key: key);

  @override
  _AbsencesScreenState createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> absences = [];
  Map<String, dynamic>? eleveData;
  String currentPeriod = 'Tous';
  List<String> periods = ['Tous', 'Trim. 1', 'Trim. 2', 'Trim. 3'];
  
  @override
  void initState() {
    super.initState();
    _fetchDataFromFirestore();
  }

  Future<void> _fetchDataFromFirestore() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Récupérer les données de l'élève
      DocumentSnapshot eleveSnapshot = await FirebaseFirestore.instance
          .collection('eleves')
          .doc(widget.eleveId)
          .get();

      if (eleveSnapshot.exists) {
        eleveData = eleveSnapshot.data() as Map<String, dynamic>;
      }

      // Récupérer les absences de l'élève sans orderBy pour éviter le besoin d'un index
      QuerySnapshot absencesSnapshot = await FirebaseFirestore.instance
          .collection('absences')
          .where('eleveId', isEqualTo: widget.eleveId)
          .get();

      absences = absencesSnapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();
          
      // Tri manuel des absences par date (si disponible)
      absences.sort((a, b) {
        // Gestion des dates au format String ou Timestamp
        DateTime? dateA = _parseDate(a['date']);
        DateTime? dateB = _parseDate(b['date']);
        
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA); // Ordre décroissant
        }
        return 0;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement des données: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Fonction pour analyser différents formats de date
  DateTime? _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      try {
        // Essayer de parser la date au format ISO String (YYYY-MM-DD)
        return DateTime.parse(dateValue);
      } catch (e) {
        try {
          // Essayer de parser au format français (DD/MM/YYYY)
          List<String> parts = dateValue.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]), // année
              int.parse(parts[1]), // mois
              int.parse(parts[0]), // jour
            );
          }
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _filterAbsencesByPeriod(String period) {
    if (period == 'Tous') {
      return absences;
    }

    // Définir les dates de début et fin selon le trimestre
    DateTime startDate;
    DateTime endDate;
    
    final currentYear = DateTime.now().year;
    
    switch (period) {
      case 'Trim. 1':
        startDate = DateTime(currentYear, 9, 1); // 1er septembre
        endDate = DateTime(currentYear, 12, 31); // 31 décembre
        break;
      case 'Trim. 2':
        startDate = DateTime(currentYear + 1, 1, 1); // 1er janvier
        endDate = DateTime(currentYear + 1, 3, 31); // 31 mars
        break;
      case 'Trim. 3':
        startDate = DateTime(currentYear + 1, 4, 1); // 1er avril
        endDate = DateTime(currentYear + 1, 6, 30); // 30 juin
        break;
      default:
        return absences;
    }

    return absences.where((absence) {
      DateTime? absenceDate = _parseDate(absence['date']);
      if (absenceDate != null) {
        return absenceDate.isAfter(startDate) && absenceDate.isBefore(endDate);
      }
      return false;
    }).toList();
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'justifiée':
        return '#4CAF50'; // Vert
      case 'non justifiée':
        return '#F44336'; // Rouge
      case 'en attente':
        return '#FFC107'; // Jaune
      default:
        return '#9E9E9E'; // Gris
    }
  }
  
  // Fonction pour formater la date pour l'affichage
  String _formatDate(dynamic dateValue) {
    DateTime? date = _parseDate(dateValue);
    if (date != null) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
    return 'Date non disponible';
  }
  
  // Fonction pour récupérer la durée de l'absence
  String _formatDuree(dynamic heures) {
    if (heures == null) return '0';
    
    if (heures is num) {
      return heures.toString();
    } else if (heures is String) {
      // Nettoyer la chaîne et remplacer la virgule par un point si nécessaire
      String cleanValue = heures.trim().replaceAll(',', '.');
      try {
        double? value = double.tryParse(cleanValue);
        return value != null ? value.toString() : heures;
      } catch (e) {
        return heures;
      }
    }
    return '0';
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredAbsences = _filterAbsencesByPeriod(currentPeriod);
    
    // Calculer les statistiques
    int totalAbsences = filteredAbsences.length;
    int justifiees = filteredAbsences.where((a) => a['statut'] == 'Justifiée').length;
    int nonJustifiees = filteredAbsences.where((a) => a['statut'] == 'Non justifiée').length;
    int enAttente = filteredAbsences.where((a) => a['statut'] == 'En attente').length;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // En-tête
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Absences',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: DropdownButton<String>(
                        value: currentPeriod,
                        dropdownColor: Color(0xFF4285F4),
                        underline: SizedBox(),
                        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              currentPeriod = newValue;
                            });
                          }
                        },
                        items: periods.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Information de l'élève
              if (eleveData != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Color(0xFF4285F4).withOpacity(0.2),
                            child: Text(
                              "${eleveData!['prenom']?[0] ?? ''}${eleveData!['nom']?[0] ?? ''}",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${eleveData!['prenom'] ?? ''} ${eleveData!['nom'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Classe: ${eleveData!['classeId'] ?? ''} - ${eleveData!['niveau'] ?? ''}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "ID: ${widget.eleveId}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Statistiques des absences
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStatisticCard(
                      totalAbsences.toString(),
                      'Total',
                      Colors.blue,
                      Icons.calendar_today,
                    ),
                    SizedBox(width: 8),
                    _buildStatisticCard(
                      justifiees.toString(),
                      'Justifiées',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    SizedBox(width: 8),
                    _buildStatisticCard(
                      nonJustifiees.toString(),
                      'Non justifiées',
                      Colors.red,
                      Icons.cancel,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Liste des absences
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : filteredAbsences.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Aucune absence pendant cette période',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: filteredAbsences.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> absence = filteredAbsences[index];
                                
                                // Formatage de la date avec nouvelle méthode
                                String date = _formatDate(absence['date']);
                                
                                // Récupération de la durée
                                String heures = _formatDuree(absence['heures']);
                                
                                String statut = absence['statut'] ?? 'Non défini';
                                Color statusColor = Color(int.parse(
                                    _getStatusColor(statut).replaceAll('#', '0xFF')));

                                return Card(
                                  elevation: 2,
                                  margin: EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.event, color: Color(0xFF4285F4)),
                                            SizedBox(width: 8),
                                            Text(
                                              date,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                statut,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time,
                                                color: Colors.grey[600], size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Durée: ${heures} heures',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.school,
                                                color: Colors.grey[600], size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Matière: ${absence['matiere'] ?? 'Non spécifiée'}',
                                              style: TextStyle(color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                        if (absence['motif'] != null && absence['motif'].isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Row(
                                              children: [
                                                Icon(Icons.description,
                                                    color: Colors.grey[600], size: 20),
                                                SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Motif: ${absence['motif']}',
                                                    style: TextStyle(color: Colors.grey[600]),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showFilterDialog();
        },
        backgroundColor: Color(0xFF4285F4),
        child: Icon(Icons.filter_list, color: Colors.white),
      ),
    );
  }

  Widget _buildStatisticCard(
      String count, String label, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrer par période'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: periods.map((period) {
              return ListTile(
                title: Text(period),
                trailing: period == currentPeriod
                    ? Icon(Icons.check, color: Color(0xFF4285F4))
                    : null,
                onTap: () {
                  setState(() {
                    currentPeriod = period;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}