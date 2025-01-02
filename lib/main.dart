import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:accordion/accordion.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MessageProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Message App',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xffe83e8c),
            brightness: Brightness.dark,
          )),
      home: MessageScreen(),
    );
  }
}

class MessageScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MessageProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text('Flutter MongoDB Template')),
      body: Column(
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
                child: SizedBox(
                  height: 150,
                  child: Image.asset(
                    'images/flutterLogo.png',
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(top: 3.0, bottom: 3.0),
              child: SizedBox(
                height: 100,
                child: Image.asset(
                  'images/mongoDbLogo.png',
                  fit: BoxFit.scaleDown,
                ),
              ),
            )),
          ]),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Enter a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    DateTime currentTimestamp = DateTime.now();
                    provider.addMessage(_controller.text, currentTimestamp);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: provider.messages.length,
                    itemBuilder: (context, index) {
                      final message = provider.messages[index];
                      return Card(
                          child: ListTile(
                        title: Text(message['message']),
                        subtitle: Text(DateFormat('d MMM y, hh:mm aaa').format(
                            DateTime.parse(message['created_date']).toLocal())),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            provider.deleteMessage(message['_id']);
                          },
                        ),
                      ));
                    },
                  ),
          ),
          Expanded(
              child: Accordion(
                  contentBackgroundColor: Color(0xff23191c),
                  contentBorderColor: Color(0xffe83e8c),
                  contentBorderWidth: 1,
                  contentHorizontalPadding: 20,
                  //headerBackgroundColor: Color(0xff23191c),
                  headerBorderColor: Color(0xffe83e8c),
                  headerBorderWidth: 1,
                  headerPadding: EdgeInsets.only(top:10.0, bottom: 10.0, left: 20.0),
                  children: [
                AccordionSection(
                  isOpen: false,
                  contentVerticalPadding: 20,
                  header: const Text('Buttons to Test RUM'),
                  content: const Text("Content Text"),
                ),
              ]))
        ],
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    // #docregion image-asset
    return Image.asset(
      image,
      width: 120,
      height: 250,
      fit: BoxFit.cover,
    );
    // #enddocregion image-asset
  }
}

class MessageProvider extends ChangeNotifier {
  List<dynamic> messages = [];
  bool isLoading = false;

  final String baseUrl = 'http://localhost:5000/messages';

  MessageProvider() {
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(baseUrl));
      messages = jsonDecode(response.body);
    } catch (error) {
      print('Error fetching messages: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMessage(String message, DateTime currentTimestamp) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'created_date': currentTimestamp.toIso8601String()
        }),
      );
      fetchMessages();
    } catch (error) {
      print('Error adding message: $error');
    }
  }

  Future<void> deleteMessage(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/$id'));
      fetchMessages();
    } catch (error) {
      print('Error deleting message: $error');
    }
  }
}
