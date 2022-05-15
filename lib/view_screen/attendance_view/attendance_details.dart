import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AttendanceDetails extends StatefulWidget {
  final String courseName, courseId, courseTime;

  AttendanceDetails({Key? key, required this.courseName,required this.courseId,required this.courseTime}) : super(key: key);

  @override
  State<AttendanceDetails> createState() => _AttendanceDetailsState();
}

class _AttendanceDetailsState extends State<AttendanceDetails> {
  final FirebaseDatabase database = FirebaseDatabase.instance;

  // Create a CollectionReference called users that references the firestore collection
  final CollectionReference _users =
      FirebaseFirestore.instance.collection('users');

  double textSize = 12;

  // int? userId =
  // int.tryParse(Hive.box('loginCredentials').get('id').toString());

  final DatabaseReference attendanceNodeRef =
      FirebaseDatabase.instance.ref("attendance");

  final int? hiveUserId =
      int.tryParse(Hive.box('loginCredentials').get('id').toString());

  final bool isStudent =
      Hive.box('loginCredentials').get('role').toString() == 'student';

  List<int> studentIdsFromRealTimeDB = [];

  late List<Map<String, dynamic>> listOfStudents = [];

  var tempList = [
    {"noArgs": "loading Data..."},
  ];

  late List<Map<String, dynamic>> listOfAttendance = [];

  bool attendanceCorrector = true;
  int totalPresents = 0;
  int totalAbsents = 0;

  DateTime previousDate = DateTime.now();

  Future<void> getDataFromFirebase() async {
    EasyLoading.show(
      status: 'Loading...',
      indicator: CircularProgressIndicator(),
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );

    await attendanceNodeRef.once().then((var snapshots) {
      //here i iterate and create the list of objects
      Map<dynamic, dynamic>? attendanceRecords =
          snapshots.snapshot.value as Map?;
      attendanceRecords!.forEach((key, value) {
        setState(() {
          studentIdsFromRealTimeDB.add(int.parse(key));
        });
        //printing status
        print("Getting keys (ids) from RT: " + key);
      });
    });

    await _users
        .where('role', isEqualTo: 'student')
        .where('id', whereIn: studentIdsFromRealTimeDB)
        .get()
        .then((value) {
      value.docs.forEach((doc) {
        Map<String, dynamic> dataOfStudents =
            doc.data()! as Map<String, dynamic>;
        setState(() {
          listOfStudents.add(dataOfStudents);
        });
        print("(AttendanceDetails) Loaded Data of : " +
            dataOfStudents['full_name']);
      });
    });

    listOfStudents.forEach((element) async {
      //166931
      final DatabaseReference studentNodeRef =
          FirebaseDatabase.instance.ref("attendance/${element['id']}");
      // Get the data once
      await studentNodeRef
          .orderByValue()
          .limitToLast(1)
          .once()
          .then((var snapshots) {
        //here i iterate and create the list of objects
        Map<dynamic, dynamic>? attendanceRecords =
            snapshots.snapshot.value as Map?;
        attendanceRecords!.forEach((key, value) {
          String record = value;
          int datetimeInEpoch = int.tryParse(record.substring(11, 21)) as int;

          // print("datetimeInEpoch: " + datetimeInEpoch.toString());
          DateTime dateTime =
              DateTime.fromMillisecondsSinceEpoch(datetimeInEpoch * 1000)
                  .subtract(Duration(hours: 1));

          String formatTime = DateFormat('hh:mm a').format(dateTime);

          String formatDate = DateFormat('dd/MM/yyyy').format(dateTime);

          print("TIME: " + value.substring(29, 36));

          setState(() {
            listOfAttendance.add({
              'CheckIn':
                  '${value.substring(29, 36) == "checkin" ? '$formatTime' : '-'}',
              'CheckOut':
                  '${value.substring(29, 36) == "checkou" ? '$formatTime' : '-'}',
              'Date': '$formatDate',
            });
          });

          //printing timeStamp
          print(formatTime);
          //printing status
          print(value.substring(29, 36));
        });
      }).whenComplete(() => EasyLoading.dismiss());
    });
  }

  Future<void> getStudentRecord() async {

    bool isTwoTimes = false;

    EasyLoading.show(
      status: 'Loading...',
      indicator: CircularProgressIndicator(),
      dismissOnTap: false,
      maskType: EasyLoadingMaskType.black,
    );

    print(hiveUserId);

    if (Hive.box('loginCredentials').isOpen) {
      //166931
      final DatabaseReference studentNodeRef =
          FirebaseDatabase.instance.ref("attendance/${hiveUserId}");
      // Get the data once
      studentNodeRef.once().then((var snapshots) {
        //here i iterate and create the list of objects
        Map<dynamic, dynamic>? attendanceRecords =
            snapshots.snapshot.value as Map?;
        attendanceRecords!.forEach((key, value) {
          String record = value;

          int datetimeInEpoch = int.tryParse(record.substring(11, 21)) as int;
          print("datetimeInEpoch: " + datetimeInEpoch.toString());
          DateTime dateTime =
              DateTime.fromMillisecondsSinceEpoch(datetimeInEpoch * 1000)
                  .subtract(Duration(hours: 1));

          String formatTime = DateFormat('hh:mm a').format(dateTime);

          String formatDate = DateFormat('dd/MM/yyyy').format(dateTime);

          setState(() {
            attendanceCorrector
                ? listOfAttendance.add({
                    'CheckIn': '$formatTime',
                    'Date': '$formatDate',
                  })
                : listOfAttendance.add({
                    'CheckOut': '$formatTime',
                    'Date': '$formatDate',
                  });

            // Edit the timing conditions from there~~~~~~~~~~~~~~~~
            if (isAfter30Mints(
                currentTime: dateTime, previousTime: previousDate)) {
              setState(() {
                totalPresents += 1;
              });
            } else if (!isAfter30Mints(
                currentTime: dateTime, previousTime: previousDate)) {
              setState(() {
                if (isTwoTimes == true) {
                  totalAbsents += 1;
                }
                isTwoTimes = !isTwoTimes;
              });
            }
          });

          //printing timeStamp
          print(formatTime);
          //printing status for useless
          print(value.substring(29, 36));
          previousDate = dateTime;
          attendanceCorrector = !attendanceCorrector;
        });
      }).whenComplete(() => EasyLoading.dismiss());
    }
  }

