//======= IMPORTS (LIBRARY & FILE LAIN) =======
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'package:flutter_aplikasi_cuaca/main.dart';

//======= WIDGET HALAMAN HASIL PENCARIAN CUACA (STATEFUL) =======
class Result extends StatefulWidget {
  final String city;

  const Result({super.key, required this.city});

  @override
  State<Result> createState() => _ResultState();
}

//======= STATE DARI HALAMAN HASIL =======
class _ResultState extends State<Result> {
  //======= VARIABEL STATE (FUTURE DATA CUACA & FORECAST) =======
  late Future<Map<String, dynamic>> weatherData;
  late Future<Map<String, dynamic>> forecastData;

  String formatTemperature(
    num value,
    bool isCelsius, {
    int decimalPlaces = 0,
  }) {
    final celsius = value.toDouble();

    final temperature = isCelsius ? celsius : (celsius * 9 / 5) + 32;

    final unit = isCelsius ? '°C' : '°F';

    return '${temperature.toStringAsFixed(decimalPlaces)}$unit';
  }

  //======= FUNGSI MENAMBAHKAN KOTA KE FAVORIT (FIRESTORE) =======

  Future<void> addFavorite() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu.'),
        ),
      );
      return;
    }

    final city = widget.city.trim();

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorite');

      // Periksa apakah kota sudah ada di Firestore.
      final check = await ref.where('city', isEqualTo: city).limit(1).get();

      if (check.docs.isNotEmpty) {
        // Pastikan data yang sudah ada juga tersimpan di SQLite.
        await DatabaseService.instance.addFavoriteCity(
          userId: user.uid,
          city: city,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kota ini sudah ada di favorit ⭐'),
          ),
        );
        return;
      }

      // Simpan ke SQLite.
      await DatabaseService.instance.addFavoriteCity(
        userId: user.uid,
        city: city,
      );

      // Simpan ke Firestore.
      await ref.add({
        'city': city,
        'time': Timestamp.now(),
      });

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil ditambahkan ke favorit ⭐'),
        ),
      );
    } catch (e) {
      debugPrint('ADD FAVORITE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan favorit: $e'),
        ),
      );
    }
  }

  //======= FUNGSI MENYIMPAN RIWAYAT PENCARIAN (FIRESTORE) =======
  Future<void> saveHistory() async {
    try {
      final data = await ApiService.getWeather(
        widget.city,
      );

      String cityName = data['name'];

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;
      // Simpan nama kota hasil API ke SQLite.
      await DatabaseService.instance.addSearchHistory(
        userId: user.uid,
        city: cityName,
      );
      final ref = FirebaseFirestore.instance
          .collection(
            'users',
          )
          .doc(
            user.uid,
          )
          .collection(
            'history',
          );

      final check = await ref
          .where(
            'city',
            isEqualTo: cityName,
          )
          .get();

      // Menyimpan ke riwayat hanya jika belum ada di database
      if (check.docs.isEmpty) {
        await ref.add({
          'city': cityName,
          'time': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint(
        "SAVE HISTORY ERROR: $e",
      );
    }
  }

  //======= INISIALISASI AWAL STATE (INIT STATE) =======
  @override
  void initState() {
    super.initState();

    weatherData = ApiService.getWeather(
      widget.city,
    );

    forecastData = ApiService.getForecast(
      widget.city,
    );

    saveHistory();
  }

  //======= FUNGSI HELPER: MENDAPATKAN IKON CUACA =======
  IconData getWeatherIcon(String condition) {
    if (condition.contains("cloud")) {
      return Icons.cloud;
    } else if (condition.contains("rain")) {
      return Icons.grain;
    } else if (condition.contains("clear")) {
      return Icons.wb_sunny;
    } else {
      return Icons.wb_cloudy;
    }
  }

  //======= FUNGSI HELPER: MENDAPATKAN NAMA HARI =======
  String getHari(String date) {
    DateTime d = DateTime.parse(date);

    List<String> hari = [
      "Sen",
      "Sel",
      "Rab",
      "Kam",
      "Jum",
      "Sab",
      "Min",
    ];

    return hari[d.weekday - 1];
  }

  //======= FUNGSI HELPER: MENERJEMAHKAN STATUS CUACA KE BAHASA INDONESIA =======
  String translateWeather(String weather) {
    weather = weather.toLowerCase();

    if (weather.contains("clear")) {
      return "Cerah";
    } else if (weather.contains("cloud")) {
      return "Berawan";
    } else if (weather.contains("rain")) {
      return "Hujan";
    } else if (weather.contains("thunderstorm")) {
      return "Badai Petir";
    } else if (weather.contains("mist")) {
      return "Berkabut";
    } else {
      return weather;
    }
  }

  @override
  Widget build(BuildContext context) {
    //======= TAMPILAN ANTARMUKA UTAMA (UI) =======
    return Scaffold(
      //======= APP BAR & TOMBOL FAVORIT (STREAM BUILDER) =======
      appBar: AppBar(
        title: Text(
          "Cuaca ${widget.city}",
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseAuth.instance.currentUser == null
                ? const Stream<QuerySnapshot<Map<String, dynamic>>>.empty()
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('favorite')
                    .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];

              final isFavorite = docs.any(
                (e) =>
                    (e.data()['city'] ?? '').toString().trim().toLowerCase() ==
                    widget.city.trim().toLowerCase(),
              );

              return IconButton(
                tooltip: isFavorite
                    ? 'Sudah menjadi favorit'
                    : 'Tambahkan ke favorit',
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : null,
                ),
                onPressed: addFavorite,
              );
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,

        //======= DESAIN LATAR BELAKANG (GRADIENT) =======
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        //======= FUTURE BUILDER: MENGAMBIL DATA CUACA SAAT INI =======
        child: FutureBuilder(
          future: weatherData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            } else if (snapshot.hasError) {
              //======= TAMPILAN JIKA TERJADI ERROR API =======
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 80, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      "Gagal mengambil data",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            } else {
              //======= FUTURE BUILDER: MENGAMBIL DATA FORECAST =======
              return FutureBuilder(
                future: forecastData,
                builder: (context, forecastSnapshot) {
                  if (!forecastSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snapshot.data!;
                  final isCelsius = MyApp.of(context).isCelsius;

                  final temp = formatTemperature(
                    data['main']['temp'],
                    isCelsius,
                    decimalPlaces: 1,
                  );
                  final weather = data['weather'][0]['description']
                      .toString()
                      .toLowerCase();
                  final forecast = forecastSnapshot.data!['list'];

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          //======= KARTU UTAMA (MAIN WEATHER CARD) =======
                          Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(25),
                              child: Column(
                                children: [
                                  Icon(
                                    getWeatherIcon(
                                      weather,
                                    ),
                                    size: 90,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    data['name'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    temp,
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    translateWeather(
                                      weather,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 25,
                                  ),

                                  //======= GRID INFO DETAIL (BARIS 1: TERASA & LEMBAP) =======
                                  Row(
                                    children: [
                                      Expanded(
                                        child: detailCard(
                                          Icons.thermostat,
                                          "Terasa",
                                          formatTemperature(
                                            data['main']['feels_like'],
                                            isCelsius,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: detailCard(
                                          Icons.water_drop,
                                          "Lembap",
                                          "${data['main']['humidity']}%",
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 10,
                                  ),

                                  //======= GRID INFO DETAIL (BARIS 2: ANGIN & TEKANAN) =======
                                  Row(
                                    children: [
                                      Expanded(
                                        child: detailCard(
                                          Icons.air,
                                          "Angin",
                                          "${data['wind']['speed']} m/s",
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child: detailCard(
                                          Icons.speed,
                                          "Tekanan",
                                          "${data['main']['pressure']} hPa",
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 30,
                          ),

                          //======= BAGIAN FORECAST 5 HARI =======
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Forecast 5 Hari",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 15,
                          ),

                          //======= LIST HORIZONTAL (WIDGET SCROLL) FORECAST =======
                          SizedBox(
                            height: 150,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(
                                  5,
                                  (index) {
                                    final item = forecast[index * 8];

                                    return Container(
                                      width: 95,
                                      margin: const EdgeInsets.only(
                                        right: 12,
                                      ),
                                      child: Card(
                                        elevation: 5,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(
                                            12,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Text(
                                                getHari(
                                                  item['dt_txt'],
                                                ),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(
                                                getWeatherIcon(
                                                  item['weather'][0]['main']
                                                      .toString()
                                                      .toLowerCase(),
                                                ),
                                                size: 26,
                                                color: Colors.blue,
                                              ),
                                              Text(
                                                formatTemperature(
                                                  item['main']['temp'],
                                                  isCelsius,
                                                ),
                                              ),
                                              Text(
                                                translateWeather(
                                                  item['weather'][0]['main'],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  //======= WIDGET KUSTOM: KARTU DETAIL KECIL =======
  // (Digunakan untuk menampilkan parameter cuaca seperti kelembapan, angin, dll)
  Widget detailCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.blue,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            title,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
