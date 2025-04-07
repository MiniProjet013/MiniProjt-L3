import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EmploiExamensScreen extends StatefulWidget {
  @override
  _EmploiExamensScreenState createState() => _EmploiExamensScreenState();
}

class _EmploiExamensScreenState extends State<EmploiExamensScreen> {
  String? selectedLevel;
  String? selectedClass;
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  TextEditingController subjectController = TextEditingController();
  TextEditingController salleController = TextEditingController();
  
  final List<String> levels = ["1ère année", "2ème année", "3ème année"];
  final List<String> classes = ["Classe A", "Classe B", "Classe C"];
  final List<Map<String, dynamic>> examsSchedule = [];
  
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(232, 2, 196, 34),
        title: Text(
          "جدول اختبارات",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSchedule,
            tooltip: 'حفظ الجدول',
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: _printSchedule,
            tooltip: 'طباعة الجدول',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // تقويم لاختيار التاريخ
            Card(
              elevation: 4,
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(Duration(days: 60)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    selectedDate = selectedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: Color.fromARGB(232, 2, 196, 34),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  formatButtonTextStyle: TextStyle(color: Colors.white),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color.fromARGB(232, 2, 196, 34),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.orangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // اختيار المستوى والقسم
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "المستوى",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    value: selectedLevel,
                    items: levels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedLevel = value;
                      });
                    },
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "القسم",
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    value: selectedClass,
                    items: classes.map((classe) {
                      return DropdownMenuItem(
                        value: classe,
                        child: Text(classe),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedClass = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // تفاصيل الاختبار
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "إضافة اختبار جديد",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(232, 2, 196, 34),
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    TextFormField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: "المادة",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    TextFormField(
                      controller: salleController,
                      decoration: InputDecoration(
                        labelText: "القاعة",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.meeting_room),
                      ),
                    ),
                    SizedBox(height: 10),
                    
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "وقت البداية",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                startTime != null
                                    ? startTime!.format(context)
                                    : "اختر الوقت",
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: "وقت النهاية",
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.access_time),
                              ),
                              child: Text(
                                endTime != null
                                    ? endTime!.format(context)
                                    : "اختر الوقت",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: _addExam,
                      child: Text("إضافة الاختبار"),
                      style: ElevatedButton.styleFrom(
                        iconColor: Color.fromARGB(232, 2, 196, 34),
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // قائمة الاختبارات المضافة
            if (examsSchedule.isNotEmpty) ...[
              Text(
                "جدول الاختبارات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      for (var exam in examsSchedule)
                        ListTile(
                          title: Text(exam['subject']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${exam['date']}"),
                              Text("${exam['startTime']} - ${exam['endTime']}"),
                              Text("القاعة: ${exam['salle']}"),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeExam(exam),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  void _addExam() {
    if (selectedLevel == null ||
        selectedClass == null ||
        selectedDate == null ||
        startTime == null ||
        endTime == null ||
        subjectController.text.isEmpty ||
        salleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("الرجاء ملء جميع الحقول")),
      );
      return;
    }

    setState(() {
      examsSchedule.add({
        'level': selectedLevel,
        'class': selectedClass,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate!),
        'startTime': startTime!.format(context),
        'endTime': endTime!.format(context),
        'subject': subjectController.text,
        'salle': salleController.text,
      });

      // Reset fields
      subjectController.clear();
      salleController.clear();
      startTime = null;
      endTime = null;
    });
  }

  void _removeExam(Map<String, dynamic> exam) {
    setState(() {
      examsSchedule.remove(exam);
    });
  }

  void _saveSchedule() {
    if (examsSchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("لا يوجد اختبارات لحفظها")),
      );
      return;
    }

    // هنا يمكنك إضافة كود لحفظ الجدول في قاعدة البيانات
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم حفظ جدول الاختبارات بنجاح")),
    );
  }

  void _printSchedule() {
    if (examsSchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("لا يوجد اختبارات لطباعتها")),
      );
      return;
    }

    // هنا يمكنك إضافة كود لطباعة الجدول
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("جاري تحضير الجدول للطباعة...")),
    );
  }
}