  // bool isDayChanged({required DateTime dayBefore, required DateTime dayAfter}) {
  //   if (dayBefore.day < dayAfter.day)
  //     return true;
  //   else
  //     return false;
  // }

  bool isAfter30Mints(
      {required DateTime previousTime, required DateTime currentTime}) {
    if (currentTime.minute - previousTime.minute > 30)
      return true;
    else
      return false;
  }

  @override
  void initState() {
    super.initState();
    if (isStudent) {
      getStudentRecord();
    } else {
      getDataFromFirebase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        toolbarHeight: 120,
        backgroundColor: Colors.blue,
        title: Column(
          children: [
            const Text("Attendance Details"),
            Container(
              color: Colors.black45,
              height: 3,
              margin: const EdgeInsets.symmetric(vertical: 10),
            ),
            Text(widget.courseName),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "close ",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                      Icon(
                        FontAwesomeIcons.times,
                        color: Colors.red,
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                DataTable(
                  showBottomBorder: true,
                  sortColumnIndex: 0,
                  headingRowColor: MaterialStateProperty.resolveWith(
                    (Set<MaterialState> states) =>
                        Theme.of(context).primaryColor,
                  ),
                  columns: <DataColumn>[
                    DataColumn(
                      label: Text(
                        isStudent ? 'Date' : 'Name',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Check-In',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Check-Out',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          fontSize: textSize,
                        ),
                      ),
                    ),
                  ],

                  //Row Data~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  rows: isStudent
                      ? listOfAttendance // Loops through dataColumnText, each iteration assigning the value to element
                          .map(
                            (element) => DataRow(
                              cells: <DataCell>[
                                DataCell(Text(
                                  element["Date"] ?? '',
                                  style: TextStyle(
                                    fontSize: textSize,
                                  ),
                                )),
                                //Extracting from Map element the value
                                DataCell(Text(
                                  (element)["CheckIn"] ?? '',
                                  style: TextStyle(
                                    fontSize: textSize,
                                  ),
                                )),
                                DataCell(Text(
                                  (element)["CheckOut"] ?? '',
                                  style: TextStyle(
                                    fontSize: textSize,
                                  ),
                                )),
                              ],
                            ),
                          )
                          .toList()
                      : listOfStudents.length >= 0 &&
                              listOfStudents.isNotEmpty &&
                              listOfAttendance.length >= 0 &&
                              listOfAttendance.isNotEmpty
                          ? listOfStudents // Loops through dataColumnText, each iteration assigning the value to element
                              .map(
                                (element) => DataRow(
                                  cells: <DataCell>[
                                    DataCell(Text(
                                      element["full_name"] ?? '',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                    //Extracting from Map element the value
                                    DataCell(Text(
                                      listOfAttendance[listOfStudents
                                              .indexOf(element)]["CheckIn"] ??
                                          '-',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                    DataCell(Text(
                                      listOfAttendance[listOfStudents
                                              .indexOf(element)]["CheckOut"] ??
                                          '-',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                  ],
                                ),
                              )
                              .toList()
                          : tempList
                              .map(
                                (element) => DataRow(
                                  cells: <DataCell>[
                                    DataCell(Text(
                                      element["noArgs"] ?? '',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                    //Extracting from Map element the value
                                    DataCell(Text(
                                      element["noArgs"] ?? '',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                    DataCell(Text(
                                      element["noArgs"] ?? '',
                                      style: TextStyle(
                                        fontSize: textSize,
                                      ),
                                    )),
                                  ],
                                ),
                              )
                              .toList(),
                ),
                const SizedBox(
                  height: 20,
                ),

                //Total counter~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                isStudent
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Table(
                            border: TableBorder.all(color: Colors.black26),
                            defaultVerticalAlignment:
                                TableCellVerticalAlignment.middle,
                            columnWidths: const <int, TableColumnWidth>{
                              0: IntrinsicColumnWidth(),
                              1: IntrinsicColumnWidth(),
                            },
                            children: <TableRow>[
                              TableRow(
                                children: <Widget>[
                                  Container(
                                    height: 32,
                                    width: 120,
                                    color: Colors.green,
                                    child: const Center(
                                      child: Text(
                                        'Total Presents: ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    child: Center(
                                      child: Text(
                                        '$totalPresents',
                                        style: TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: <Widget>[
                                  Container(
                                    height: 32,
                                    width: 120,
                                    color: Colors.red,
                                    child: const Center(
                                      child: Text(
                                        'Total Absents: ',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 32,
                                    width: 32,
                                    // color: Colors.orange,
                                    child: Center(
                                      child: Text(
                                        '${totalAbsents}',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
