import 'package:eventstore_client/eventstore_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:todo_flutter_esdb_demo/features/todo/domain/repositories/todo_store.dart';
import 'package:todo_flutter_esdb_demo/features/todo/presentation/providers/todo_provider.dart';

import 'features/todo/data/services/todo_service_impl.dart';
import 'features/todo/domain/entities/todo.dart';

void main() async {
  // TODO: Replace with token of authenticated user
  final userId = 'user123';

  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TodoProvider(
            TodoStore(
              TodoServiceImpl(
                userId,
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo ESDB Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListPage(title: 'Todos w/last-write-wins'),
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
  final _checked = <String, bool>{
    'Done': false,
    'Deleted': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Consumer<TodoProvider>(
              builder: (__, model, _) {
                return Text(
                  '${model.open.length} open todos '
                  '(${model.done.length} done, '
                  '${model.deleted.length} deleted, '
                  '${model.modifications} modifications)',
                  style: Theme.of(context).textTheme.caption,
                );
              },
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleClick,
            itemBuilder: (BuildContext context) {
              return _checked.keys.map((String choice) {
                return CheckedPopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                  padding: EdgeInsets.zero,
                  checked: _checked[choice]!,
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTodo,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }

  void _createTodo() async {
    final todo = await _settingModalBottomSheet();
    if (todo != null) {
      context.read<TodoProvider>().create(todo);
    }
  }

  void _toggleTodo(String uuid) {
    context.read<TodoProvider>().toggle(uuid);
  }

  void _deleteTodo(String uuid) {
    context.read<TodoProvider>().delete(uuid);
  }

  Widget _buildListView() {
    return Consumer<TodoProvider>(
      builder: (__, model, _) {
        return RefreshIndicator(
          onRefresh: () => model.load(),
          child: ListView.builder(
            itemBuilder: (_, index) {
              final todos = model
                  .where(done: _checked['Done']!, deleted: _checked['Deleted']!)
                  .toList();
              return Slidable(
                actionPane: SlidableStrechActionPane(),
                actionExtentRatio: 0.2,
                child: Card(
                  child: CheckboxListTile(
                    value: todos[index].isDone,
                    title: Text(
                      todos[index].title,
                      style: TextStyle(
                        decoration: todos[index].isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(todos[index].description),
                    onChanged: todos[index].isDeleted
                        ? null
                        : (done) => _toggleTodo(todos[index].uuid),
                  ),
                ),
                secondaryActions: <Widget>[
                  if (!todos[index].isDeleted)
                    IconSlideAction(
                      caption: 'DELETE',
                      icon: Icons.delete,
                      onTap: () => _deleteTodo(todos[index].uuid),
                    ),
                ],
              );
            },
            itemCount: model
                .where(done: _checked['Done']!, deleted: _checked['Deleted']!)
                .length,
          ),
        );
      },
    );
  }

  Future<Todo?> _settingModalBottomSheet() {
    String title = '';
    String description = '';
    final isValid = () => title.isEmpty == true || description.isEmpty == true;
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
                      onPressed: isValid()
                          ? null
                          : () =>
                              Navigator.pop(bc, Todo.from(title, description)),
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

  void _handleClick(String value) {
    setState(() {
      _checked[value] = !_checked[value]!;
    });
  }
}
