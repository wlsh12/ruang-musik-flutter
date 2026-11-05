import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final cariController = TextEditingController();
  final player = AudioPlayer();

  List songs = [];
  List favorit = [];

  String? laguAktif;
  bool sedangPutar = false;
  bool loading = false;
  bool prosesMusik = false;
  bool tampilFavorit = false;
  String pesan = 'Cari lagu favoritmu 🎵';

  // Menampilkan pesan jika terjadi kesalahan.
  void tampilPesan(String teks) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(teks)),
    );
  }

  // Mengambil lagu dari API iTunes.
  Future<void> cariLagu() async {
    if (loading) return;

    if (cariController.text.trim().isEmpty) {
      tampilPesan('Masukkan judul lagu atau artis.');
      return;
    }

    setState(() {
      loading = true;
      tampilFavorit = false;
    });

    try {
      final url = Uri.https('itunes.apple.com', '/search', {
        'term': cariController.text.trim(),
        'entity': 'song',
        'limit': '10',
      });

      final response =
      await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() {
        songs = data['results'];
        pesan = 'Lagu tidak ditemukan.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        songs = [];
        pesan = 'Gagal mengambil lagu. Coba cari lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  // Memutar atau menjeda cuplikan lagu.
  Future<void> putarLagu(String url) async {
    if (prosesMusik) return;

    if (url.isEmpty) {
      tampilPesan('Preview tidak tersedia.');
      return;
    }

    setState(() {
      prosesMusik = true;
    });

    try {
      if (laguAktif == url && sedangPutar) {
        await player.pause();

        if (!mounted) return;
        setState(() {
          sedangPutar = false;
        });
      } else {
        // Lanjutkan jika dijeda; mulai ulang jika sudah selesai.
        if (laguAktif == url && player.state == PlayerState.paused) {
          await player.resume();
        } else {
          await player.play(UrlSource(url));
        }

        if (!mounted) return;
        setState(() {
          laguAktif = url;
          sedangPutar = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        laguAktif = null;
        sedangPutar = false;
      });
      tampilPesan('Lagu gagal diputar.');
    } finally {
      if (mounted) {
        setState(() {
          prosesMusik = false;
        });
      }
    }
  }

  // Mengecek apakah lagu sudah masuk favorit.
  bool sudahFavorit(dynamic lagu) {
    return favorit.any((item) => item['trackId'] == lagu['trackId']);
  }

  // Menambah atau menghapus favorit.
  void ubahFavorit(dynamic lagu) {
    setState(() {
      if (sudahFavorit(lagu)) {
        favorit.removeWhere(
              (item) => item['trackId'] == lagu['trackId'],
        );
      } else {
        favorit.add(lagu);
      }
    });
  }

  // Profil ditampilkan menggunakan dialog sederhana.
  void bukaProfil() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profil Saya'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 35,
              child: Icon(Icons.person, size: 45),
            ),
            const SizedBox(height: 16),
            const Text(
              'Wilshen Aristo Budianto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text('825240088'),
            const Text('Sistem Informasi'),
            const SizedBox(height: 16),
            Text('${favorit.length} lagu favorit'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cariController.dispose();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pilih daftar yang ditampilkan.
    final daftar = tampilFavorit ? favorit : songs;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: const Text('Ruang Musik'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: bukaProfil,
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profil',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cariController,
              onSubmitted: (_) => cariLagu(),
              decoration: InputDecoration(
                hintText: 'Judul lagu atau artis',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : cariLagu,
                child: const Text('Cari Lagu'),
              ),
            ),
            const SizedBox(height: 10),

            // Tombol untuk berpindah daftar.
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Semua Lagu'),
                  selected: !tampilFavorit,
                  onSelected: (_) {
                    setState(() {
                      tampilFavorit = false;
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: Text('Favorit (${favorit.length})'),
                  selected: tampilFavorit,
                  onSelected: (_) {
                    setState(() {
                      tampilFavorit = true;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : daftar.isEmpty
                  ? Center(
                child: Text(
                  tampilFavorit
                      ? 'Belum ada lagu favorit.'
                      : pesan,
                ),
              )
                  : ListView.builder(
                itemCount: daftar.length,
                itemBuilder: (context, index) {
                  final lagu = daftar[index];

                  return Card(
                    color: Colors.white,
                    elevation: 0,
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.music_note),
                      ),
                      title: Text(
                        lagu['trackName'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        lagu['artistName'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => ubahFavorit(lagu),
                            icon: Icon(
                              sudahFavorit(lagu)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.redAccent,
                            ),
                          ),

                          // Ikon mengikuti keadaan player,
                          // termasuk saat cuplikan selesai.
                          StreamBuilder<PlayerState>(
                            stream: player.onPlayerStateChanged,
                            builder: (context, snapshot) {
                              final aktif =
                                  laguAktif == lagu['previewUrl'] &&
                                      player.state ==
                                          PlayerState.playing;

                              return IconButton(
                                onPressed: prosesMusik
                                    ? null
                                    : () => putarLagu(
                                  lagu['previewUrl'] ?? '',
                                ),
                                icon: Icon(
                                  aktif
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: Colors.teal,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Text(
              'Musik berupa cuplikan dari iTunes',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}