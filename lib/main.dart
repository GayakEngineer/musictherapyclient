import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  void _login()async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     await prefs.setBool('isLoggedIn', true); 
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
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
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final internetStatus = Provider.of<InternetConnectionStatus>(context);
    bool isConnected = internetStatus == InternetConnectionStatus.connected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: ()async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('isLoggedIn'); 
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
            child: Column(
              children: [
                MorningAudioContainer(
                    title: 'Morning', isConnected: isConnected),
                AfternoonAudioContainer(
                    title: 'Afternoon', isConnected: isConnected),
                EveningAudioContainer(
                    title: 'Evening', isConnected: isConnected),
                NightAudioContainer(title: 'Night', isConnected: isConnected),
              ],
            ),
          ),
          const Text("Expiry Date")
        ],
      ),
    );
  }
}

class MorningAudioContainer extends StatelessWidget {
  final String title;
  final bool isConnected;
  MorningAudioContainer(
      {super.key, required this.title, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<MorningAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;
    player.setUrl(
        'https://file.notion.so/f/f/03eb2569-ebdb-4a4d-8f90-c73374d805cc/d89230a3-c4db-494b-b71f-13908d9f72f1/Addha_Teental.mp3?table=block&id=103ab9a5-784f-806b-ac55-fd6fda3fb425&spaceId=03eb2569-ebdb-4a4d-8f90-c73374d805cc&expirationTimestamp=1726574400000&signature=QBOene20qkXzKTS5EUu5SF9NY7qNO9azDJmENK1Jspo', preload: true);

    return AudioPlayerUI(
      title: title,
      player: player,
      isConnected: isConnected,
    );
  }
}

class AfternoonAudioContainer extends StatelessWidget {
  final String title;
  final bool isConnected;
  AfternoonAudioContainer(
      {super.key, required this.title, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<AfternoonAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;
    player.setUrl(
        'https://file.notion.so/f/f/03eb2569-ebdb-4a4d-8f90-c73374d805cc/411bf95d-f2da-48f4-931b-6224b787ab49/Ghazal_Taal.m4a?table=block&id=103ab9a5-784f-80ac-9f50-c1503b759878&spaceId=03eb2569-ebdb-4a4d-8f90-c73374d805cc&expirationTimestamp=1726574400000&signature=QYMh_nSCd9avcqGccR_c8G8n_At00RTHTvZp4GJ6POg', preload: true);

    return AudioPlayerUI(
      title: title,
      player: player,
      isConnected: isConnected,
    );
  }
}

class EveningAudioContainer extends StatelessWidget {
  final String title;
  final bool isConnected;
  EveningAudioContainer(
      {super.key, required this.title, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<EveningAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;
    player.setUrl(
        '', preload: true);

    return AudioPlayerUI(
      title: title,
      player: player,
      isConnected: isConnected,
    );
  }
}

class NightAudioContainer extends StatelessWidget {
  final String title;
  final bool isConnected;
  NightAudioContainer(
      {super.key, required this.title, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    final audioPlayerModel = Provider.of<NightAudioPlayerModel>(context);
    final player = audioPlayerModel.audioPlayer;

    return AudioPlayerUI(
      title: title,
      player: player,
      isConnected: isConnected,
    );
  }
}

class AudioPlayerUI extends StatelessWidget {
  final String title;
  final AudioPlayer player;
  final bool isConnected;
  AudioPlayerUI(
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
                  Icon(Icons.warning_amber),
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
