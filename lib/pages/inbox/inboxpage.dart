import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../navbar.dart';
import '../homepage/homepage.dart';
import '../program/program_page.dart';
import '../waqaf/waqafpage.dart';
import '../akaun/akaunpage.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({Key? key}) : super(key: key);

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  int _currentIndex = 3;
  String _selectedFilter = 'Semua';

  // Sample data untuk inbox notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'id': '1',
      'title': 'Ziarah Kasih: Agihan Manfaat WAQAF FELDA bersama Warga FELDA Lok Heng Barat',
      'description': 'Tidak akan berkurang harta dengan sedekah, bahkan bertambah dengan keberkatan, Ayuh teruskan kebaikan ini bersama Waqaf FELDA.',
      'date': '4 Minggu lalu',
      'image': 'assets/images/KP5R3.png',
      'isRead': false,
      'category': 'Agihan Manfaat',
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF11998E),
      'facebookUrl': 'https://www.facebook.com/share/v/1F2hVFmcEi/', // Ganti dengan URL post anda
    },
    {
      'id': '2',
      'title': 'Agihan Manfaat Gelandangan di Sekitar Kuala Lumpur dengan kerjasama YAYASAN FELDA dan PERSADA',
      'description': 'Pada Bulan Ramadan yang mulia ini, Waqaf FELDA dengan kerjasama YAYASAN FELDA dan PERSADA telah mengagihkan manfaat kepada golongan gelandangan di sekitar Kuala Lumpur.',
      'date': '9 Bulan lalu',
      'image': 'assets/images/IST2.png',
      'isRead': false,
      'category': 'Agihan Manfaat',
      'icon': Icons.check_circle_rounded,
      'color': Color(0xFF11998E),
      'facebookUrl': 'https://www.facebook.com/watch/?v=628287120018116',
    },
    {
      'id': '3',
      'title': 'Sumbangan Terindah: Set Persalinan Akhir & Waqaf Al-Quran',
      'description': 'Mari tinggalkan bekalan penuh makna dengan berwakaf melalui Set Persalinan Akhir & Waqaf Al-Quran bersama Waqaf FELDA — hadiah abadi yang terus mengalir pahalanya.',
      'date': '2 Bulan lalu',
      'image': 'assets/images/SPAT1.png',
      'isRead': true,
      'category': 'Kempen',
      'icon': Icons.article_rounded,
      'color': Color(0xFFF36F21),
      'facebookUrl': ' https://www.facebook.com/share/v/1H3pxmJ4Zr/',
    },
    {
      'id': '4',
      'title': 'Jom Bersama: Potongan Bulanan Bersama WAQAF FELDA',
      'description': 'WAQAF FELDA menyeru semua petugas kumpulan FELDA untuk bersama menyertai amalan wakaf secara konsisten melalui potongan gaji bulanan.',
      'date': '2 Bulan lalu',
      'image': 'assets/images/WQT1.png',
      'isRead': true,
      'category': 'Kempen',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFFF36F21),
      'facebookUrl': 'https://www.facebook.com/share/v/1JYqExjyRB/',
    },
    {
      'id': '5',
      'title': 'Kunci berkat amalan kecil: Istiqomah.',
      'description': 'Allah pasti bukakan jalan untuk lebih banyak kebaikan, Inshaa Allah.',
      'date': '1 Bulan lalu',
      'image': 'assets/images/SPAT1.png',
      'isRead': true,
      'category': 'Ilmu & Inspirasi',
      'icon': Icons.trending_up_rounded,
      'color': Color.fromARGB(255, 233, 33, 243),
      'facebookUrl': 'https://www.facebook.com/share/v/1GWC6sWKnU/',
    },
  ];

  // Fungsi untuk membuka Facebook URL
  Future<void> _openFacebookPost(String url) async {
    // Buang whitespace dari URL
    final cleanUrl = url.trim();
    final Uri uri = Uri.parse(cleanUrl);
    
    try {
      // Cuba buka URL terus
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      if (!launched) {
        throw 'Tidak dapat membuka pautan';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka pautan Facebook. Sila cuba lagi.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const Homepage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const ProgramPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const WaqafPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const AkaunPage(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
        break;
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final notification = notifications.firstWhere((n) => n['id'] == id);
      notification['isRead'] = true;
    });
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    _markAsRead(notification['id']);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(0),
                    children: [
                      // Image Header dengan aspect ratio 16:9 (hanya untuk popup)
                      if (notification['image'] != null && notification['image'].toString().isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 9 / 16, // 16:9 ratio
                          decoration: BoxDecoration(
                            color: notification['color'].withOpacity(0.1),
                          ),
                          child: Stack(
                            children: [
                              Image.asset(
                                notification['image'],
                                width: double.infinity,
                                height: MediaQuery.of(context).size.width * 9 / 16,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: notification['color'].withOpacity(0.2),
                                    child: Center(
                                      child: Icon(
                                        notification['icon'],
                                        size: 80,
                                        color: notification['color'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Positioned(
                                top: 16,
                                right: 16,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: notification['color'].withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    notification['category'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: notification['color'],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  notification['date'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              notification['title'],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              notification['description'],
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Button untuk buka Facebook Post
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  if (notification['facebookUrl'] != null) {
                                    _openFacebookPost(notification['facebookUrl']);
                                  }
                                },
                                icon: const Icon(Icons.facebook_rounded, size: 20),
                                label: const Text(
                                  'Lihat di Facebook',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: notification['color'],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n['isRead']).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Inbox',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Colors.black87),
            onPressed: () {
              setState(() {
                for (var notification in notifications) {
                  notification['isRead'] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua notifikasi ditandakan sebagai dibaca'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Tandakan semua sebagai dibaca',
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tiada notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semua notifikasi akan dipaparkan di sini',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isRead'] as bool;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFF0F8FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isRead
                          ? Colors.grey.withOpacity(0.2)
                          : (notification['color'] as Color).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showNotificationDetails(notification),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon sahaja untuk senarai inbox
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: (notification['color'] as Color)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                notification['icon'] as IconData,
                                color: notification['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (!isRead)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            color: notification['color'],
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          notification['title'],
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isRead
                                                ? FontWeight.w600
                                                : FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['description'],
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        notification['date'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: (notification['color'] as Color)
                                              .withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          notification['category'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: notification['color'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Arrow Icon
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}