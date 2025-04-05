import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Hello! I\'m Bready, your baking assistant. Ask me anything about baking, recipes, or ingredient substitutions! 🍪',
      'isUser': false,
      'time': 'Just now',
    }
  ];

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final ImagePicker _picker = ImagePicker();
  final String _backendUrl = 'http://127.0.0.1:5000'; // Your Flask URL

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    final userMessage = _controller.text;
    _controller.clear();

    setState(() {
      _messages.insert(0, {
        'text': userMessage,
        'isUser': true,
        'time': _formatTime(DateTime.now()),
      });
    });

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/ask'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'question': userMessage}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages.insert(0, {
            'text': data['response'],
            'isUser': false,
            'time': _formatTime(DateTime.now()),
          });
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.insert(0, {
          'text': 'Error: ${e.toString()}\n\nMake sure:\n1. Flask server is running\n2. CORS is enabled on backend',
          'isUser': false,
          'time': _formatTime(DateTime.now()),
        });
      });
    }
  }

  Future<void> _uploadImage(File image, String action) async {
    setState(() {
      _messages.insert(0, {
        'image': image,
        'isUser': true,
        'time': _formatTime(DateTime.now()),
      });
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/api/analyze-image'),
      );
      request.fields['action'] = action;
      request.files.add(await http.MultipartFile.fromPath('file', image.path));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);

        setState(() {
          _messages.insert(0, {
            'text': jsonData['analysis'] ?? 'No analysis returned.',
            'isUser': false,
            'time': _formatTime(DateTime.now()),
          });
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _messages.insert(0, {
          'text': 'Failed to analyze image. Error: ${e.toString()}',
          'isUser': false,
          'time': _formatTime(DateTime.now()),
        });
      });
    }
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
        },
      );
    } else {
      setState(() {
        _messages.insert(0, {
          'text': 'Speech recognition not available on this device',
          'isUser': false,
          'time': _formatTime(DateTime.now()),
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('What would you like to do?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analyze food'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadImage(File(image.path), 'analyze');
                },
              ),
              ListTile(
                leading: const Icon(Icons.zoom_in),
                title: const Text('Identify ingredients'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadImage(File(image.path), 'identify');
                },
              ),
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('Troubleshoot baking problem'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadImage(File(image.path), 'troubleshoot');
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bready Chat',
          style: GoogleFonts.pacifico(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD4A373),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildChatBubble(message);
              },
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: message['isUser']
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message['isUser'])
            CircleAvatar(
              backgroundColor: const Color(0xFFD4A373).withOpacity(0.2),
              child: const Icon(Icons.person, color: Color(0xFFD4A373)),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: ChatBubble(
              clipper: ChatBubbleClipper4(
                type: message['isUser']
                    ? BubbleType.receiverBubble
                    : BubbleType.sendBubble,
              ),
              backGroundColor: message['isUser']
                  ? const Color(0xFFF8EDE3)
                  : const Color(0xFFD4A373).withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.containsKey('image'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        message['image'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (message.containsKey('text'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        message['text'],
                        style: GoogleFonts.dmSans(),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message['time'],
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message['isUser']) const SizedBox(width: 8),
          if (!message['isUser'])
            CircleAvatar(
              backgroundColor: const Color(0xFFD4A373).withOpacity(0.2),
              child: const Icon(Icons.breakfast_dining, color: Color(0xFFD4A373)),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFD4A373)),
            onPressed: _pickImage,
          ),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off : Icons.mic,
              color: _isListening ? Colors.red : const Color(0xFFD4A373),
            ),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about baking...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            backgroundColor: const Color(0xFFD4A373),
            foregroundColor: Colors.white,
            elevation: 0,
            mini: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
            ),
            onPressed: _sendMessage,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}