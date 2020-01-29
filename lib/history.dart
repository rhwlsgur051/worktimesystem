import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      child: Scaffold(
          appBar: AppBar(
            title: Text('WorkTime History'),
            backgroundColor: Color.fromARGB(255, 8, 68, 123),
          ),
          body: FutureBuilder(
              future: getData(),
              builder: (BuildContext context, AsyncSnapshot data) {
                if (data.data == null) {
                  return Container();
                }
              })),
    );
  }

  getData() async {
    SharedPreferences history = await SharedPreferences.getInstance();
    print(history.getString('timeHouse'));
    
    return null;
  }
}
