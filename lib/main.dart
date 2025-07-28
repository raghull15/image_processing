import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      );
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? imageFile;
  final picker = ImagePicker();
  bool showControls = true;

  Future<void> requestPermission() async {
    await Permission.photos.request();
    await Permission.storage.request();
  }

  Future<void> pickImage(ImageSource source) async {
    await requestPermission();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => imageFile = File(pickedFile.path));
    }
  }

  Future<File> saveToExternalStorage(File image) async {
    final directory = Directory('/storage/emulated/0/Pictures/MyFlutterStories');
    if (!await directory.exists()) await directory.create(recursive: true);
    final fileName = basename(image.path);
    final saved = await image.copy('${directory.path}/$fileName');

    try {
      const channel = MethodChannel('media_scanner');
      await channel.invokeMethod('scanMedia', {'path': saved.path});
    } catch (e) {
      if (kDebugMode) print("Media scan failed: $e");
    }

    return saved;
  }

  void saveImage(BuildContext context) async {
    if (imageFile != null) {
      final saved = await saveToExternalStorage(imageFile!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saved to ${saved.path}")),
      );
    }
  }

  void shareImage() {
    if (imageFile != null) {
      Share.shareXFiles([XFile(imageFile!.path)], text: "Check out my Flutter Story!");
    }
  }

  @override
  Widget build(BuildContext context) => WillPopScope(
        onWillPop: () async => true,
        child: Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(80),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.pink.shade300, Colors.redAccent]),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text("Image Viewer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                centerTitle: true,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
              ),
            ),
          ),
          body: GestureDetector(
            onTap: () => setState(() => showControls = !showControls),
            child: Stack(
              children: [
                Center(
                  child: imageFile != null
                      ? AnimatedSwitcher(
                          duration: Duration(milliseconds: 400),
                          child: Image.file(
                            imageFile!,
                            key: ValueKey(imageFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Text("No Story Yet", style: TextStyle(color: Colors.white70, fontSize: 20)),
                ),
                if (showControls)
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          buildActionButton(Icons.camera_alt, () => pickImage(ImageSource.camera)),
                          buildActionButton(Icons.photo, () => pickImage(ImageSource.gallery)),
                          buildActionButton(Icons.save, () => saveImage(context)),
                          buildActionButton(Icons.share, shareImage),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

  Widget buildActionButton(IconData icon, VoidCallback onPressed) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      );
}