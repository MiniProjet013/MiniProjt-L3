/*import 'package:flutter/material.dart';

class AbsenceFiltersWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onFilterChanged;
  
  AbsenceFiltersWidget({this.onFilterChanged});
  
  @override
  _AbsenceFiltersWidgetState createState() => _AbsenceFiltersWidgetState();
}

class _AbsenceFiltersWidgetState extends State<AbsenceFiltersWidget> {
  final Color orangeColor = Color.fromARGB(255, 218, 64, 3);
  final Color greenColor = Color.fromARGB(255, 1, 110, 5);
  final Color lightColor = Color.fromARGB(255, 255, 255, 255);
  final Color darkColor = Color(0xFF333333);
  
  bool _isExpanded = false;
  String? _selectedClass;
  String? _selectedMonth;
  String? _selectedMatiere;
  bool? _isJustified;
  
  final List<String> _classes = ['C-6117', 'B-4322', 'A-7891', 'Toutes les classes'];
  final List<String> _months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre', 'Tous les mois'];
  final List<String> _matieres = ['Français', 'Mathématiques', 'Sciences', 'Histoire', 'Géographie', 'Anglais', 'Toutes les matières'];
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre de filtre avec bouton d'expansion
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: orangeColor,
                ),
                SizedBox(width: 8),
                Text(
                  'Filtrer les absences',
                  style: TextStyle(
                    color: darkColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: greenColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: greenColor,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Contenu des filtres (visible seulement quand expandé)
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _isExpanded ? 320 : 0,
          curve: Curves.fastOutSlowIn,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterTitle('Classe'),
                  _buildDropdownFilter(_classes, _selectedClass, (value) {
                    setState(() {
                      _selectedClass = value;
                      _applyFilters();
                    });
                  }),
                  SizedBox(height: 16),
                  
                  _buildFilterTitle('Mois'),
                  _buildDropdownFilter(_months, _selectedMonth, (value) {
                    setState(() {
                      _selectedMonth = value;
                      _applyFilters();
                    });
                  }),
                  SizedBox(height: 16),
                  
                  _buildFilterTitle('Matière'),
                  _buildDropdownFilter(_matieres, _selectedMatiere, (value) {
                    setState(() {
                      _selectedMatiere = value;
                      _applyFilters();
                    });
                  }),
                  SizedBox(height: 16),
                  
                  _buildFilterTitle('Justification'),
                  Row(
                    children: [
                      _buildSelectableChip('Justifiées', _isJustified == true, () {
                        setState(() {
                          _isJustified = _isJustified == true ? null : true;
                          _applyFilters();
                        });
                      }),
                      SizedBox(width: 8),
                      _buildSelectableChip('Non justifiées', _isJustified == false, () {
                        setState(() {
                          _isJustified = _isJustified == false ? null : false;
                          _applyFilters();
                        });
                      }),
                      SizedBox(width: 8),
                      _buildSelectableChip('Toutes', _isJustified == null, () {
                        setState(() {
                          _isJustified = null;
                          _applyFilters();
                        });
                      }),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Réinitialiser',
                            style: TextStyle(color: darkColor),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.grey.shade200,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _applyFilters,
                          child: Text(
                            'Appliquer',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: darkColor,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
  
  Widget _buildDropdownFilter(List<String> items, String? selectedItem, Function(String?) onChanged) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedItem,
        isExpanded: true,
        underline: SizedBox(),
        hint: Text('Sélectionner'),
        icon: Icon(Icons.keyboard_arrow_down, color: orangeColor),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildSelectableChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor : Colors.transparent,
          border: Border.all(
            color: isSelected ? orangeColor : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : darkColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
  
  void _applyFilters() {
    if (widget.onFilterChanged != null) {
      final Map<String, dynamic> filters = {};
      
      // Ne pas ajouter le filtre "Toutes les..." à la map
      if (_selectedClass != null && _selectedClass != 'Toutes les classes') {
        filters['classeId'] = _selectedClass;
      }
      
      if (_selectedMonth != null && _selectedMonth != 'Tous les mois') {
        filters['month'] = _months.indexOf(_selectedMonth!) + 1;
      }
      
      if (_selectedMatiere != null && _selectedMatiere != 'Toutes les matières') {
        filters['matiere'] = _selectedMatiere;
      }
      
      if (_isJustified != null) {
        filters['justified'] = _isJustified;
      }
      
      widget.onFilterChanged!(filters);
    }
  }
  
  void _resetFilters() {
    setState(() {
      _selectedClass = null;
      _selectedMonth = null;
      _selectedMatiere = null;
      _isJustified = null;
    });
    
    if (widget.onFilterChanged != null) {
      widget.onFilterChanged!({});
    }
  }
}*/