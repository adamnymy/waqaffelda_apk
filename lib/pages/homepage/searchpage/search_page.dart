import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final List<Program> _programs = [
    Program(
      title: 'Kempen Potong Lima Ringgit',
      organization: 'WAQAF FELDA',
      isVerified: true,
      collected: 'RM 4,325.00',
      daysLeft: 'Baki hari ∞',
      imageUrl: 'assets/images/KP5R3.png',
      color: Colors.teal.shade800,
    ),
    Program(
      title: 'Infak Set Persalinan Akhir',
      organization: 'WAQAF FELDA',
      isVerified: true,
      collected: '',
      daysLeft: 'Baki hari ∞',
      imageUrl: 'assets/images/SPAT1.png',
      color: Colors.green.shade700,
    ),
    Program(
      title: 'Wakaf Al-Qur\'an untuk Pelajar',
      organization: "WAQAF FELDA",
      isVerified: true,
      collected: 'RM 13,520.00',
      daysLeft: 'Baki hari ∞',
      imageUrl: 'assets/images/WQT1.png',
      color: Colors.orange.shade400,
    ),
  ];

  List<Program> _filteredPrograms = [];

  @override
  void initState() {
    super.initState();
    _filteredPrograms = _programs;
  }

  void _filterPrograms(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPrograms = _programs;
      } else {
        _filteredPrograms = _programs.where((program) {
          return program.title.toLowerCase().contains(query.toLowerCase()) ||
              program.organization.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari nama program...',
            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search, color: Colors.orange.shade700),
          ),
          onChanged: _filterPrograms,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Program Terkini',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ..._filteredPrograms.map((program) => _buildProgramCard(program)).toList(),
        ],
      ),
    );
  }

  Widget _buildProgramCard(Program program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          print('Tapped on: ${program.title}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder -> use Image.asset with fallback
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 120,
                  height: 90,
                  child: Image.asset(
                    program.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) {
                      // fallback if asset not found or fails to load
                      return Container(
                        color: program.color,
                        child: Center(
                          child: Icon(
                            Icons.mosque,
                            size: 40,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            program.organization,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (program.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.blue.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terkumpul',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                program.collected,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              program.daysLeft,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Program {
  final String title;
  final String organization;
  final bool isVerified;
  final String collected;
  final String daysLeft;
  final String imageUrl;
  final Color color;

  Program({
    required this.title,
    required this.organization,
    required this.isVerified,
    required this.collected,
    required this.daysLeft,
    required this.imageUrl,
    required this.color,
  });
}
