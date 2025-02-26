import 'package:flutter/material.dart';
import 'package:kozo/apps/fem/fem_data.dart';
import 'package:kozo/apps/fem/fem_painter.dart';
import 'package:kozo/components/my_decorations.dart';
import 'package:kozo/components/my_widgets.dart';

class PageFem extends StatefulWidget {
  const PageFem({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  State<PageFem> createState() => _PageFemState();
}

class _PageFemState extends State<PageFem> {
  late GlobalKey<ScaffoldState> scaffoldKey;
  late FemData data;
  int devTypeNum = 0;
  int toolTypeNum = 0, toolNum = 0;



  @override
  void initState() {
    super.initState();

    scaffoldKey = widget.scaffoldKey;
    data = FemData(onDebug: (value){},);
    data.node = Node();
  }

  @override
  Widget build(BuildContext context) {
    // 画面サイズ取得
    final Size size = MediaQuery.of(context).size;

    return MyScaffold(
      header: MyHeader(
        center: [
          // メニューボタン
          MyIconButton(
            icon: Icons.menu, 
            message: "メニュー",
            onPressed: (){
              scaffoldKey.currentState!.openDrawer();
            },
          ),
          if(!data.isCalculation)...{
            // ツールタイプ
            MyIconToggleButtons(
              icons: const [Icons.circle, Icons.rectangle], 
              messages: const ["節点", "要素"],
              value: toolTypeNum, 
              onPressed: (value){
                setState(() {
                  toolTypeNum = value;
                  data.node = null;
                  data.elem = null;
                  if(toolTypeNum == 0 && toolNum == 0){
                    data.node = Node();
                    data.node!.number = data.nodeList.length;
                  }else if(toolTypeNum == 1 && toolNum == 0){
                    data.elem = Elem();
                    data.elem!.number = data.elemList.length;
                  }
                  data.initSelect();
                });
              }
            ),
            // ツール
            MyIconToggleButtons(
              icons: const [Icons.add, Icons.touch_app], 
              messages: const ["新規","修正"],
              value: toolNum, 
              onPressed: (value){
                setState(() {
                  toolNum = value;
                  data.node = null;
                  data.elem = null;
                  if(toolTypeNum == 0 && toolNum == 0){
                    data.node = Node();
                    data.node!.number = data.nodeList.length;
                  }else if(toolTypeNum == 1 && toolNum == 0){
                    data.elem = Elem();
                    data.elem!.number = data.elemList.length;
                  }
                  data.initSelect();
                });
              }
            ),
          },
          const Expanded(child: SizedBox()),
          if(!data.isCalculation)...{
            // 解析開始ボタン
            MyIconButton(
              icon: Icons.play_arrow,
              message: "計算",
              onPressed: (){
                setState(() {
                  data.calculation();
                });
              },
            ),
          }else...{
            // 解析結果選択
            MyMenuDropdown(
              items: const ["X方向応力","y方向応力","せん断応力","X方向ひずみ","y方向ひずみ","せん断ひずみ"],
              value: devTypeNum,
              onPressed: (value){
                setState(() {
                  devTypeNum = value;
                  data.selectResult(value);
                });
              },
            ),
            // 再開ボタン
            MyIconButton(
              icon: Icons.restart_alt,
              message: "再編集",
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
              if(!data.isCalculation){
                setState(() {
                  if(toolNum == 1){
                    if(toolTypeNum == 0){
                      data.selectNode(position);
                    }
                    else if(toolTypeNum == 1){
                      data.selectElem(position, 0);
                    }
                  }
                  data.selectedNumber = data.selectedNumber;
                });
                if(toolNum == 0 && toolTypeNum == 1){
                  data.selectNode(position);
                  newElem(data.nodeList[data.selectedNumber]);
                }
              }
            },
            painter: FemPainter(data: data, devTypeNum: devTypeNum),
          ),

          // 設定
          if(!data.isCalculation)...{
            if(toolTypeNum == 0)...{
              if(toolNum == 0)...{
                // 新規ノード
                nodeSetting(true, size.width),
              }
              else if(data.selectedNumber >= 0)...{
                // 既存ノード
                nodeSetting(false, size.width),
              }
            }
            else if(toolTypeNum == 1)...{
              if(toolNum == 0)...{
                // 新規要素
                textElem(),
              }
              else if(data.selectedNumber >= 0)...{
                // 既存要素
                elemSetting(false, size.width),
              }
            }
          },

        ]
      ),
    );
  }

  // 要素
  Widget textElem(){
    String text = "節点を3つ選択して要素作成\nNo. ${data.elemList.length+1}";
    if(data.elem!.nodeList[0] != null){
      text += "   a：${data.elem!.nodeList[0]!.number+1}";
    }else{
      text += "   a： ";
    }
    if(data.elem!.nodeList[1] != null){
      text += "   b：${data.elem!.nodeList[1]!.number+1}";
    }else{
      text += "   b： ";
    }
    if(data.elem!.nodeList[2] != null){
      text += "   c：${data.elem!.nodeList[2]!.number+1}";
    }else{
      text += "   c： ";
    }

    return MyAlign(
      alignment: Alignment.bottomCenter,
      isIntrinsicHeight: true,
      isIntrinsicWidth: true,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        child: Text(text),
      ),
    );
  }

  // 要素生成
  void newElem(Node node){
    if(data.elem!.nodeList[0] == null){
      data.elem!.nodeList[0] = node;
    }else if(data.elem!.nodeList[1] == null){
      data.elem!.nodeList[1] = node;
    }else if(data.elem!.nodeList[2] == null){
      data.elem!.nodeList[2] = node;
      setState(() {
        data.addElem();
        data.initSelect();
      });
    }
  }

  Widget setting(List<MyProperty> propertyList, String title, String buttonName, Function() onButtonPressed, double width) {
    return MyAlign(
      alignment: Alignment.bottomCenter,
      isIntrinsicHeight: true,
      isIntrinsicWidth: true,
      child: Container(
        margin: const EdgeInsets.all(10),
        padding: const EdgeInsets.all(5),
        decoration: myBoxDecoration,
        child: Column(children: [
          MyProperty(
            name: title,
            width: (width > 505) ? 475 : width-30,
            buttonName: buttonName,
            onButtonPressed: onButtonPressed,
          ),
          const SizedBox(height: 5,),
          const Divider(height: 0, color: MyColors.border,),
          const SizedBox(height: 5,),
          for(int i = 0; i < propertyList.length; i++)...{
            propertyList[i],
            if(i < propertyList.length-1)...{
              const SizedBox(height: 2.5,),
            }
          },
        ],),
      )
      
    );
  }

  Widget nodeSetting(bool isAdd, double width) {
    double propWidth = (width > 505) ? 100 : (width-30-75-4)/4;
    double labelWidth = 75;

    List<MyProperty> propertyList(Node node) {
      MyProperty prop2_1(Node node) {
        return MyProperty(
          name: "X",
          labelAlignment: Alignment.centerRight,
          width: propWidth*2,
          boolValue: node.constXY[0],
          onChangedBool: (value) {
            setState(() {
              node.constXY[0] = value;
            });
          },
        );
      }
      MyProperty prop2_2(Node node) {
        return MyProperty(
          name: "Y",
          labelAlignment: Alignment.centerRight,
          width: propWidth*2,
          boolValue: node.constXY[1],
          onChangedBool: (value) {
            setState(() {
              node.constXY[1] = value;
            });
          },
        );
      }
      MyProperty prop3_1(Node node) {
        return MyProperty(
          name: "X",
          labelAlignment: Alignment.centerRight,
          width: propWidth*2,
          filledWidth: 75,
          doubleValue: (node.loadXY[0] != 0.0) ? node.loadXY[0] : null,
          onChangedDouble: (value) {
            node.loadXY[0] = value;
          },
        );
      }
      MyProperty prop3_2(Node node) {
        return MyProperty(
          name: "Y",
          labelAlignment: Alignment.centerRight,
          width: propWidth*2,
          filledWidth: 75,
          doubleValue: (node.loadXY[1] != 0.0) ? node.loadXY[1] : null,
          onChangedDouble: (value) {
            node.loadXY[1] = value;
          },
        );
      }

      return [
        MyProperty(
          name: "座標",
          labelWidth: labelWidth,
          children: [
            MyProperty(
              name: "X",
              labelAlignment: Alignment.centerRight,
              width: propWidth*2,
              filledWidth: 75,
              doubleValue: node.pos.dx,
              onChangedDouble: (value) {
                node.pos = Offset(value, node.pos.dy);
              },
            ),
            MyProperty(
              name: "Y",
              labelAlignment: Alignment.centerRight,
              width: propWidth*2,
              filledWidth: 75,
              doubleValue: node.pos.dy,
              onChangedDouble: (value) {
                node.pos = Offset(node.pos.dx, value);
              },
            )
          ],
        ),
        MyProperty(
          name: "拘束",
          labelWidth: labelWidth,
          children: [
            prop2_1(node),
            prop2_2(node),
          ],
        ),
        MyProperty(
          name: "変位",
          labelWidth: labelWidth,
          children: [
            prop3_1(node),
            prop3_2(node),
          ],
        ),
      ];
    }

    if(isAdd){
      // 追加時
      return setting(
        propertyList(data.node!), 
        "No. ${data.node!.number+1}", 
        "追加", 
        (){
          setState(() {
            data.addNode();
            data.initSelect();
          });
        },
        width
      );
    }
    else{
      // タッチ時
      return setting(
        propertyList(data.nodeList[data.selectedNumber]), 
        "No. ${data.nodeList[data.selectedNumber].number+1}", 
        "削除", 
        (){
          setState(() {
            data.removeNode(data.selectedNumber);
            data.initSelect();
          });
        },
        width
      );
    }
  }

  Widget elemSetting(bool isAdd, double width) {
    double propWidth = (width > 505) ? 100 : (width-30-75-4)/4;
    List<MyProperty> propertyList(Elem elem) {
      return [
        MyProperty(
          name: "節点番号",
          labelWidth: 75,
          children: [
            MyProperty(
              name: "a",
              labelAlignment: Alignment.centerRight,
              width: propWidth*1.33,
              filledWidth: 50,
              intValue: (elem.nodeList[0] != null) ? (elem.nodeList[0]!.number+1) : null,
              onChangedInt: (value) {
                if(value-1 >= 0 && value-1 < data.nodeList.length){
                  elem.nodeList[0] = data.nodeList[value-1];
                }else{
                  elem.nodeList[0] = null;
                }
              },
            ),
            MyProperty(
              name: "b",
              labelAlignment: Alignment.centerRight,
              width: propWidth*1.33,
              filledWidth: 50,
              intValue: (elem.nodeList[1] != null) ? (elem.nodeList[1]!.number+1) : null,
              onChangedInt: (value) {
                if(value-1 >= 0 && value-1 < data.nodeList.length){
                  elem.nodeList[1] = data.nodeList[value-1];
                }else{
                  elem.nodeList[1] = null;
                }
              },
            ),
            MyProperty(
              name: "c",
              labelAlignment: Alignment.centerRight,
              width: propWidth*1.33,
              filledWidth: 50,
              intValue: (elem.nodeList[2] != null) ? (elem.nodeList[2]!.number+1) : null,
              onChangedInt: (value) {
                if(value-1 >= 0 && value-1 < data.nodeList.length){
                  elem.nodeList[2] = data.nodeList[value-1];
                }else{
                  elem.nodeList[2] = null;
                }
              },
            ),
          ],
        ),
        MyProperty(
          name: "剛性",
          labelWidth: 75,
          children: [
            MyProperty(
              name: "ヤング率",
              labelAlignment: Alignment.centerRight,
              width: propWidth*2,
              filledWidth: 75,
              doubleValue: elem.e,
              onChangedDouble: (value) {
                elem.e = value;
              },
            ),
            MyProperty(
              name: "ポアソン比",
              labelAlignment: Alignment.centerRight,
              width: propWidth*2,
              filledWidth: 75,
              doubleValue: elem.v,
              onChangedDouble: (value) {
                elem.v = value;
              },
            ),
          ],
        ),
      ];
    }

    if(isAdd){
      // 追加時
      return setting(
        propertyList(data.elem!), 
        "No. ${data.elem!.number+1}", 
        "追加", 
        (){
          setState(() {
            data.addElem();
            data.initSelect();
          });
        },
        width
      );
    }
    else{
      // タッチ時
      return setting(
        propertyList(data.elemList[data.selectedNumber]), 
        "No. ${data.elemList[data.selectedNumber].number+1}",
        "削除", 
        (){
          setState(() {
            data.removeElem(data.selectedNumber);
            data.initSelect();
          });
        },
        width
      );
    }
  }
}