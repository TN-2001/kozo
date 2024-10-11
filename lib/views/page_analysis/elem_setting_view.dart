import 'package:flutter/material.dart';
import 'package:kozo/components/decorations.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class ElemSetting extends StatelessWidget {
  const ElemSetting({super.key, required this.elem, required this.title, required this.endButtonName, required this.onChageParameter, required this.onUpdate, required this.onEndButton, required this.isUpdate, required this.elemNodeNumber});

  final Elem elem;
  final int elemNodeNumber;
  final String title, endButtonName;
  final void Function() onChageParameter, onUpdate, onEndButton;
  final bool isUpdate;

  static List<String> nameList = ["a","b","c","d"];

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
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("節点番号"),),
                  for(int i = 0; i < elemNodeNumber; i++)...{
                    Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: Text(nameList[i]),),
                    SizedBox(width: 100, child: TextField(
                      controller: TextEditingController(text: (elem.nodeList[i]+1).toString()),
                      inputFormatters: myInputFormattersNumber,
                      decoration: myInputDecoration,
                      onChanged: (value) {
                        if(int.tryParse(value) != null){
                          elem.nodeList[i] = int.parse(value)-1;
                          onChageParameter();
                        }
                      },
                    )),
                  }
                ],
              )
            ),
            const SizedBox(height: 2.5,),
            Container(
              height: 25,
              alignment: Alignment.center,
              child: Row(
                children: [
                  Container(width: 75, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("パラメータ"),),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("ヤング率"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: elem.e.toString()),
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        elem.e = double.parse(value);
                        onChageParameter();
                      }
                    },
                  )),
                  Container(width: 25, alignment: Alignment.centerRight, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("断"),),
                  SizedBox(width: 100, child: TextField(
                    controller: TextEditingController(text: elem.v.toString()),
                    inputFormatters: myInputFormattersNumber,
                    decoration: myInputDecoration,
                    onChanged: (value) {
                      if(double.tryParse(value) != null){
                        elem.v = double.parse(value);
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