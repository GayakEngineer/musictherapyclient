import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MorningAudioPlayerModel()),
        ChangeNotifierProvider(create: (_) => AfternoonAudioPlayerModel()),
        ChangeNotifierProvider(create: (_) => EveningAudioPlayerModel()),
        ChangeNotifierProvider(create: (_) => NightAudioPlayerModel()),
        StreamProvider<InternetConnectionStatus>(
          create: (_) => InternetConnectionChecker().onStatusChange,
          initialData: InternetConnectionStatus.connected,
        ),
      ],
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if the user is logged in by reading SharedPreferences
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // If user is logged in, navigate to the HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // If not logged in, show the LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _pinController = TextEditingController();
  String error = '';

  // Function to check if user exists in Firestore
  Future<bool> _checkUserExists(String userID) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentSnapshot doc = await firestore.collection('users').doc(userID).get();

    // Return true if the document exists, false otherwise
    return doc.exists;
  }

  void _login() async {
    String userID = _pinController.text.trim();

    // Check if the entered userID exists in Firestore
    bool userExists = await _checkUserExists(userID);

    if (userExists) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userID', userID);

      // Navigate to HomePage if user exists
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      // Show error if user doesn't exist
      setState(() {
        error = 'Invalid PIN: No user found with this ID';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'Enter 4-digit PIN',
                errorText: error.isNotEmpty ? error : null,
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
            const SizedBox(height: 45),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DocumentSnapshot documentSnapshot;
 bool isLoading = true;
 bool expired=false;
  late String expiryStatus;
  
  @override
  void initState() {
    super.initState();
    getData();
  }
  void dateCalc()async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
              
    
    if (documentSnapshot.exists) {
      DateTime expiryDate = documentSnapshot.get('expiry_date').toDate();
      int daysRemaining = expiryDate.difference(DateTime.now()).inDays;

      if (daysRemaining < 0) {
        expiryStatus = 'Audio expired';
        await prefs.setBool('expired', true);
      } else if (daysRemaining == 0) {
        expiryStatus = 'Audio expires today';
        await prefs.setBool('expired', false);
      } else {
        expiryStatus = '$daysRemaining';
        await prefs.setBool('expired', false);
      }
    } else {
      expiryStatus = 'No data available';
    }
          }

  void getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID=prefs.getString('userID')??'0000';
    expired=prefs.getBool('expired')??false;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      // Fetch document from Firestore
      documentSnapshot = await firestore.collection('users').doc(userID).get();

      dateCalc();
    } catch (e) {
      print('Error fetching data: $e');
    } finally {
      // Stop loading once the data is fetched
      setState(() {
        isLoading = false;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final internetStatus = Provider.of<InternetConnectionStatus>(context);
    bool isConnected = internetStatus == InternetConnectionStatus.connected;
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: ()async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn');
              await prefs.remove('userID');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child:!expired? Column(
              children: [
                !documentSnapshot.get('morningempty')?MorningAudioContainer(
                    title: 'Morning', isConnected: isConnected):const SizedBox(),
                !documentSnapshot.get('afternoonempty')?AfternoonAudioContainer(
                    title: 'Afternoon', isConnected: isConnected):const SizedBox(),
                !documentSnapshot.get('eveningempty')?EveningAudioContainer(
                    title: 'Evening', isConnected: isConnected):const SizedBox(),
                !documentSnapshot.get('nightempty')?NightAudioContainer(title: 'Night', isConnected: isConnected):const SizedBox(),
              ],
            ): const Center(child: Text("Audios expired. Ask admin to renew audios"),),
          ),
          Text("Days left : $expiryStatus", style: const TextStyle(fontSize: 16),)
        ],
      ),
    );
  }
}

class MorningAudioContainer extends StatefulWidget {
  final String title;
  final bool isConnected;

  const MorningAudioContainer({
    super.key,
    required this.title,
    required this.isConnected,
  });

  @override
  _MorningAudioContainerState createState() => _MorningAudioContainerState();
}

class _MorningAudioContainerState extends State<MorningAudioContainer> {
  Future<DocumentSnapshot> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '0000';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch document from Firestore
      return await firestore.collection('users').doc(userID).get();
    } catch (e) {
      print('Error fetching data: $e');
      rethrow; // Rethrow the error to handle it in FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<MorningAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;

    return FutureBuilder<DocumentSnapshot>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading audio');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No audio data available');
        }

        final documentSnapshot = snapshot.data!;
        if (documentSnapshot.exists) {
          player.setUrl(documentSnapshot.get('morning'), preload: true);
        }

        return AudioPlayerUI(
          title: widget.title,
          player: player,
          isConnected: widget.isConnected,
        );
      },
    );
  }
}

class AfternoonAudioContainer extends StatefulWidget {
  final String title;
  final bool isConnected;

