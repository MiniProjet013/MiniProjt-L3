import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EvenementsProf extends StatefulWidget {
  const EvenementsProf({Key? key}) : super(key: key);

  @override
  State<EvenementsProf> createState() => _EvenementsProfState();
}

class _EvenementsProfState extends State<EvenementsProf> {
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
        return Color.fromARGB(255, 1, 110, 5);
      case 'examen':
        return Color.fromARGB(255, 218, 64, 3);
      case 'devoir':
        return Colors.purple;
      case 'sortie':
        return Color.fromARGB(255, 1, 110, 5);
      case 'vacances':
        return Color.fromARGB(255, 218, 64, 3);
      default:
        return Color.fromARGB(255, 1, 110, 5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = Color.fromARGB(255, 218, 64, 3);
    final greenColor = Color.fromARGB(255, 1, 110, 5);
    final lightColor = Color.fromARGB(255, 255, 255, 255);

    return Scaffold(
      backgroundColor: lightColor,
      body: CustomScrollView(
        slivers: [
          // En-tête avec dégradé similaire à la page d'accueil
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    orangeColor.withOpacity(0.8),
                    greenColor.withOpacity(0.8)
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                          Text(
                            "ÉVÉNEMENTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.event,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Gestion des événements",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  DateFormat("dd/MM/yyyy").format(DateTime.now()),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: Container(
              color: lightColor,
              child: _isLoading 
                ? _buildLoadingContent() 
                : _buildMainContent(),
            ),
          ),
        ],
      ),
     /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fonction pour ajouter un nouvel événement
          // Implémentez votre logique ici
        },
        backgroundColor: orangeColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),*/
    );
  }

  Widget _buildLoadingContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
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
          );
        },
      ),
    );
  }

  Widget _buildMainContent() {
    if (_evenements.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 218, 64, 3).withOpacity(0.2),
                      Color.fromARGB(255, 1, 110, 5).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.event_busy, 
                  size: 40, 
                  color: Color.fromARGB(255, 1, 110, 5)
                ),
              ),
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
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchEvenements,
      color: Color.fromARGB(255, 1, 110, 5),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _evenements.length,
        itemBuilder: (context, index) {
          final evenement = _evenements[index];
          
          DateTime eventDate = (evenement['date'] as Timestamp).toDate();
          String formattedDate = _formatDate(eventDate);
          String formattedTime = _formatDuration(eventDate);
          String type = evenement['type'] ?? 'Autre';
          IconData eventIcon = _getEventIcon(type);
          Color eventColor = _getEventColor(type);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  _showEventDetails(context, evenement, eventDate);
                },
                splashColor: eventColor.withOpacity(0.2),
                highlightColor: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  eventColor.withOpacity(0.2),
                                  eventColor.withOpacity(0.4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              eventIcon,
                              size: 24,
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
                                    color: Color(0xFF333333),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: eventColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    type,
                                    style: TextStyle(
                                      color: eventColor,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, 
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, 
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(
                                "Il y a $formattedTime",
                                style: TextStyle(
                                  color: Colors.grey[600],
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    eventColor.withOpacity(0.8),
                    eventColor.withOpacity(0.6),
                  ],
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
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(eventIcon, color: eventColor, size: 24),
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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
                        color: Color(0xFF333333),
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
                        color: Color(0xFF333333),
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 1, 110, 5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: Color.fromARGB(255, 1, 110, 5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
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
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}