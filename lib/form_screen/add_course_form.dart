import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';

class AddCourseForm extends StatefulWidget {
  final String courseId;

  const AddCourseForm({Key? key, required this.courseId}) : super(key: key);

  @override
  State<AddCourseForm> createState() => _AddCourseFormState();
}

class _AddCourseFormState extends State<AddCourseForm> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final _nameTextController = TextEditingController();

  // Create a CollectionReference called users that references the firestore collection
  final CollectionReference _course =
      FirebaseFirestore.instance.collection('courses');
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 3,minutes: 30)));

  String _courseDay = 'Monday';

  String _courseStartTime = '';
  String _courseEndTime = '';

  String _courseTerm = 'Summer 2022';

  int _generatedId = Random().nextInt(99) + 105400;

  var _courseName = '';

  void _trySubmit() {
    final isValid = _formKey.currentState!.validate();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    FocusScope.of(context).unfocus();
    _formKey.currentState!.reset();

    //Update record~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (widget.courseId != '' || !widget.courseId.isEmpty) {
      _course.doc("${widget.courseId}").update({
        'course_name': _courseName,
        'course_day': _courseDay,
        'course_start_time': startTime.format(context).toString(),
        'course_end_time': endTime.format(context).toString(),
        'course_term': _courseTerm,
      }).then((value) {
        print("Course Added");
        EasyLoading.showSuccess('Course updated');
        _nameTextController.text="";
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }).catchError((error) {
        print("Failed to add user: $error");
        EasyLoading.showSuccess('Failed to update record');
      });
    }
    //Add record~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (isValid && widget.courseId == '') {
      _course.doc("$_generatedId").set({
        'id': _generatedId,
        'course_name': _courseName,
        'course_day': _courseDay,
        'course_start_time': startTime.format(context).toString(),
        'course_end_time': endTime.format(context).toString(),
        'course_term': _courseTerm,
      }).then((value) {
        print("Course Added");
        EasyLoading.showSuccess('Course saved');
        _generatedId = Random().nextInt(99) + 105400;
      }).catchError((error) {
        print("Failed to add user: $error");
        EasyLoading.showSuccess('Failed to saved record');
      });
    }
  }

  @override
  void initState() {

    //if updating course~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if (widget.courseId != '' || !widget.courseId.isEmpty) {
      super.initState();
      EasyLoading.show(
        status: 'Loading...',
        indicator: CircularProgressIndicator(),
        dismissOnTap: false,
        maskType: EasyLoadingMaskType.black,
      );

      _course.doc('${widget.courseId}').get().then((value) {
        Map<String, dynamic> data = value.data()! as Map<String, dynamic>;
        setState(() {
          _nameTextController.text = data['course_name'];
          _courseDay = data['course_day'];
          _courseStartTime = data['course_start_time'];
          _courseEndTime = data['course_end_time'];
          _courseTerm = data['course_term'];
         
        });
      
  TimeOfDay stringToTimeOfDay(String tod) {
  final format = DateFormat.jm(); //"6:00 AM"
  return TimeOfDay.fromDateTime(format.parse(tod));
}
print(stringToTimeOfDay(_courseStartTime));
startTime = stringToTimeOfDay(_courseStartTime);
          endTime = stringToTimeOfDay(_courseEndTime);
        print(data['course_name']);
      }).whenComplete(() => EasyLoading.dismiss());
    }
  }
Future selectedTime(BuildContext context, bool ifPickedTime,
      TimeOfDay initialTime, Function(TimeOfDay) onTimePicked) async {
    var _pickedTime =
        await showTimePicker(context: context, initialTime: initialTime);
    if (_pickedTime != null) {
      onTimePicked(_pickedTime);
    }
  }
   Widget _buildTimePick(String title, bool ifPickedTime, TimeOfDay currentTime,
      Function(TimeOfDay) onTimePicked) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            title,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(20),
          ),
          child: GestureDetector(
            child: Text(
              currentTime.format(context),
            ),
            onTap: () {
              selectedTime(context, ifPickedTime, currentTime, onTimePicked);
            },
          ),
        ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),

                  widget.courseId == '' || widget.courseId.isEmpty
                      ? Container()
                      : Text('Updating ID: ' + widget.courseId),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Coure Name: "),
                      Container(
                        width: MediaQuery.of(context).size.width/2,
                        child: TextFormField(
                    controller: _nameTextController,
                    key: ValueKey('name'),
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'Course Name'),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                        value = value!.trim();
                        if (value.isEmpty) {
                          return 'Please enter a name.';
                        }
                        return null;
                    },
                    onSaved: (value) {
                        _courseName = value.toString().trim();
                    },
                  ),
                      ),
                 ],
                  ),

                  //Student Name~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                

                  const SizedBox(
                    height: 20,
                  ),

                  //Select Course~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Day: "),
                      Container(
                         width: MediaQuery.of(context).size.width/2,
                        child: DropdownButton<String>(
                          value: _courseDay,
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          
                          isExpanded: true,
                          // menuMaxHeight: 200,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(
                            height: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _courseDay = newValue!;
                            });
                          },
                          items: <String>[
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
const SizedBox(
                    height: 20,
                  ),
                  _buildTimePick("Start Time", true, startTime, (x) {
          setState(() {
            startTime = x;
            print("The picked time is: $x");
          });
        }),
        const SizedBox(height: 10),
        _buildTimePick("End Time", true, endTime, (x) {
          setState(() {
            endTime = x;
            print("The picked time is: $x");
          });
        }),
                  //Select Course~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     const Text("Select Time Slot: "),
                  //     Container(
                  //        width: MediaQuery.of(context).size.width/2,
                  //       child: DropdownButton<String>(
                  //         value: _courseTime,
                  //         icon: const Icon(Icons.arrow_downward),
                  //         iconSize: 24,
                  //         elevation: 16,
                          
                  //         isExpanded: true,
                  //         // menuMaxHeight: 200,
                  //         style: const TextStyle(color: Colors.black),
                  //         underline: Container(
                  //           height: 2,
                  //           color: Theme.of(context).primaryColor,
                  //         ),
                  //         onChanged: (String? newValue) {
                  //           setState(() {
                  //             _courseTime = newValue!;
                  //           });
                  //         },
                  //         items: <String>[
                  //           '8:40 AM - 11:40 AM',
                  //           '12:30 PM - 03:30 PM',
                  //         ].map<DropdownMenuItem<String>>((String value) {
                  //           return DropdownMenuItem<String>(
                  //             value: value,
                  //             child: Text(value),
                  //           );
                  //         }).toList(),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  const SizedBox(
                    height: 20,
                  ),
                  //Select Course~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Select Term: "),
                      Container(
                         width: MediaQuery.of(context).size.width/2,
                        child: DropdownButton<String>(
                          value: _courseTerm,
                          icon: const Icon(Icons.arrow_downward),
                          iconSize: 24,
                          elevation: 16,
                          isExpanded: true,
                          // menuMaxHeight: 200,
                          style: const TextStyle(color: Colors.black),
                          underline: Container(
                            height: 2,
                            color: Theme.of(context).primaryColor,
                          ),
                          onChanged: (String? newValue) {
                            setState(() {
                              _courseTerm = newValue!;
                            });
                          },
                          items: <String>[
                            'Spring 2022',
                            'Summer 2022',
                            'Fall 2022',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MaterialButton(
                        child: Container(
                          child: const Text(
                            "Save Course",
                            style: TextStyle(fontSize: 20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 20),
                        ),
                        onPressed: _trySubmit,
                        color: Theme.of(context).primaryColor,
                        textColor: Colors.white,
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
