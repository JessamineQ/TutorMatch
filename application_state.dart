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

 List<TutorSlot> reserveTutorSlots = [];

  StreamSubscription<QuerySnapshot>? _tutorSubscription;
  List<TutorSlot> _tutorSlots = [];
  List<TutorSlot> get tutorSlots => _tutorSlots;

  StreamSubscription<QuerySnapshot>? _forumSubscription;
  List<ForumEntry> forums = [];
  StreamSubscription<QuerySnapshot>? _forumPostSubscription;
  List<ForumPostEntry> _forumPosts = [];

  /**
   *         forums: appState.forums,
        getPosts: appState.getPosts,
        addPost: appState.addPost,
        updateForumView: appState.updateFormView,
   */
  FutureOr<void> updateFormView(ForumEntry forum) {
    forum.views = forum.views + 1;
    forum.doc?.update({"views": forum.views + 1});
  }

  List<ForumPostEntry> getPosts(String forumName) {
    List<ForumPostEntry> posts = [];
    for (var element in _forumPosts) {
      if (element.forum == forumName) {
        posts.add(element);
      }
    }
    return posts;
  }

  Future<FutureOr<void>> addPost(ForumPostEntry post) async {
    if (_loginState != ApplicationLoginState.loggedIn) {
      throw Exception('Must be logged in');
    }
    _forumPosts.add(post);

    var ref = await FirebaseFirestore.instance
        .collection('forumPostTable')
        .add(<String, dynamic>{
      'forum': post.forum,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'message': post.text,
      'user': post.username,
    });

    post.doc = ref;
  }

  Future<FutureOr<void>> addForum(ForumEntry forum) async {
    forums.add(forum);

    var ref = await FirebaseFirestore.instance
        .collection('forumTable')
        .add(<String, dynamic>{
      'title': forum.title,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'description': forum.description,
      'icon': forum.icon,
      'views': forum.views,
      'responses': forum.responses,
    });

    forum.doc = ref;
  }

  ApplicationState() {
    init();
  }

  Future<void> init() async {
    _loginState = ApplicationLoginState.loggedOut;
    //_email = null;
    _tutorSlots = [];
    reserveTutorSlots = [];
    myTutorSlots = [];

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseAuth.instance.userChanges().listen((user) {
      if (user != null) {
        _loginState = ApplicationLoginState.loggedIn;
        _email = user.email;

        setupTutorSubscription(user);
        setupForumSubscriptions();
      } else {
        _loginState = ApplicationLoginState.loggedOut;

        _tutorSlots = [];
        _tutorSubscription?.cancel();
      }
      notifyListeners();
    });
  }

  void setupForumSubscriptions() {
    _tutorSubscription = FirebaseFirestore.instance
        .collection('forumTable')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      forums = [];
      for (final document in snapshot.docs) {
        var forum = ForumEntry(
          //title, icon, description, views, responses
          document.data()['title'] as String,
          document.data()['icon'] as String,
          document.data()['description'] as String,
          document.data()['views'] as int,
          document.data()['responses'] as int,
        );

        forums.add(forum);
      }

      if (forums.isEmpty) {
        addForum(
            ForumEntry("Volunteer", "test", "Voluteer oppotunities", 0, 0));
        addForum(ForumEntry(
            "Health", "test", "Physical and phychological health", 0, 0));
        addForum(ForumEntry("Campus life", "test", "All things campus", 0, 0));
        addForum(ForumEntry("Others", "test", "Any discussion", 0, 0));
      }
    });
  }
void setupTutorSubscription(User user) {
    _tutorSubscription = FirebaseFirestore.instance
        .collection('tutorTable')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      _tutorSlots = [];
      reserveTutorSlots = [];
      myTutorSlots = [];
      for (final document in snapshot.docs) {
        var tutorSlot = TutorSlot(
            document.data()['tutorId'] as String,
            document.data()['subject'] as String,
            DateTime.fromMicrosecondsSinceEpoch(document.data()['date']),
            TimeRange(
              startTime: TimeOfDay(
                  hour: (document.data()['start'] / 60).toInt(),
                  minute: (document.data()['start'] % 60).toInt()),
              endTime: TimeOfDay(
                  hour: (document.data()['end'] / 60).toInt(),
                  minute: (document.data()['end'] % 60).toInt()),
            ),
            (document.data()['studentId'] as String?) ?? "",
            document.reference);
        _tutorSlots.add(
          tutorSlot,
        );

        if (tutorSlot.tutorId == user.email &&
            user.email != null &&
            user.email != "") {
          myTutorSlots.add(tutorSlot);
        }

        if (tutorSlot.studentId == user.email &&
            user.email != null &&
            user.email != "") {
          reserveTutorSlots.add(tutorSlot);
        }
      }

      notifyListeners();
    });
  }

  void startLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> verifyEmail(
    String email,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      var methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.contains('password')) {
        _loginState = ApplicationLoginState.password;
      } else {
        _loginState = ApplicationLoginState.register;
      }
      _email = email;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    void Function(FirebaseAuthException e) errorCallback,
  ) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void cancelRegistration() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  Future<void> registerAccount(
      String email,
      String displayName,
      String password,
      void Function(FirebaseAuthException e) errorCallback) async {
    try {
      var credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await credential.user!.updateDisplayName(displayName);
    } on FirebaseAuthException catch (e) {
      errorCallback(e);
    }
  }

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  void updatePageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }

  List<TutorSlot> searchTutorSlot(String subject, DateTime date) {
    List<TutorSlot> searchSlots = [];
    for (var slot in _tutorSlots) {
      if (slot.subject == subject && slot.date.day == date.day) {
        searchSlots.add(slot);
      }
    }
    return searchSlots;
  }

  FutureOr<void> removeReservationTutorSlot(TutorSlot slot) {
    slot.setStudentId(null);
    reserveTutorSlots.add(slot);
    slot.doc?.update({"studentId": null});
  }
}
