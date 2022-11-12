import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:volunteer_connection/src/tutor.dart';

import 'src/application_state.dart';
import 'src/authentication.dart';
import 'src/widgets.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ApplicationState(),
      builder: (context, _) => App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  //This widget is the root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tutor Matching',
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        
      },
    );
  }
}

//Home page of application
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor Matching'),
      ),
      body: Consumer<ApplicationState>(
        builder: getPageBody,
      ),
      bottomNavigationBar: Consumer<ApplicationState>(
        builder: (context, appState, _) => BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            //Home page
            BottomNavigationBarItem( 
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Colors.deepOrange),
            //Tutor page
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Tutor',
              backgroundColor: Colors.purple,
            ),
          ],
          currentIndex: appState.pageIndex,
          selectedItemColor: Colors.amber[800],
          onTap: (index) => appState.updatePageIndex(index),
        ),
      ),
    );
  }

  Widget getPageBody(BuildContext context, ApplicationState appState, _) {
    if (appState.pageIndex == 0) {
      return ListView(
        children: <Widget>[
          Image.asset('assets/help_hands.jpeg'),
          const SizedBox(height: 8),
          Authentication(
            email: appState.email,
            loginState: appState.loginState,
            startLoginFlow: appState.startLoginFlow,
            verifyEmail: appState.verifyEmail,
            signInWithEmailAndPassword: appState.signInWithEmailAndPassword,
            cancelRegistration: appState.cancelRegistration,
            registerAccount: appState.registerAccount,
            signOut: appState.signOut,
          ), //Authentication for user
          const Divider(
            height: 8,
            thickness: 1,
            indent: 8,
            endIndent: 8,
            color: Colors.grey,
          ), 
          const Header("Connecting tutors and tutees"),
          const Paragraph(
            'Quick and easy matchups based on subject and availability',
          ),
        ],
      );
    } else if (appState.pageIndex == 1) {
      if (appState.email == null) {
        return Paragraph('Please sign in first'); 
      }
      return ListView(children: <Widget>[
        Image.asset('assets/tutor.png'),
        const SizedBox(height: 8),
        Tutor(F
            user: appState.email ?? "",
            addMyTutorSlot: appState.addMyTutorSlot,
            removeMyTutorSlot: appState.removeMyTutorSlot,
            myTutorSlots: appState.myTutorSlots,
            searchTutorSlot: appState.searchTutorSlot,
            searchTutorSlots: [],
            reserveTutorSlot: appState.reserveTutorSlot,
            removeReservationTutorSlot: appState.removeReservationTutorSlot,
            reserveTutorSlots: appState.reserveTutorSlots),
      ]);
    } 
  }
}
