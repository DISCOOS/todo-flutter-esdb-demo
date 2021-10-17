import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_flutter_esdb_example/features/todo/presentation/todo_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'features/todo/domain/todo.dart';

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TodoProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Todo ESDB Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: TodoListPage(title: 'Todos'),
    );
  }
}

class TodoListPage extends StatefulWidget {
  TodoListPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  void _addTodo() {
    context.read<TodoProvider>().addTodo(Todo(
          false,
          'Test',
          'Some text',
        ));
  }

  void _completeTodo(int index) {
    context.read<TodoProvider>().completeTodo(index);
  }

  void _removeTodo(int index) {
    context.read<TodoProvider>().removeTodo(index);
  }

  Widget _buildListView() {
    return Consumer<TodoProvider>(
      builder: (__, model, _) {
        return ListView.builder(
          itemBuilder: (_, index) {
            return Slidable(
              actionPane: SlidableStrechActionPane(),
              actionExtentRatio: 0.2,
              child: Card(
                child: CheckboxListTile(
                  value: model.todos[index].done,
                  title: Text(model.todos[index].title),
                  subtitle: Text(model.todos[index].description),
                  onChanged: (done) => _completeTodo(index),
                ),
              ),
              secondaryActions: <Widget>[
                IconSlideAction(
                  caption: 'DELETE',
                  icon: Icons.delete,
                  onTap: () => _removeTodo(index),
                ),
              ],
            );
          },
          itemCount: model.count,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
