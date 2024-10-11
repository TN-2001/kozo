import 'package:flutter/material.dart';

// ignore: must_be_immutable
class PageHome extends StatelessWidget {
  const PageHome({super.key, required this.onTap});

  static const list = ["解析","橋の解析"];
  
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Container(
            alignment: Alignment.center,
            child: const Text(
              '構造力学',
              style: TextStyle(
                fontSize: 30,
              ),
            ),
          ),
        ),

        const Divider(),

        Column(
          children: [
            for(int i = 0; i < list.length; i++)
              ListTile(
                title: Text(list[i]), 
                onTap: (){
                  onTap(i);
                },
              ),
          ]
        )
      ],
    );
  }
}