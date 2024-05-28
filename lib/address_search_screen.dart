import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class AddressSearchScreen extends StatefulWidget {
  @override
  _AddressSearchScreenState createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _searchAddress(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('https://geocode.search.hereapi.com/v1/geocode?q=$query&apiKey=TWcQTYA4vftM0nhJ5nuBd1BZK2xe2mt2hLcC-uC3d7o'),
    );

    if (response.statusCode == 200) {
      // Xử lý định dạng dữ liệu từ API
      final utf8Decoder = Utf8Decoder();
      final decodedData = utf8Decoder.convert(response.bodyBytes);

      setState(() {
        _searchResults = json.decode(decodedData)['items'];
        _isLoading = false;
        print(decodedData); // In ra dữ liệu đã được giải mã
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
      _searchAddress(_controller.text);
    });
  }

  void _openGoogleMaps(String address) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeFull(address)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tìm kiếm địa chỉ', style: GoogleFonts.roboto()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Nhập địa chỉ',
                hintStyle: GoogleFonts.roboto(), // Sử dụng font Roboto
                suffixIcon: _isLoading
                    ? CircularProgressIndicator()
                    : IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () => _searchAddress(_controller.text),
                ),
              ),
              onChanged: (text) => _onSearchChanged(),
              style: GoogleFonts.roboto(), // Sử dụng font Roboto
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return ListTile(
                    title: Text(
                      result['title'],
                      style: GoogleFonts.roboto(), // Sử dụng font Roboto
                    ),
                    subtitle: Text(
                      result['address']['label'],
                      style: GoogleFonts.roboto(), // Sử dụng font Roboto
                    ),
                    onTap: () => _openGoogleMaps(result['address']['label']),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
