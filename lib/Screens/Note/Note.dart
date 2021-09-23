import 'package:flutter/material.dart';
import 'NoteDetail.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../Services/NoteService.dart';
import '../Setting.dart';
import '../../Observables/NoteObservable.dart';
import '../../Utility/Constant.dart';
import 'SaveNote.dart';
import '../../Model/Note.dart';
import '../NoteID.dart' as ID;

final viewNotesScaffoldKey = GlobalKey<ScaffoldState>();
/// View Notes page
class ViewNotes extends StatefulWidget {

  @override
  _ViewNotesState createState() => _ViewNotesState();
}

class _ViewNotesState extends State<ViewNotes> {

  NoteScreenNav screenNav = NoteScreenNav();

  _ViewNotesState(){
    screenNav.changeScreen(SCREEN_NAMES.NOTE);
  }
  
  
  // flag to control whether or not results are read
  bool readResults = false;

  // flag to indicate a voice search
  bool voiceSearch = false;

  // Search bar to insert in the app bar header
  late SearchBar searchBar;

  // voice helper service

  /// Value of search filter to be used in filtering search results
  String searchFilter = "";

  /// Search is submitted from search bar
  onSubmitted(value) {
    if (voiceSearch) {
      voiceSearch = false;
      readResults = true;
    }
    searchFilter = value;
    setState(() => viewNotesScaffoldKey.currentState);
  }

  // Search has been cleared from search bar
  onCleared() {
    searchFilter = "";
  }

 

  // text to speech
  FlutterTts flutterTts = FlutterTts();

  /// Text note service to use for I/O operations against local system
  TextNoteService textNoteService = new TextNoteService();

  void voiceHandler(Map<String, dynamic> inference) {
    if (inference['isUnderstood']) {
      if (inference['intent'] == 'searchNotes') {
        print('Searching for: ' + inference['slots']['date']);
        voiceSearch = true;
        onSubmitted(inference['slots']['date'].toString());
      }
      if (inference['intent'] == 'startTranscription') {
        print('start recording');
        Navigator.pushNamed(context, '/record-notes');
      }
      if (inference['intent'] == 'searchDetails') {
        print('Searching for personal detail');
        Navigator.pushNamed(context, '/view-details');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Sorry, I did not understand'),
          backgroundColor: Colors.deepOrange,
          duration: const Duration(seconds: 1)));
    }
  }

  Future readFilterResults() async {
    List<dynamic> textNotes = [];//await textNoteService.getTextFileList(searchFilter);
    if (textNotes.isNotEmpty) {
      if (readResults) {
        for (TextNote note in textNotes) {
          readResults = false;
          await flutterTts.speak("Your reminders for " +
              searchFilter +
              " are: " +
              note.text.toString());
        }
      }
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Observer( builder: (_) =>
      Container(
       child: (screenNav.currentScreen == SCREEN_NAMES.NOTE) ?
          FutureBuilder<List<dynamic>>(
          //future: textNoteService.getTextFileList(searchFilter),
          builder: (context, AsyncSnapshot<List<dynamic>> textNotes) {
            if (textNotes.hasData) {
              readFilterResults();
              return Scaffold(
                //appBar: buildAppBar(context),
                key: viewNotesScaffoldKey,
                body: Column(children: [

                  Expanded(child:
                  Container(
                    padding: EdgeInsets.all(10),
                    child: SingleChildScrollView(
                      child: textNotes.data == null ||
                          textNotes.data?.length == 0
                      // No text notes found, tell user
                          ? Text(
                          "Uh-oh! It looks like you don't have any text notes saved. Try saving some notes first and come back here.",
                          style: TextStyle(
                            fontSize: 20,
                          ))
                          : Table(
                          border: TableBorder.all(),
                          columnWidths: const <int, TableColumnWidth>{
                            0: FlexColumnWidth(.45),
                            1: FlexColumnWidth(),
                            2: FlexColumnWidth()
                          },
                          defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                          children: <TableRow>[
                            TableRow(
                                decoration: const BoxDecoration(
                                    color: Colors.blueGrey),
                                children: <Widget>[
                                  TableCell(
                                    verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                    child: Container(
                                        padding: EdgeInsets.all(10),
                                        child: Text('ID',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.white))),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                    child: Container(
                                        padding: EdgeInsets.all(10),
                                        child: Text('DATE',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.white))),
                                  ),
                                  TableCell(
                                    verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                    child: Container(
                                        padding: EdgeInsets.all(10),
                                        child: Text('NOTE',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: Colors.white))),
                                  ),
                                ]),
                            //not sure how to pass the correct element
                            for (var textNote in textNotes.data ?? [])
                              TableRow(children: <Widget>[
                                TableCell(
                                  verticalAlignment:
                                  TableCellVerticalAlignment.top,
                                  child: Container(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                          ID.main(),
                                          style: TextStyle(fontSize: 20))),
                                ),
                                TableCell(
                                  verticalAlignment:
                                  TableCellVerticalAlignment.top,
                                  child: Container(
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                          timeago.format(textNote.dateTime),
                                          style: TextStyle(fontSize: 20))),
                                ),
                                TableCell(
                                    verticalAlignment:
                                    TableCellVerticalAlignment.top,
                                    // text button used to test exact solution from
                                    // https://flutter.dev/docs/cookbook/navigation/navigate-with-arguments
                                    // - Alec

                                    /*   child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/save-note');
                                        },

                                            */
                                    child: TextButton(
                                      onPressed: () {
                                        // When the user taps the button,
                                        // navigate to a named route and
                                        // provide the arguments as an optional
                                        // parameter.
                                        Navigator.pushNamed(
                                          context,
                                          NoteDetails.routeName,
                                          arguments: textNote?.fileName ?? "",
                                        );
                                      },
                                      child: Container(
                                          padding: EdgeInsets.all(10),
                                          child: Text(textNote.text,
                                              style: TextStyle(
                                                fontSize: 20,
                                              ))),
                                    )),
                              ]),
                          ]),
                      // Add table rows for each text note
                    ),
                  ))
                ]),
                floatingActionButton: FloatingActionButton(

                  onPressed: () {
                    screenNav.changeScreen(SCREEN_NAMES.SAVE_NOTE);
                  },
                  tooltip: 'Save Note',
                  child: Icon(Icons.add),
                ),
              );
            } else {
              return CircularProgressIndicator();
            }
          })
        : (screenNav.currentScreen == SCREEN_NAMES.SAVE_NOTE)?
            SaveNote(screenNav)
        :  NoteDetails()
      )
    );
  }
}
