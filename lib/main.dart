import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:kozo/apps/beam/beam_page.dart';
import 'package:kozo/apps/bridge/bridge_page.dart';
import 'package:kozo/apps/privacy/privacy_page.dart';
import 'package:kozo/apps/truss/truss_page.dart';
import 'package:kozo/components/my_widgets.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy());

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: "kozo",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const BeamPage(),
        '/truss':(context) => const TrussPage(),
        '/bridge':(context) => const BridgePage(),
        '/privacy':(context) => const PrivacyPage(),
      },
    );
  }
}

Widget drawer(BuildContext context){
  return MyDrawer(
    title: "ツール",
    itemList: const ["「はり」の計算", "「トラス」の計算", "橋作りゲーム", "ヘルプ"], 
    onTap: (number){
      String currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
      if(number <= 2){
        String targetRoute;

        if (number == 0) {
          targetRoute = '/';
        } else if (number == 1) {
          targetRoute = '/truss';
        } else{
          targetRoute = '/bridge';
        }

        Navigator.pop(context);

        if (currentRoute != targetRoute) {
          Navigator.pushNamed(context, targetRoute);
        }
      }else{
        String videoId;
        if(currentRoute == '/'){
          videoId = '44JrBWd-lS4';
        }else if(currentRoute == '/truss'){
          videoId = 'heslu9QKW1E';
        }else{
          videoId = '9TabbZ8wR9A';
        }

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("使い方（動画）"),
              content: VideoPlayerScreen(videoId: videoId),
              actions: [
                TextButton(
                  child: const Text("閉じる"),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      }
    }
  );
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.videoId});

  final String videoId;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // YouTubeの動画IDを指定してコントローラーを初期化
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      params: const YoutubePlayerParams(
        mute: true,
        showControls: true,
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();  // YouTubeプレイヤーを破棄
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width / 1.5,
      child: YoutubePlayer(
        controller: _controller,
        aspectRatio: 16 / 9,
      ),
    );
  }
}