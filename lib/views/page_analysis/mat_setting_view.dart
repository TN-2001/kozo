import 'package:flutter/material.dart';
import 'package:kozo/components/decorations.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/models/data.dart';

class MatSetting extends StatefulWidget {
  const MatSetting({super.key, required this.matList});
  final List<Mat> matList;

  @override
  State<MatSetting> createState() => _MatSettingState();
}

class _MatSettingState extends State<MatSetting> {
  late final List<Mat> matList;
  late final int selectedNumber = 0;

  @override
  void initState() {
    super.initState();

    matList = widget.matList;
  }

  @override
  Widget build(BuildContext context) {
    return MyAlign(
      alignment: Alignment.center,
      child: Container(
        width: 500,
        height: 500,
        margin: const EdgeInsets.all(50),
        padding: const EdgeInsets.all(5),
        decoration: myBoxDecoration,
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: ListView(
                children: [
                  for(int i = 0; i < matList.length; i++)...{
                    ChoiceChip(
                      label: Text("No.${i+1}"),
                      selected: selectedNumber == 2,
                      onSelected: (_){
                        setState(() {
                          selectedNumber == i;
                        });
                      },
                    ),
                  },
                  ElevatedButton(
                    onPressed: (){
                      setState(() {
                        matList.add(Mat());
                      });
                    }, 
                    style: myButtonStyle,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const VerticalDivider(color: MyColors.border,),
            if(matList.isNotEmpty)...{
              SizedBox(
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          Container(width: 100, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("ヤング率"),),
                          SizedBox(width: 100, child: TextField(
                            controller: TextEditingController(text: matList[selectedNumber].e.toString()),
                            inputFormatters: myInputFormattersNumber,
                            decoration: myInputDecoration,
                            onChanged: (value) {
                              if(double.tryParse(value) != null){
                                setState(() {
                                  matList[selectedNumber].e = double.parse(value);
                                });
                              }
                            },
                          )),
                        ],
                      )
                    ),
                    const SizedBox(height: 5,),
                    SizedBox(
                      height: 30,
                      child: Row(
                        children: [
                          Container(width: 100, alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 5, right: 5), child: const Text("ポアソン比"),),
                          SizedBox(width: 100, child: TextField(
                            controller: TextEditingController(text: matList[selectedNumber].v.toString()),
                            inputFormatters: myInputFormattersNumber,
                            decoration: myInputDecoration,
                            onChanged: (value) {
                              if(double.tryParse(value) != null){
                                setState(() {
                                  matList[selectedNumber].v = double.parse(value);
                                });
                              }
                            },
                          )),
                        ],
                      )
                    ),
                  ],
                ),
              ),
            }
          ],
        ),
      )
    );
  }
}