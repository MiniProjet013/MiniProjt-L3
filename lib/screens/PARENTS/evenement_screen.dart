import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EvenementsPage extends StatefulWidget {
  const EvenementsPage({super.key});

  @override
  State<EvenementsPage> createState() => _EvenementsPageState();
}

class _EvenementsPageState extends State<EvenementsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _evenements = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchEvenements();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Fonction pour récupérer les événements depuis Firestore
  Future<void> _fetchEvenements() async {
    try {
      final snapshot = await _firestore.collection('evenements').get();
      
      setState(() {
        _evenements = snapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erreur de chargement des événements: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fonction pour formater l'heure en "1h30min"
  String _formatDuration(DateTime eventTime) {
    Duration difference = DateTime.now().difference(eventTime);
    int heures = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);
    return "${heures}h${minutes}min";
  }

  // Fonction pour formater la date en "jour/mois/année"
  String _formatDate(DateTime date) {
    return DateFormat("dd/MM/yyyy").format(date);
  }

  // Fonction pour obtenir une icône en fonction du type d'événement
  IconData _getEventIcon(String type) {
    switch (type.toLowerCase()) {
      case 'réunion':
        return Icons.people;
      case 'examen':
        return Icons.quiz;
      case 'devoir':
        return Icons.assignment;
      case 'sortie':
        return Icons.directions_bus;
      case 'vacances':
        return Icons.beach_access;
      default:
        return Icons.event;
    }
  }

  // Fonction pour obtenir une couleur en fonction du type d'événement
  Color _getEventColor(String type) {
    switch (type.toLowerCase()) {
      case 'réunion':
        return Colors.blue;
      case 'examen':
        return Colors.red;
      case 'devoir':
        return Colors.purple;
      case 'sortie':
        return Colors.green;
      case 'vacances':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // En-tête fixe avec dégradé
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4285F4), Color(0xFF5B6AF0)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "ÉVÉNEMENTS",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 48), // Pour équilibrer le layout
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: Container(
              color: Colors.white,
              child: _isLoading 
                ? _buildLoadingContent() 
                : _buildMainContent(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fonction pour ajouter un nouvel événement
          // Implémentez votre logique ici
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: 5, // Nombre de placeholders
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        width: 54,
                        height: 54,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 14,
                    width: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_evenements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.event_busy, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Aucun événement disponible",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEvenements,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        itemCount: _evenements.length,
        itemBuilder: (context, index) {
          final evenement = _evenements[index];
          
          DateTime eventDate = (evenement['date'] as Timestamp).toDate();
          String formattedDate = _formatDate(eventDate);
          String formattedTime = _formatDuration(eventDate);
          String type = evenement['type'] ?? 'Autre';
          IconData eventIcon = _getEventIcon(type);
          Color eventColor = _getEventColor(type);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                // Détails de l'événement
                _showEventDetails(context, evenement, eventDate);
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: eventColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            eventIcon,
                            size: 30,
                            color: eventColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                evenement['description'] ?? 'Sans description',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type,
                                style: TextStyle(
                                  color: eventColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, 
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, 
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              "Il y a $formattedTime",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEventDetails(BuildContext context, Map<String, dynamic> evenement, DateTime eventDate) {
    String formattedDate = _formatDate(eventDate);
    String formattedTime = _formatDuration(eventDate);
    String type = evenement['type'] ?? 'Autre';
    IconData eventIcon = _getEventIcon(type);
    Color eventColor = _getEventColor(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [eventColor, eventColor.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(eventIcon, color: eventColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    evenement['description'] ?? 'Sans description',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    type,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(Icons.calendar_today, "Date", formattedDate),
                    _buildDetailItem(Icons.access_time, "Il y a", formattedTime),
                    
                    if (evenement['lieu'] != null)
                      _buildDetailItem(Icons.location_on, "Lieu", evenement['lieu']),
                    
                    if (evenement['participants'] != null)
                      _buildDetailItem(Icons.people, "Participants", 
                          evenement['participants'].toString()),
                    
                    const SizedBox(height: 20),
                    const Text(
                      "Description détaillée",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evenement['descriptionDetaillee'] ?? 
                      evenement['description'] ?? 
                      "Aucune description détaillée disponible pour cet événement.",
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}