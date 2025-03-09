import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kozo/apps/beam/beam_page.dart';
import 'package:kozo/apps/bridge/bridge_page.dart';
import 'package:kozo/apps/bridgegame/bridgegame_page.dart';
import 'package:kozo/apps/privacy/privacy_page.dart';
import 'package:kozo/apps/truss/truss_page.dart';
import 'package:kozo/components/my_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_web_plugins/flutter_web_plugins.dart'; // Webアプリのときだけ

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setUrlStrategy(PathUrlStrategy()); // Webアプリのときだけ

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: "kozo | 茨城大学 構造・地震工学研究室",
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const BeamPage(),
        '/truss':(context) => const TrussPage(),
        '/bridge':(context) => const BridgePage(),
        '/bridgegame':(context) => const BridgegamePage(),
        '/privacy':(context) => const PrivacyPage(),
      },
    );
  }
}

Widget drawer(BuildContext context){
  return MyDrawer(
    title: "ツール",
    itemList: const ["「はり」の計算", "「トラス」の計算", "橋作り", "橋作り（ゲーム）", "ヘルプ"], 
    onTap: (number){
      String currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
      if(number <= 3){
        String targetRoute;

        if (number == 0) {
          targetRoute = '/';
        } else if (number == 1) {
          targetRoute = '/truss';
        } else if (number == 2) {
          targetRoute = '/bridge';
        } else {
          targetRoute = '/bridgegame';
        }

        Navigator.pop(context);

        if (currentRoute != targetRoute) {
          Navigator.pushNamed(context, targetRoute);
        }
      }else{
        String videoId;
        String viewId;
        if(currentRoute == '/'){
          videoId = '44JrBWd-lS4';
          viewId = '1';
        }else if(currentRoute == '/truss'){
          videoId = 'heslu9QKW1E';
          viewId = '2';
        }else{
          videoId = '9TabbZ8wR9A';
          viewId = '3';
        }

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("使い方（動画リンク）"),
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width / 1.5,
                height: MediaQuery.sizeOf(context).width / 1.5 /16*9,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: (){
                      final url = Uri.parse('https://youtu.be/$videoId');
                      launchUrl(url);
                    },
                    child: Image.asset(
                      "assets/images/youtube/$viewId.jpg",
                    )
                  ),
                ),
              ),
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