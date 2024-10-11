import 'package:flutter/material.dart';
// import 'package:kozo/components/decorations.dart';
import 'package:kozo/models/data.dart';
import 'package:kozo/components/widgets.dart';
import 'package:kozo/utils/event_emitter.dart';
import 'package:kozo/views/page_analysis/canvas_view.dart';
import 'package:kozo/views/page_analysis/elem_setting_view.dart';
import 'package:kozo/views/page_analysis/mat_setting_view.dart';
import 'package:kozo/views/page_analysis/node_setting_view.dart';

class PageAnalysis extends StatefulWidget {
  const PageAnalysis({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageAnalysis> createState() => _PageAnalysis();
}

class _PageAnalysis extends State<PageAnalysis> {
  late GlobalKey<ScaffoldState> scaffoldKey;
  late Data data;
  String debugText = "";
  Node newNode = Node();
  Elem newElem = Elem();
  final EventEmitter updateEvent = EventEmitter();
  late bool isCanvasUpdate = true, isSettingUpdate = true;
  List<String> devTypes = ["応力","ひずみ"];
  int elemTypeNum = 0, toolTypeNum = 0, toolNum = 0, devTypeNum = 0;


  @override
  void initState() {
    super.initState();

    scaffoldKey = widget.scaffoldKey;
    data = Data(onDebug: (value){
      // setState(() {
      //   if(debugText != ""){
      //     debugText = "$debugText\n$value";
      //   }else{
      //     debugText = value;
      //   }
      // });
      if(debugText != ""){
        debugText += "\n";
      }
      debugText += value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MyScaffold(
      header: MyHeaderMenu(
        children: [
          // メニューボタン
          MyMenuIconButton(
            icon: Icons.menu, 
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // エレメントのタイプ
            // MyMenuDropdown(
            //   items: const ['トラス', '3角形', '4角形'],
            //   value: elemTypeNum, 
            //   onPressed: (value){
            //     setState(() {
            //       elemTypeNum = value;
            //       data.elemNode = elemTypeNum + 2;
            //       newNode = Node();
            //       data.selectedNumber = -1;
            //       if(elemTypeNum == 0){
            //         devTypes = ["応力","ひずみ"];
            //       }else{
            //         devTypes = ["x応力","y応力","xひずみ","yひずみ"];
            //       }
            //     });
            //   }
            // ),
            // ツールタイプ
            MyMenuToggleButtons(
              icons: const [Icons.circle, Icons.square], 
              value: toolTypeNum, 
              onPressed: (value){
                setState(() {
                  toolTypeNum = value;
                  toolNum = 0;
                  newNode = Node();
                  data.selectedNumber = -1;
                });
              }
            ),
            // ツール
            if(toolTypeNum < 2)...{
              MyMenuToggleButtons(
                icons: const [Icons.add, Icons.touch_app], 
                value: toolNum, 
                onPressed: (value){
                  setState(() {
                    toolNum = value;
                    newNode = Node();
                    data.selectedNumber = -1;
                  });
                }
              ),
            }
          },
          const Expanded(child: SizedBox()),
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyMenuIconButton(
              icon: Icons.play_arrow,
              onPressed: (){
                setState(() {
                  data.calculation();
                });
              },
            ),
          }else...{
            // 解析結果選択
            MyMenuDropdown(
              items: devTypes,
              value: devTypeNum,
              onPressed: (value){
                setState(() {
                  devTypeNum = value;
                  data.selectResult(value);
                });
                updateEvent.emit(null);
              },
            ),
            // 再開ボタン
            MyMenuIconButton(
              icon: Icons.restart_alt,
              onPressed: (){
                setState(() {
                  data.resetCalculation();
                });
              },
            ),
          }
        ]
      ),

      body: Stack(
        children: [
          // メインビュー
          MyCustomPaint(
            onTap: (position) {
              setState(() {
                if(toolNum == 1){
                  if(toolTypeNum == 0){
                    data.selectNode(position);
                  }
                  else if(toolTypeNum == 1){
                    data.selectElem(position);
                  }
                }
                data.selectedNumber = data.selectedNumber;
                isSettingUpdate = true;
              });
            },
            painter: MyPainter(data: data, isUpdate: isCanvasUpdate),
          ),
          if(data.isCalculation)...{
            // Align(
            //   alignment: Alignment.bottomCenter,
            //   child: Container(
            //     margin: const EdgeInsets.all(10),
            //     color: MyColors.wiget0,
            //     // decoration: myBoxDecoration,
            //     width: 500,
            //     height: 150,
            //     child: ListView(
            //       children: [
            //         Text(debugText),
            //       ],
            //     )
            //   ),
            // )
          }
          else if(toolTypeNum == 0)...{
            if(toolNum == 0)...{
              NodeSetting(
                node: newNode, 
                title: "No.${data.nodeList.length+1}", 
                endButtonName: "追加", 
                onChageParameter: (){isCanvasUpdate = true;}, 
                onUpdate: (){setState(() {
                  isSettingUpdate = true;
                });},
                onEndButton: (){
                  setState(() {
                    data.nodeList.add(newNode);
                    newNode = Node();
                  });
                },
                isUpdate: isSettingUpdate,
              ),
            }
            else if(data.selectedNumber >= 0)...{
              NodeSetting(
                node: data.nodeList[data.selectedNumber], 
                title: "No.${data.selectedNumber+1}", 
                endButtonName: "削除", 
                onChageParameter: (){isCanvasUpdate = true;}, 
                onUpdate: (){setState(() {
                  isSettingUpdate = true;
                });},
                onEndButton: (){
                  setState(() {
                    data.removeNode(data.selectedNumber);
                    data.selectedNumber = -1;
                  });
                },
                isUpdate: isSettingUpdate,
              ),
            }
          }
          else if(toolTypeNum == 1)...{
            if(toolNum == 0)...{
              ElemSetting(
                elem: newElem,
                title: "No.${data.elemList.length+1}",
                endButtonName: "追加", 
                onChageParameter: (){isCanvasUpdate = true;}, 
                onUpdate: (){setState(() {
                  isSettingUpdate = true;
                });},
                onEndButton: (){
                  for(int i = 0; i < data.elemNode; i++){
                    for(int j = 0; j < data.elemNode; j++){
                      if(i != j && newElem.nodeList[i] == newElem.nodeList[j]){
                        return;
                      }
                    }
                  }
                  for(int e = 0; e < data.elemList.length; e++){
                    int count = 0;
                    for(int i = 0; i < data.elemNode; i++){
                      for(int j = 0; j < data.elemNode; j++){
                        if(newElem.nodeList[i] == data.elemList[e].nodeList[j]){
                          count ++;
                          if(count == data.elemNode){
                            return;
                          }
                        }
                      }
                    }
                  }
                  setState(() {
                    data.elemList.add(newElem);
                    newElem = Elem();
                  });
                },
                isUpdate: isSettingUpdate, 
                elemNodeNumber: data.elemNode,
              )
            }
            else if(data.selectedNumber >= 0)...{
              ElemSetting(
                elem: data.elemList[data.selectedNumber],
                title: "No.${data.selectedNumber+1}",
                endButtonName: "削除", 
                onChageParameter: (){isCanvasUpdate = true;}, 
                onUpdate: (){setState(() {
                  isSettingUpdate = true;
                });},
                onEndButton: (){
                  setState(() {
                    data.elemList.removeAt(data.selectedNumber);
                    data.selectedNumber = -1;
                  });
                },
                isUpdate: isSettingUpdate, 
                elemNodeNumber: data.elemNode,
              )
            }
          }
          else if(toolTypeNum == 2)...{
            MatSetting(matList: data.matList,),
          }
        ]
      ),
    );
  }
}