import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PDFReaderPage extends StatefulWidget {
  final String title;
  final String url;

  const PDFReaderPage({super.key, required this.title, required this.url});

  @override
  State<PDFReaderPage> createState() => _PDFReaderPageState();
}

class _PDFReaderPageState extends State<PDFReaderPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _fetchPdf();
  }

  Future<void> _fetchPdf() async {
    try {
      // Handle the case where the url still contains raw spaces
      String safeUrl = widget.url.replaceAll(' ', '%20');
      final uri = Uri.parse(safeUrl);
      
      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36',
        'Accept': 'application/pdf, */*',
      });

      if (response.statusCode == 200 || response.statusCode == 206) {
        // Verify it starts with %PDF- to make sure it's not a Cloudflare/Hostinger HTML challenge
        final firstBytes = response.bodyBytes.take(5).toList();
        final signature = String.fromCharCodes(firstBytes);
        if (!signature.startsWith('%PDF')) {
          // It's probably an HTML page or error encoded
          String sample = String.fromCharCodes(response.bodyBytes.take(100));
          throw Exception("Server did not return a valid PDF. Response starts with: $sample");
        }

        if (mounted) {
          setState(() {
            _pdfBytes = response.bodyBytes;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Server returned HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        print("PDF Fetch Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          if (_pdfBytes != null)
            SfPdfViewer.memory(
              _pdfBytes!,
              key: _pdfViewerKey,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                setState(() {
                  _errorMessage = details.description;
                  _pdfBytes = null;
                });
              },
            ),
          if (_isLoading && _errorMessage == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Downloading PDF..."),
                ],
              ),
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load PDF:\n$_errorMessage',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "URL Attempted:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SelectableText(
                      widget.url,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
