import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:intl/intl.dart';

import 'widgets.dart';

class TutorSlot {
  final String tutorId;
  final String subject;
  final DateTime date;
  final TimeRange timeRange;
  String? studentId;
  DocumentReference? doc;

  TutorSlot(this.tutorId, this.subject, this.date, this.timeRange,
      this.studentId, this.doc);

  void setStudentId(String? studentId) {
    studentId = studentId;
  }
}

class Tutor extends StatefulWidget {
  final String user;
  final FutureOr<void> Function(TutorSlot slot) addMyTutorSlot;
  final FutureOr<void> Function(TutorSlot slot) removeMyTutorSlot;
  final List<TutorSlot> myTutorSlots;
  final List<TutorSlot> Function(String subject, DateTime date) searchTutorSlot;
  List<TutorSlot> searchTutorSlots;
  final FutureOr<void> Function(String user, TutorSlot slot) reserveTutorSlot;
  final FutureOr<void> Function(TutorSlot slot) removeReservationTutorSlot;
  final List<TutorSlot> reserveTutorSlots;

  Tutor(
      {required this.user,
      required this.addMyTutorSlot,
      required this.removeMyTutorSlot,
      required this.myTutorSlots,
      required this.searchTutorSlot,
      required this.searchTutorSlots,
      required this.reserveTutorSlot,
      required this.removeReservationTutorSlot,
      required this.reserveTutorSlots});

  @override
  _TutorState createState() => _TutorState();
}

class _TutorState extends State<Tutor> {
  final DateFormat formatter = DateFormat('yyyy-MM-dd');

  String subjectToAdd = "Calculus";
  DateTime selectedDate = DateTime.now();
  TimeRange timeRange = TimeRange(
      startTime: TimeOfDay(hour: 18, minute: 0),
      endTime: TimeOfDay(hour: 19, minute: 0));

