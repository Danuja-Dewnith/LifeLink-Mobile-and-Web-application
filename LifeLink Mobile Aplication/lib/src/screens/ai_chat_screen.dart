import 'dart:typed_data';
import 'dart:io'; // ← Added for File class
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _userMessage = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const apiKey =
      "AIzaSyAsObBypfDH5h1X3jHtBkH09HozXdAE0S8"; // ← Replace with your real Gemini API key

  final model = GenerativeModel(
    model: 'gemini-flash-latest', // Recommended working model
    apiKey: apiKey,
  );

  final List<Message> _messages = [];
  Uint8List? _selectedImageBytes;
  String? _selectedMimeType;
  String? _selectedFileName;

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedMimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        _selectedFileName = image.name;
      });
    }
  }

  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedMimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        _selectedFileName = image.name;
      });
    }
  }

  // Pick any file - FIXED
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes;

        if (file.bytes != null) {
          bytes = file.bytes;
        } else if (file.path != null) {
          // Fallback using dart:io File
          final ioFile = File(file.path!);
          bytes = await ioFile.readAsBytes();
        }

        if (bytes != null) {
          setState(() {
            _selectedImageBytes = bytes;
            _selectedMimeType =
                lookupMimeType(file.name) ?? 'application/octet-stream';
            _selectedFileName = file.name;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _clearAttachment() {
    setState(() {
      _selectedImageBytes = null;
      _selectedMimeType = null;
      _selectedFileName = null;
    });
  }

  Future<void> sendMessage() async {
    final text = _userMessage.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final userMessageText = text.isEmpty ? "Analyze this file:" : text;

    setState(() {
      _messages.add(Message(
        isUser: true,
        message: userMessageText,
        date: DateTime.now(),
        imageBytes: _selectedImageBytes,
        fileName: _selectedFileName,
      ));
      _userMessage.clear();
    });

    final parts = <Part>[];

    if (text.isNotEmpty) {
      parts.add(TextPart(text));
    }

    if (_selectedImageBytes != null && _selectedMimeType != null) {
      parts.add(DataPart(_selectedMimeType!, _selectedImageBytes!));
    }

    final content = [Content.multi(parts)];

    try {
      final response = await model.generateContent(content);

      setState(() {
        _messages.add(Message(
          isUser: false,
          message: response.text ?? "Sorry, I couldn't process that.",
          date: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(Message(
          isUser: false,
          message: "Error: ${e.toString()}",
          date: DateTime.now(),
        ));
      });
    }

    _clearAttachment();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // Messages Area
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          "How can I help you today?",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[_messages.length - 1 - index];
                      return Messages(
                        isUser: msg.isUser,
                        message: msg.message,
                        date: DateFormat('HH:mm').format(msg.date),
                        imageBytes: msg.imageBytes,
                        fileName: msg.fileName,
                      );
                    },
                  ),
          ),

          // Attachment Preview
          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: [
                  if (_selectedMimeType!.startsWith('image/'))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _selectedImageBytes!,
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insert_drive_file,
                          size: 40, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedFileName ?? 'Selected file',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: _clearAttachment,
                  ),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library_outlined,
                      color: Color(0xFF4F46E5)),
                ),
                IconButton(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF4F46E5)),
                ),
                IconButton(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_outlined,
                      color: Color(0xFF4F46E5)),
                ),
                Expanded(
                  child: TextField(
                    controller: _userMessage,
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Message Model
class Message {
  final bool isUser;
  final String message;
  final DateTime date;
  final Uint8List? imageBytes;
  final String? fileName;

  Message({
    required this.isUser,
    required this.message,
    required this.date,
    this.imageBytes,
    this.fileName,
  });
}

// Beautiful Message Bubbles
class Messages extends StatelessWidget {
  final bool isUser;
  final String message;
  final String date;
  final Uint8List? imageBytes;
  final String? fileName;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
    required this.date,
    this.imageBytes,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF4F46E5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageBytes != null && isUser)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            if (imageBytes != null && isUser) const SizedBox(height: 10),
            if (fileName != null && !isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  "📎 $fileName",
                  style: TextStyle(
                    color: isUser ? Colors.white70 : Colors.indigo,
                    fontStyle: FontStyle.italic,
                    fontSize: 13,
                  ),
                ),
              ),
            Text(
              message,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: TextStyle(
                color: isUser ? Colors.white60 : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
