import 'package:eventstore_client/eventstore_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/repositories/todo_store.dart';
import 'package:todo_flutter_esdb_demo/features/todo/presentation/providers/todo_provider.dart';

import 'features/todo/data/services/todo_service_impl.dart';
import 'features/todo/domain/entities/todo.dart';

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodoProvider(
            TodoStore(
              TodoServiceImpl(
                EventStoreStreamsClient(
                  // Assumes that an EventStoreDB instance is
                  // running locally without security enabled
                  EventStoreClientSettings.parse(
                    'esdb://10.0.2.2:2113?tls=false',
                  ),
                ),
              ),
            ),
          ),
        ),
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
  void _addTodo() async {
    final todo = await _settingModalBottomSheet();
    if (todo != null) {
      context.read<TodoProvider>().create(todo);
    }
  }

  void _completeTodo(int index) {
    context.read<TodoProvider>().complete(index);
  }

  void _deleteTodo(int index) {
    context.read<TodoProvider>().delete(index);
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
                  onTap: () => _deleteTodo(index),
                ),
              ],
            );
          },
          itemCount: model.total,
        );
      },
    );
  }

  Future<Todo?> _settingModalBottomSheet() {
    String title = '';
    String description = '';
    return showModalBottomSheet<Todo?>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) => Padding(
            padding: EdgeInsets.all(24.0),
            child: Container(
              padding: MediaQuery.of(bc).viewInsets,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  TextField(
                    autofocus: true,
                    enableSuggestions: true,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      label: Text('Title'),
                      enabledBorder: UnderlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => title = value),
                  ),
                  TextField(
                    enableSuggestions: true,
                    enableInteractiveSelection: true,
                    decoration: InputDecoration(
                      label: Text('Description'),
                      enabledBorder: UnderlineInputBorder(),
                    ),
                    onChanged: (value) => setState(() => description = value),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed:
                          title.isEmpty == true || description.isEmpty == true
                              ? null
                              : () => Navigator.pop(
                                    bc,
                                    Todo.from(title, description),
                                  ),
                      child: Text('Add Todo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Consumer<TodoProvider>(
              builder: (__, model, _) {
                return Text(
                  '${model.open} open todos',
                  style: Theme.of(context).textTheme.caption,
                );
              },
            ),
          ],
        ),
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
