import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Lists',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'My Lists'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List _listTasks = [];
  Map<String, dynamic> _lastRemoved;
  int _lastPos;
  final TextEditingController _newTasksCtrl = TextEditingController();

  // ! Toda vez em que a aplicação iniciar
  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _listTasks = json.decode(data);
      });
    });
  }

  Future<File> _getFile() async {
    final _directory = await getApplicationDocumentsDirectory();
    return File("${_directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String _data = json.encode(_listTasks);
    final _file = await _getFile();
    return _file.writeAsString(_data);
  }

  Future<String> _readData() async {
    try {
      final _file = await _getFile();
      return _file.readAsString();
    } catch (_e) {
      return null;
    }
  }

  void _addList() {
    if (_newTasksCtrl.text.isNotEmpty) {
      setState(() {
        Map<String, dynamic> _newTask = Map();
        _newTask['title'] = _newTasksCtrl.text;
        _newTasksCtrl.clear();
        _newTask['done'] = false;
        _listTasks.add(_newTask);
      });
      _saveData();
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_listTasks[index]['title']),
        value: _listTasks[index]['done'],
        secondary: CircleAvatar(
          child: Icon(
            _listTasks[index]['done'] ? Icons.check : Icons.error,
            color: Colors.white,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _listTasks[index]['done'] = value;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_listTasks[index]);
          _lastPos = index;
          _listTasks.removeAt(index);
          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa removida com sucesso."),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  _listTasks.insert(_lastPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _listTasks.sort((x, y) {
        if (x['done'] && !y['done'])
          return 1;
        else if (!x['done'] && y['done'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: _newTasksCtrl,
          keyboardType: TextInputType.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.0,
          ),
          decoration: InputDecoration(
            labelText: "Nova tarefa",
            labelStyle: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: _listTasks.length,
          padding: EdgeInsets.only(top: 10.0),
          itemBuilder: _buildItem,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        child: Icon(Icons.add),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}
