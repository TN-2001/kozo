import 'package:flutter/material.dart';
import 'package:kozo/components/widgets.dart';

class PageStudy extends StatelessWidget {
  const PageStudy({super.key, required this.onReturn});

  final void Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      header: MyHeaderMenu(
        children: [
          // 戻るボタン
          MyMenuIconButton(
            icon: Icons.keyboard_arrow_left_sharp, 
            onPressed: (){
              onReturn();
            },
          ),
        ]
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 7,
        child: Image.asset("assets/documents/test_01.jpg"),
      )
    );
  }
}