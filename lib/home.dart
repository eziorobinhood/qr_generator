import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/rendering.dart'; // For RepaintBoundary
import 'dart:ui' as ui; // For Image (ui.Image)
import 'package:universal_html/html.dart' as html; // For web download logic
import 'package:flutter/foundation.dart' show kIsWeb;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final TextEditingController _textController = TextEditingController();
  String qrCodeData = '';
  final GlobalKey _qrKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    // Add a listener to the text controller to update QR code data dynamically
    _textController.addListener(() {
      setState(() {
        qrCodeData =
            _textController.text.isEmpty ? "No Data" : _textController.text;
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveQrCode() async {
    if (qrCodeData == "No Data" || qrCodeData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text to generate QR code first.'),
        ),
      );
      return;
    }

    try {
      // Find the render object of the QrImageView
      RenderRepaintBoundary? boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception("Could not find RenderRepaintBoundary for QR code.");
      }

      // Capture the image from the render boundary
      // Use a higher pixelRatio for better quality, especially for QR codes
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception("Failed to convert QR code to ByteData.");
      }

      Uint8List pngBytes = byteData.buffer.asUint8List();

      // --- Web specific download logic (only path remaining) ---
      // Create a Blob from the PNG bytes
      final blob = html.Blob([pngBytes]);
      // Create a temporary URL for the Blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      // Create an invisible anchor element
      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute(
              'download',
              'qrcode.png',
            ) // Set the filename for download
            ..click(); // Programmatically click the anchor to trigger download
      html.Url.revokeObjectUrl(url); // Revoke the object URL to free up memory
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('QR Code downloaded!')));
    } catch (e) {
      print('Error saving QR code: $e'); // Log any errors to console
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating/saving QR Code: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Generator')),
      body: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(image: AssetImage("images/GraphifyInfotech.png")),
            Text('Welcome to the QR Generator'),
            const SizedBox(height: 20),
            Container(
              width: MediaQuery.of(context).size.width * 0.5,
              child: TextFormField(
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter text to generate QR code',
                ),
              ),
            ),

            const SizedBox(height: 20),
            RepaintBoundary(
              key: _qrKey, // Assign the GlobalKey here
              child:
                  qrCodeData.isNotEmpty && qrCodeData != "No Data"
                      ? QrImageView(
                        data: qrCodeData, // The data to encode in the QR code
                        version:
                            QrVersions
                                .auto, // Automatically selects the best QR version
                        size: 200.0, // Size of the QR code image
                        gapless: false, // Set to false to have a quiet zone
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Colors.black, // Color of the QR code modules
                        ),
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Colors.black, // Color of the eye patterns
                        ),
                      )
                      : Container(
                        // Placeholder when no data is entered
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Type something to generate a QR Code.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
            ),
            const SizedBox(height: 20.0),

            // Button to trigger the download
            ElevatedButton(
              onPressed: _saveQrCode, // Call the save function
              child: const Text('Download QR Code as PNG'),
            ),

            const SizedBox(height: 20.0),

            // Display the current QR data text below the code
            Text(
              'QR Code Content: "$qrCodeData"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