  String subjectToSearch = "Calculus";
  DateTime searchDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Add tutor session:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      getAddSlotWidget(context),
      const SizedBox(height: 8),
      Text("Tutoring sessions that I offers:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columns: createTutorSlotTableHeader,
                  rows: createMyTutorSlotTableRows()))),
      const SizedBox(height: 8),
      Text("Search:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      getSearchSlotsWidget(context),
      SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columns: createSearchTutorSlotTableHeader,
                  rows: createSearchTutorSlotTableRows()))),
      const SizedBox(height: 8),
      Text("Tutoring sessions that I signed up:",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                  columns: createReserveTutorSlotTableHeader,
                  rows: createReserveTutorSlotTableRows()))),
    ]);
  }

  Row getAddSlotWidget(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: subjectToAdd,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String? newValue) {
            setState(() {
              subjectToAdd = newValue!;
            });
          },
          items: <String>['Calculus', 'English', 'Physics', 'Computer']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        ElevatedButton(
            onPressed: () => _selectDate(context),
            child: Icon(Icons.date_range),
            style: ElevatedButton.styleFrom(shape: CircleBorder())),
        ElevatedButton(
          onPressed: () => _selectTimeRange(context),
          child: Icon(Icons.lock_clock),
          style: ElevatedButton.styleFrom(shape: CircleBorder()),
        ),
        ElevatedButton(
          onPressed: addSlot,
          child: Text("Add"),
        ),
      ],
    );
  }

  Row getSearchSlotsWidget(BuildContext context) {
    return Row(
      children: [
        DropdownButton<String>(
          value: subjectToSearch,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String? newValue) {
            setState(() {
              subjectToSearch = newValue!;
            });
          },
          items: <String>['Calculus', 'English', 'Physics', 'Computer']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        ElevatedButton(
            onPressed: () => _selectSearchDate(context),
            child: Icon(Icons.date_range),
            style: ElevatedButton.styleFrom(shape: CircleBorder())),
        ElevatedButton(
          onPressed: searchSlots,
          child: Text("Search"),
        ),
      ],
    );
  }

  List<DataRow> createMyTutorSlotTableRows() {
    return widget()
        .myTutorSlots
        .map((mySlot) => DataRow(cells: [
              DataCell(ElevatedButton(
                onPressed: () {
                  widget().removeMyTutorSlot(mySlot);
                  setState(() => {});
                },
                child: Icon(Icons.remove),
                style: ElevatedButton.styleFrom(shape: CircleBorder()),
              )),
              DataCell(Text(mySlot.subject)),
              DataCell(Text(formatter.format(mySlot.date))),
              DataCell(Text(mySlot.timeRange.startTime.hour
                      .toString()
                      .padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.startTime.minute.toString().padLeft(2, '0') +
                  '-' +
                  mySlot.timeRange.endTime.hour.toString().padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.endTime.minute.toString().padLeft(2, '0'))),
              DataCell(Text(mySlot.studentId ?? ""))
            ]))
        .toList();
  }

  List<DataRow> createSearchTutorSlotTableRows() {
    return widget()
        .searchTutorSlots
        .map((mySlot) => DataRow(cells: [
              DataCell(ElevatedButton(
                onPressed: () {
                  widget().reserveTutorSlot(widget().user, mySlot);
                  widget().searchTutorSlots.remove(mySlot);
                  setState(() => {});
                },
                child: Icon(Icons.assignment),
                style: ElevatedButton.styleFrom(shape: CircleBorder()),
              )),
              DataCell(Text(mySlot.subject)),
              DataCell(Text(mySlot.tutorId ?? "")),
              DataCell(Text(formatter.format(mySlot.date))),
              DataCell(Text(mySlot.timeRange.startTime.hour
                      .toString()
                      .padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.startTime.minute.toString().padLeft(2, '0') +
                  '-' +
                  mySlot.timeRange.endTime.hour.toString().padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.endTime.minute.toString().padLeft(2, '0'))),
            ]))
        .toList();
  }

  List<DataRow> createReserveTutorSlotTableRows() {
    return widget()
        .reserveTutorSlots
        .map((mySlot) => DataRow(cells: [
              DataCell(
                ElevatedButton(
                  onPressed: () {
                    widget().removeReservationTutorSlot(mySlot);
                    widget().reserveTutorSlots.remove(mySlot);
                    setState(() => {});
                  },
                  child: Icon(Icons.remove),
                  style: ElevatedButton.styleFrom(shape: CircleBorder()),
                ),
              ),
              DataCell(Text(mySlot.subject)),
              DataCell(Text(mySlot.tutorId ?? "")),
              DataCell(Text(formatter.format(mySlot.date))),
              DataCell(Text(mySlot.timeRange.startTime.hour
                      .toString()
                      .padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.startTime.minute.toString().padLeft(2, '0') +
                  '-' +
                  mySlot.timeRange.endTime.hour.toString().padLeft(2, '0') +
                  ':' +
                  mySlot.timeRange.endTime.minute.toString().padLeft(2, '0'))),
            ]))
        .toList();
  }

  List<DataColumn> get createTutorSlotTableHeader {
    return [
      DataColumn(
          label: Text('Remove',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Subject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Assigned',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
    ];
  }

  List<DataColumn> get createSearchTutorSlotTableHeader {
    return [
      DataColumn(
          label: Text('Reserve',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Subject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Tutor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
    ];
  }

  List<DataColumn> get createReserveTutorSlotTableHeader {
    return [
      DataColumn(
          label: Text('Remove',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Subject',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Tutor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
      DataColumn(
          label: Text('Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
    ];
  }

  void addSlot() {
    widget().addMyTutorSlot(TutorSlot(
        widget().user, subjectToAdd, selectedDate, timeRange, null, null));
    setState(() {});
  }

  _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  _selectSearchDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: searchDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        searchDate = picked;
      });
    }
  }

  _selectTimeRange(BuildContext context) async {
    final TimeRange? picked = await showTimeRangePicker(
      context: context,
      ticks: 15,
      start: timeRange.startTime,
      end: timeRange.endTime,
    );
    if (picked != null) {
      setState(() {
        timeRange = picked;
      });
    }
  }

  DateTimeRange getTimeSlot(DateTime date, TimeRange timeRange) {
    return DateTimeRange(
      start: DateTime(date.year, date.month, date.day, timeRange.startTime.hour,
          timeRange.startTime.minute),
      end: DateTime(date.year, date.month, date.day, timeRange.endTime.hour,
          timeRange.endTime.minute),
    );
  }

  Future<void> searchSlots() async {
    widget().searchTutorSlots =
        widget().searchTutorSlot(subjectToSearch, searchDate);
    setState(() {});
  }
}