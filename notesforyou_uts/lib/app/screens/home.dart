import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:new_version/new_version.dart';
import 'package:note_app/app/screens/read_notes_screens.dart';
import 'package:note_app/app/screens/settings_screen.dart';
import 'package:note_app/const_values.dart';
import 'package:note_app/models/note_model.dart';
import 'package:note_app/providers/change_view_style_provider.dart';
import 'package:note_app/providers/theme_provider.dart';
import 'package:note_app/utils/slide_transition.dart';
import 'package:provider/provider.dart';

import 'create_note_screen.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Box<NoteModel>? storeData;
  Box<NoteModel>? deletedData;

  @override
  void initState() {
    super.initState();
    storeData = Hive.box<NoteModel>(noteBox);
    deletedData = Hive.box<NoteModel>(deletedNotes);
    _checkVersion();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkVersion() async {
    final newVersion = NewVersion(
      androidId: 'com.viewus.v_notes',
    );
    final status = await newVersion.getVersionStatus();
    if (status!.canUpdate) {
      newVersion.showUpdateDialog(
          context: context,
          versionStatus: status,
          dialogTitle: 'Update Notes',
          dialogText: 'Ada update baru untuk Notes, '
              'apakah anda mau melihat'
              'apa yang kami tingkatkan pada update ini',
          dismissAction: () {
            SystemNavigator.pop();
          },
          updateButtonText: 'Update sekarang',
          dismissButtonText: 'Tutup');
    }
  }

  void deleteDialog(key, NoteModel note, noteDate) {
    showDialog(
      context: context,
      builder: (_) {
        return Platform.isAndroid
            ? AlertDialog(
                title: const Text('Warning'),
                content:
                    const Text('Apakah kamu yakin ingin menghapus notes ini?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'No',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      NoteModel noteToDelete = NoteModel(
                        title: note.title,
                        notes: note.notes,
                        dateTime: noteDate,
                      );
                      deletedData!.add(noteToDelete);
                      storeData!.delete(key);
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    child: const Text(
                      'Yes',
                    ),
                  ),
                ],
              )
            : CupertinoAlertDialog(
                title: const Text('Warning'),
                content:
                    const Text('Apakah kamu yakin ingin menghapus notes ini?'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'No',
                      style: TextStyle(),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      storeData!.delete(key);
                      Navigator.of(context).pop();
                      setState(() {});
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(),
                    ),
                  ),
                ],
              );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checkTheme = Provider.of<ThemeProvider>(context);
    final homeViewStyle = Provider.of<ChangeViewStyleProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          if (Platform.isIOS)
            IconButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MySlide(builder: (_) {
                  return const CreateNoteScreen();
                }));
              },
              icon: const Icon(
                CupertinoIcons.add_circled,
              ),
            ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) {
                return const SettingsScreen();
              }));
            },
            icon: const Icon(
              Icons.settings,
            ),
          ),
          IconButton(
            onPressed: () {
              homeViewStyle.checkButtonState();
            },
            icon: Icon(
              homeViewStyle.mChangeViewStyle == false
                  ? Icons.list
                  : Icons.grid_view_outlined,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Platform.isAndroid
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MySlide(builder: (_) {
                  return const CreateNoteScreen();
                }));
              },
              backgroundColor: backColor,
              tooltip: 'Add Note',
              child: const Icon(
                Icons.add,
                color: defaultBlack,
              ),
            )
          : null,
      body: storeData!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Tidak ada catatan... \n(Tekan tombol dibawah ini untuk menambah notes)',
                    style: TextStyle(
                      fontSize: 18.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Icon(
                    Icons.arrow_downward_sharp,
                    size: 60,
                  )
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ValueListenableBuilder(
                  valueListenable: storeData!.listenable(),
                  builder: (context, Box<NoteModel> notes, _) {
                    List<int>? keys = notes.keys.cast<int>().toList();
                    return homeViewStyle.mChangeViewStyle == false
                        ? MasonryGridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            primary: false,
                            shrinkWrap: true,
                            mainAxisSpacing: 8.0,
                            crossAxisSpacing: 8.0,
                            addRepaintBoundaries: true,
                            itemCount: keys.length,
                            gridDelegate:
                                const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            itemBuilder: (_, index) {
                              final key = keys[index];
                              final NoteModel? note = notes.get(key);
                              DateTime convertedDate =
                                  DateTime.parse(note!.dateTime ?? '');
                              var noteDate = DateFormat.yMMMd()
                                  .add_jm()
                                  .format(convertedDate);
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MySlide(builder: (_) {
                                    return ReadNotesScreen(
                                      note: note,
                                      noteKey: key,
                                    );
                                  }));
                                },
                                onLongPress: () {
                                  deleteDialog(key, note, noteDate);
                                },
                                child: note.title == null
                                    ? Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.white38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10.0))),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            '${note.notes}',
                                            style: const TextStyle(),
                                            softWrap: true,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                            color: Colors.white38,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10.0))),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                decoration: BoxDecoration(
                                                  color:
                                                      checkTheme.mTheme == false
                                                          ? backColor
                                                          : Colors.grey[900],
                                                ),
                                                child: Text(
                                                  note.title == null ||
                                                          note.title == ''
                                                      ? 'No Title'
                                                      : '${note.title}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  softWrap: true,
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              Flexible(
                                                fit: FlexFit.loose,
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      '${note.notes!.length >= 70 ? note.notes!.substring(0, 70) + '...' : note.notes}',
                                                      style: const TextStyle(),
                                                      softWrap: true,
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    Text(
                                                      noteDate,
                                                      style: const TextStyle(
                                                        color: Colors.grey,
                                                        fontSize: 14,
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            primary: false,
                            shrinkWrap: true,
                            itemCount: keys.length,
                            itemBuilder: (context, index) {
                              final key = keys[index];
                              final NoteModel? note = notes.get(key);
                              // DateFormat mFormat = DateFormat.yMMMd().add_jm();
                              DateTime convertedDate =
                                  DateTime.parse('${note!.dateTime}');
                              var noteDate = DateFormat.yMMMd()
                                  .add_jm()
                                  .format(convertedDate);
                              return GestureDetector(
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MySlide(builder: (_) {
                                    return ReadNotesScreen(
                                      note: note,
                                      noteKey: key,
                                    );
                                  }));
                                },
                                onLongPress: () {
                                  deleteDialog(key, note, noteDate);
                                },
                                child: note.title == null
                                    ? Column(
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white38,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10.0),
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                '${note.notes}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 7,
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white38,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(10.0),
                                              ),
                                            ),
                                            child: ListTile(
                                              title: Text(
                                                note.title == null ||
                                                        note.title == ''
                                                    ? 'No Title'
                                                    : '${note.title}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${note.notes!.length >= 70 ? note.notes!.substring(0, 70) + '...' : note.notes}',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Text(
                                                    noteDate,
                                                    style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 14,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 7,
                                          ),
                                        ],
                                      ),
                              );
                            },
                          );
                  },
                ),
              ),
            ),
    );
  }
}
