import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({Key? key}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _specialtyController = TextEditingController();

  // Education
  final List<Map<String, String>> _education = [];
  final TextEditingController _degreeController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // Work Experience
  final List<Map<String, String>> _experience = [];
  final TextEditingController _positionController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Skills
  final List<String> _skills = [];
  final TextEditingController _skillController = TextEditingController();

  // Publications
  final List<String> _publications = [];
  final TextEditingController _publicationController = TextEditingController();

  // Profile Image
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // CV File
  String? _cvFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _specialtyController.dispose();
    _degreeController.dispose();
    _institutionController.dispose();
    _yearController.dispose();
    _positionController.dispose();
    _companyController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _skillController.dispose();
    _publicationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  void _addEducation() {
    if (_degreeController.text.isNotEmpty &&
        _institutionController.text.isNotEmpty &&
        _yearController.text.isNotEmpty) {
      setState(() {
        _education.add({
          'degree': _degreeController.text,
          'institution': _institutionController.text,
          'year': _yearController.text,
        });
        _degreeController.clear();
        _institutionController.clear();
        _yearController.clear();
      });
    }
  }

  void _addExperience() {
    if (_positionController.text.isNotEmpty &&
        _companyController.text.isNotEmpty &&
        _durationController.text.isNotEmpty) {
      setState(() {
        _experience.add({
          'position': _positionController.text,
          'company': _companyController.text,
          'duration': _durationController.text,
          'description': _descriptionController.text,
        });
        _positionController.clear();
        _companyController.clear();
        _durationController.clear();
        _descriptionController.clear();
      });
    }
  }

  void _addSkill() {
    if (_skillController.text.isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text);
        _skillController.clear();
      });
    }
  }

  void _addPublication() {
    if (_publicationController.text.isNotEmpty) {
      setState(() {
        _publications.add(_publicationController.text);
        _publicationController.clear();
      });
    }
  }

  void _uploadCV() {
    // In a real app, this would use a file picker
    setState(() {
      _cvFileName = 'CV_Professeur.pdf';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CV téléchargé avec succès'),
        backgroundColor: Color(0xFF4CAF50), // Green color
      ),
    );
  }

  void _savePortfolio() {
    if (_formKey.currentState!.validate()) {
      // In a real app, this would save the data to a database
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Portfolio enregistré avec succès'),
          backgroundColor: Color(0xFF4CAF50), // Green color
        ),
      );
    }
  }

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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Image
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE67E22), // Orange color
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionTitle('Informations Personnelles'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom Complet',
                  prefixIcon: Icon(Icons.person, color: Color(0xFFE67E22)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color(0xFFE67E22)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFFE67E22)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFFE67E22)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Spécialité',
                  prefixIcon: Icon(Icons.school, color: Color(0xFFE67E22)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre spécialité';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Education Section
              _buildSectionTitle('Formation'),
              ..._education.map((edu) => _buildEducationItem(edu)).toList(),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _degreeController,
                        decoration: const InputDecoration(
                          labelText: 'Diplôme',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _institutionController,
                        decoration: const InputDecoration(
                          labelText: 'Institution',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _yearController,
                        decoration: const InputDecoration(
                          labelText: 'Année',
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addEducation,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter Formation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE67E22), // Orange color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Work Experience Section
              _buildSectionTitle('Expérience Professionnelle'),
              ..._experience.map((exp) => _buildExperienceItem(exp)).toList(),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Poste',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Établissement',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _durationController,
                        decoration: const InputDecoration(
                          labelText: 'Durée (ex: 2018-2022)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _addExperience,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter Expérience'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE67E22), // Orange color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Skills Section
              _buildSectionTitle('Compétences'),
              Wrap(
                spacing: 8,
                children: _skills
                    .map((skill) => Chip(
                          label: Text(skill),
                          backgroundColor: Colors.grey[200],
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _skills.remove(skill);
                            });
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(
                        labelText: 'Nouvelle compétence',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add_circle),
                    color: const Color(0xFFE67E22), // Orange color
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Publications Section
              _buildSectionTitle('Publications'),
              ..._publications.asMap().entries.map((entry) {
                final index = entry.key;
                final publication = entry.value;
                return ListTile(
                  leading: const Icon(Icons.article, color: Color(0xFFE67E22)),
                  title: Text(publication),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _publications.removeAt(index);
                      });
                    },
                  ),
                );
              }).toList(),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _publicationController,
                      decoration: const InputDecoration(
                        labelText: 'Nouvelle publication',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addPublication,
                    icon: const Icon(Icons.add_circle),
                    color: const Color(0xFFE67E22), // Orange color
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // CV Upload Section
              _buildSectionTitle('CV'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_cvFileName != null)
                        ListTile(
                          leading: const Icon(Icons.description,
                              color: Color(0xFFE67E22)),
                          title: Text(_cvFileName!),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _cvFileName = null;
                              });
                            },
                          ),
                        )
                      else
                        const Text('Aucun CV téléchargé'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _uploadCV,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Télécharger CV'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFE67E22), // Orange color
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePortfolio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50), // Green color
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'ENREGISTRER LE PORTFOLIO',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50), // Green color
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: Color(0xFF4CAF50), // Green color
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationItem(Map<String, String> education) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(education['degree'] ?? ''),
        subtitle: Text('${education['institution']} (${education['year']})'),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _education.remove(education);
            });
          },
        ),
      ),
    );
  }

  Widget _buildExperienceItem(Map<String, String> experience) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(experience['position'] ?? ''),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${experience['company']} (${experience['duration']})'),
            if (experience['description']?.isNotEmpty ?? false)
              Text(
                experience['description'] ?? '',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        isThreeLine: experience['description']?.isNotEmpty ?? false,
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            setState(() {
              _experience.remove(experience);
            });
          },
        ),
      ),
    );
  }
}
