import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MessageProvider1()),
        ChangeNotifierProvider(create: (context) => MessageProvider2()),
        ChangeNotifierProvider(create: (context) => MessageProvider3()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MessageTabs(),
    );
  }
}

class MessageTabs extends StatelessWidget {
  const MessageTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'assets/logowobg.png',
                height: 40, // Adjust the height to fit your design
              ),
              const SizedBox(width: 8), // Space between logo and text
              const Text('Message Viewer'),
            ],
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Service 1'),
              Tab(text: 'Service 2'),
              Tab(text: 'Service 3'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MessageList(serviceIndex: 1),
            MessageList(serviceIndex: 2),
            MessageList(serviceIndex: 3),
          ],
        ),
      ),
    );
  }
}

class MessageList extends StatelessWidget {
  final int serviceIndex;

  const MessageList({super.key, required this.serviceIndex});

  @override
  Widget build(BuildContext context) {
    late final ChangeNotifier messageProvider;

    switch (serviceIndex) {
      case 1:
        messageProvider = Provider.of<MessageProvider1>(context);
        break;
      case 2:
        messageProvider = Provider.of<MessageProvider2>(context);
        break;
      case 3:
        messageProvider = Provider.of<MessageProvider3>(context);
        break;
      default:
        messageProvider = Provider.of<MessageProvider1>(context);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: messageProvider.messages.length,
        itemBuilder: (context, index) {
          final message = messageProvider.messages[index];
          return Card(
            elevation: 5,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              title: Text(
                message['subject'] ?? 'No Subject',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(message['body'] ?? 'No Content'),
            ),
          );
        },
      ),
    );
  }
}

class MessageProvider1 with ChangeNotifier {
  final List<Map<String, String>> _messages = [
    {
      'subject': 'Hello from Service 1',
      'body': 'This is a message body from Service 1.'
    },
    {'subject': 'Another Message', 'body': 'More content from Service 1.'},
  ];

  List<Map<String, String>> get messages => _messages;
}

class MessageProvider2 with ChangeNotifier {
  final List<Map<String, String>> _messages = [
    {
      'subject': 'Hello from Service 2',
      'body': 'This is a message body from Service 2.'
    },
    {'subject': 'Another Message', 'body': 'More content from Service 2.'},
  ];

  List<Map<String, String>> get messages => _messages;
}

class MessageProvider3 with ChangeNotifier {
  final List<Map<String, String>> _messages = [
    {
      'subject': 'Hello from Service 3',
      'body': 'This is a message body from Service 3.'
    },
    {'subject': 'Another Message', 'body': 'More content from Service 3.'},
  ];

  List<Map<String, String>> get messages => _messages;
}
