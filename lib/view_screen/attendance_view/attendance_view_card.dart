import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

import 'attendance_details.dart';


class AttendanceViewCard extends StatelessWidget {
  final String courseName, courseDay, courseTime;
  final int courseId;
  final GestureTapCallback onPressed;

  const AttendanceViewCard(
      {Key? key,
      required this.courseName,
      required this.courseDay,
      required this.courseId,
      required this.courseTime,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        splashColor: Theme.of(context).primaryColor,
        onTap: onPressed,
        child: OpenContainer(
            transitionType: ContainerTransitionType.fadeThrough,
            closedColor: Theme.of(context).cardColor,
            closedElevation: 0.0,
            openElevation: 4.0,
            transitionDuration: const Duration(milliseconds: 1500),
            openBuilder: (BuildContext context, VoidCallback _) =>
                AttendanceDetails(courseName: courseName, courseId: courseId.toString(), courseTime: courseTime,),
            closedBuilder: (BuildContext _, VoidCallback openContainer) {
              return ListTile(
                title: Text(courseId.toString() + ' - ' +courseName),
                subtitle: Text(courseDay + ' ( ' + courseTime + ' ) '),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
              );
            }),
      ),
    );
  }
}
