import 'dart:async';
import 'dart:ffi';

//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:time_range_picker/time_range_picker.dart';
import 'package:volunteer_connection/src/forum.dart';
import 'package:volunteer_connection/src/forum_detail.dart';
import '../firebase_options.dart';
import 'authentication.dart';
import 'tutor.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get loginState => _loginState;

  String? _email;
  String? get email => _email;

  int _pageIndex = 0;
  int get pageIndex => _pageIndex;

  Future<FutureOr<void>> addMyTutorSlot(TutorSlot slot) async {
    myTutorSlots.add(slot);

    if (_loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in');
    }

    var ref = await FirebaseFirestore.instance
        .collection('tutorTable')
        .add(<String, dynamic>{
      'tutorId': slot.tutorId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'subject': slot.subject,
      'date': slot.date.microsecondsSinceEpoch,
      'start':
          slot.timeRange.startTime.hour * 60 + slot.timeRange.startTime.minute,
      'end': slot.timeRange.endTime.hour * 60 + slot.timeRange.endTime.minute,
      'studentId': slot.studentId,
    });

    slot.doc = ref;
  }

  Future<FutureOr<void>> removeMyTutorSlot(TutorSlot slot) async {
    await slot.doc?.delete();
    myTutorSlots.remove(slot);
  }

  List<TutorSlot> myTutorSlots = [];

  FutureOr<void> reserveTutorSlot(String user, TutorSlot slot) {
    slot.setStudentId(user);
    reserveTutorSlots.add(slot);
    slot.doc?.update({"studentId": user});
  }
}