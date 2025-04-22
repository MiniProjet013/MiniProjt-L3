import 'package:flutter/material.dart';

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Portfolio'),
        backgroundColor: const Color(0xFF4CAF50), // Green color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Partage du portfolio...'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4CAF50),
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Title
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. Sophie Martin',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Professeur de Mathématiques',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.email,
                                size: 16, color: Color(0xFFE67E22)),
                            SizedBox(width: 4),
                            Text('s.martin@universite.fr'),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: Color(0xFFE67E22)),
                            SizedBox(width: 4),
                            Text('+33 6 12 34 56 78'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Section: À propos
            _buildSection(
              title: 'À propos',
              icon: Icons.person,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Professeur de mathématiques avec plus de 15 ans d\'expérience dans l\'enseignement supérieur. Spécialisée en analyse numérique et équations différentielles avec des applications en modélisation environnementale. Passionnée par la pédagogie innovante et l\'utilisation des technologies dans l\'enseignement des mathématiques.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Section: Formation
            _buildSection(
              title: 'Formation',
              icon: Icons.school,
              child: Column(
                children: [
                  _buildEducationItem(
                    degree: 'Doctorat en Mathématiques Appliquées',
                    institution: 'Université de Paris',
                    year: '2005 - 2008',
                  ),
                  _buildEducationItem(
                    degree: 'Master en Mathématiques',
                    institution: 'École Normale Supérieure',
                    year: '2003 - 2005',
                  ),
                  _buildEducationItem(
                    degree: 'Licence en Mathématiques',
                    institution: 'Université de Lyon',
                    year: '2000 - 2003',
                  ),
                ],
              ),
            ),

            // Section: Expérience Professionnelle
            _buildSection(
              title: 'Expérience Professionnelle',
              icon: Icons.work,
              child: Column(
                children: [
                  _buildExperienceItem(
                    position: 'Professeur des Universités',
                    institution: 'Université de Montpellier',
                    period: '2015 - Présent',
                    description:
                        'Enseignement des mathématiques avancées aux niveaux licence et master. Responsable du département de mathématiques appliquées.',
                  ),
                  _buildExperienceItem(
                    position: 'Maître de Conférences',
                    institution: 'Université de Toulouse',
                    period: '2008 - 2015',
                    description:
                        'Enseignement et recherche en analyse numérique et modélisation mathématique.',
                  ),
                  _buildExperienceItem(
                    position: 'Chercheur Post-doctoral',
                    institution: 'CNRS',
                    period: '2008 - 2010',
                    description:
                        'Recherche sur les méthodes numériques pour les équations aux dérivées partielles.',
                  ),
                ],
              ),
            ),

            // Section: Publications
            _buildSection(
              title: 'Publications',
              icon: Icons.article,
              child: Column(
                children: [
                  _buildPublicationItem(
                    title: 'Numerical Methods for Environmental Modeling',
                    journal: 'Journal of Applied Mathematics',
                    year: '2020',
                  ),
                  _buildPublicationItem(
                    title:
                        'Innovative Approaches to Teaching Differential Equations',
                    journal: 'Mathematics Education Research Journal',
                    year: '2018',
                  ),
                  _buildPublicationItem(
                    title: 'Finite Element Analysis of Fluid Dynamics Problems',
                    journal: 'Computational Mathematics and Modeling',
                    year: '2015',
                  ),
                  // View More button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Affichage de toutes les publications...'),
                            backgroundColor: Color(0xFF4CAF50),
                          ),
                        );
                      },
                      child: const Text(
                        'Voir plus (12 publications)',
                        style: TextStyle(color: Color(0xFFE67E22)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Section: Compétences
            _buildSection(
              title: 'Compétences',
              icon: Icons.psychology,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkillCategory(
                      category: 'Domaines d\'expertise',
                      skills: [
                        'Analyse numérique',
                        'Équations différentielles',
                        'Modélisation mathématique',
                        'Statistiques appliquées',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSkillCategory(
                      category: 'Langages de programmation',
                      skills: [
                        'MATLAB',
                        'Python',
                        'R',
                        'LaTeX',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSkillCategory(
                      category: 'Langues',
                      skills: [
                        'Français (natif)',
                        'Anglais (courant)',
                        'Espagnol (intermédiaire)',
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Section: Enseignements
            _buildSection(
              title: 'Enseignements',
              icon: Icons.cast_for_education,
              child: Column(
                children: [
                  _buildCourseItem(
                    title: 'Analyse Numérique',
                    level: 'Master 1',
                    description:
                        'Méthodes numériques pour la résolution d\'équations différentielles et aux dérivées partielles.',
                  ),
                  _buildCourseItem(
                    title: 'Calcul Différentiel',
                    level: 'Licence 3',
                    description:
                        'Introduction aux concepts fondamentaux du calcul différentiel et intégral.',
                  ),
                  _buildCourseItem(
                    title: 'Statistiques pour les Sciences',
                    level: 'Licence 2',
                    description:
                        'Application des méthodes statistiques dans les sciences expérimentales.',
                  ),
                ],
              ),
            ),

            // Download CV Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Téléchargement du CV en cours...'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Télécharger le CV complet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFE67E22),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child,
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildEducationItem({
    required String degree,
    required String institution,
    required String year,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  degree,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(institution),
                const SizedBox(height: 2),
                Text(
                  year,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceItem({
    required String position,
    required String institution,
    required String period,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(institution),
                const SizedBox(height: 2),
                Text(
                  period,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicationItem({
    required String title,
    required String journal,
    required String year,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.article,
            size: 16,
            color: Color(0xFFE67E22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$journal, $year',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillCategory({
    required String category,
    required List<String> skills,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFE67E22).withOpacity(0.3),
                ),
              ),
              child: Text(skill),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCourseItem({
    required String title,
    required String level,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.book,
            size: 16,
            color: Color(0xFFE67E22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