  const AfternoonAudioContainer({
    super.key,
    required this.title,
    required this.isConnected,
  });

  @override
  _AfternoonAudioContainerState createState() => _AfternoonAudioContainerState();
}

class _AfternoonAudioContainerState extends State<AfternoonAudioContainer> {
  Future<DocumentSnapshot> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '0000';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch document from Firestore
      return await firestore.collection('users').doc(userID).get();
    } catch (e) {
      print('Error fetching data: $e');
      throw e; // Rethrow the error to handle it in FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<AfternoonAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;

    return FutureBuilder<DocumentSnapshot>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading audio');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No audio data available');
        }

        final documentSnapshot = snapshot.data!;
        if (documentSnapshot.exists) {
          player.setUrl(documentSnapshot.get('afternoon'), preload: true);
        }

        return AudioPlayerUI(
          title: widget.title,
          player: player,
          isConnected: widget.isConnected,
        );
      },
    );
  }
}

class EveningAudioContainer extends StatefulWidget {
  final String title;
  final bool isConnected;

  const EveningAudioContainer({
    super.key,
    required this.title,
    required this.isConnected,
  });

  @override
  _EveningAudioContainerState createState() => _EveningAudioContainerState();
}

class _EveningAudioContainerState extends State<EveningAudioContainer> {
  Future<DocumentSnapshot> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '0000';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch document from Firestore
      return await firestore.collection('users').doc(userID).get();
    } catch (e) {
      print('Error fetching data: $e');
      throw e; // Rethrow the error to handle it in FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<EveningAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;

    return FutureBuilder<DocumentSnapshot>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading audio');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No audio data available');
        }

        final documentSnapshot = snapshot.data!;
        if (documentSnapshot.exists) {
          player.setUrl(documentSnapshot.get('evening'), preload: true);
        }

        return AudioPlayerUI(
          title: widget.title,
          player: player,
          isConnected: widget.isConnected,
        );
      },
    );
  }
}

class NightAudioContainer extends StatefulWidget {
  final String title;
  final bool isConnected;

  const NightAudioContainer({
    super.key,
    required this.title,
    required this.isConnected,
  });

  @override
  _NightAudioContainerState createState() => _NightAudioContainerState();
}

class _NightAudioContainerState extends State<NightAudioContainer> {
  Future<DocumentSnapshot> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userID = prefs.getString('userID') ?? '0000';
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // Fetch document from Firestore
      return await firestore.collection('users').doc(userID).get();
    } catch (e) {
      print('Error fetching data: $e');
      throw e; // Rethrow the error to handle it in FutureBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<NightAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;

    return FutureBuilder<DocumentSnapshot>(
      future: getData(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading audio');
        } else if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text('No audio data available');
        }

        final documentSnapshot = snapshot.data!;
        if (documentSnapshot.exists) {
          player.setUrl(documentSnapshot.get('night'), preload: true);
        }

        return AudioPlayerUI(
          title: widget.title,
          player: player,
          isConnected: widget.isConnected,
        );
      },
    );
  }
}

class AudioPlayerUI extends StatelessWidget {
  final String title;
  final AudioPlayer player;
  final bool isConnected;
  const AudioPlayerUI(
      {super.key,
      required this.title,
      required this.player,
      required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (!isConnected) const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Color(0xFFfc3503),),
                  Text("No internet connection!"),
                ],
              ),
            ),
            if (isConnected)
              Column(
                children: [
                  StreamBuilder<PlayerState>(
                    stream: player.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final processingState = playerState?.processingState;
                      final playing = playerState?.playing;

                      return Row(
                        children: [
                          IconButton(
                            iconSize:
                                36, // Adjust the size of the button if necessary
                            icon: (processingState == ProcessingState.buffering)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    playing == true
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                            onPressed: () {
                              if (playing == true) {
                                player.pause();
                              } else {
                                player.play();
                              }
                            },
                          ),
                          Expanded(
                            child: StreamBuilder<Duration>(
                              stream: player.positionStream,
                              builder: (context, snapshot) {
                                final position = snapshot.data ?? Duration.zero;
                                final totalDuration =
                                    player.duration ?? Duration.zero;
                                return Column(
                                  children: [
                                    Slider(
                                      value: position.inSeconds.toDouble(),
                                      max: totalDuration.inSeconds.toDouble(),
                                      onChanged: (value) {
                                        player.seek(
                                            Duration(seconds: value.toInt()));
                                      },
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatDuration(position)),
                                        Text(_formatDuration(totalDuration)),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

class MorningAudioPlayerModel extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}

class AfternoonAudioPlayerModel extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}

class EveningAudioPlayerModel extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}

class NightAudioPlayerModel extends ChangeNotifier {
  final AudioPlayer audioPlayer = AudioPlayer();

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }
}
