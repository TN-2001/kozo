import 'package:flutter/material.dart';
import 'package:kozo/components/decorations.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class NodeSetting extends StatelessWidget {
  const NodeSetting({super.key, required this.node, required this.title, required this.endButtonName, required this.onChageParameter, required this.onEndButton, required this.isUpdate, required this.onUpdate});

  final Node node;
  final String title, endButtonName;
  final void Function() onChageParameter, onUpdate, onEndButton;
  final bool isUpdate;

  @override
  Widget build(BuildContext context) {
    return MyAlign(
      alignment: Alignment.bottomCenter,
      isIntrinsicWidth: true,
      isIntrinsicHeight: true,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: myBoxDecoration,
        child: Column(
          children: [
            Container(
              height: 25,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 5, right: 5), 
              child: Text(title),
            ),
            const SizedBox(height: 2.5,),
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  MyContainer(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("位置"),),
                  MyContainer(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("x"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.pos.dx.toString()),
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        node.pos = Offset(double.parse(value), node.pos.dy);
                        onChageParameter();
                      }
                    },
                  )),
                  MyContainer(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("y"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.pos.dy.toString()), 
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        node.pos = Offset(node.pos.dx, double.parse(value));
                        onChageParameter();
                      }
                    },
                  )),
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("拘束"),),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("x"),),
                  Container(width: 100, alignment: Alignment.centerLeft, 
                    child: Checkbox(
                      value: node.constXY[0],
                      onChanged: (value) {
                        node.constXY[0] = value!;
                        onUpdate();
                      },
                    )
                  ),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("y"),),
                  Container(width: 100, alignment: Alignment.centerLeft, child: Checkbox(
                    value: node.constXY[1],
                    onChanged: (value) {
                      node.constXY[1] = value!;
                      onUpdate();
                    },
                  )),
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("集中荷重"),),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("x"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.loadXY[0].toString()),
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        node.loadXY[0] = double.parse(value);
                        onChageParameter();
                      }
                    },
                  )),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("y"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: node.loadXY[1].toString()), 
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        node.loadXY[1] = double.parse(value);
                        onChageParameter();
                      }
                    },
                  )),
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            SizedBox(
              width: double.infinity,
              height: 25,
              child: Row(
                children: [
                  const Expanded(
                    child: SizedBox(), 
                  ),
                  ElevatedButton(
                    onPressed: () {
                      onEndButton();
                    },
                    style: myButtonStyleBorder,
                    child: Text(endButtonName),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}