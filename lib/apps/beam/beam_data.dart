import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/utils/canvas_data.dart';
import 'package:kozo/utils/my_calculator.dart';
import 'package:kozo/apps/beam/beam2d_hinge_remesh.dart';

class BeamData{
  BeamData({required this.onDebug});
  final Function(String value) onDebug;

  // データ
  int elemNode = 2; // 要素節点数
  List<Node> nodeList = []; // 節点データ
  List<Elem> elemList = []; // 要素データ
  // 追加データ
  Node? node; // 新規節点データ
  Elem? elem; // 新規要素データ
  // 分割された結果のデータ
  List<Node> resultNodeList = [];
  List<Elem> resultElemList = [];

  // キャンバス座標
  CanvasData canvasData = CanvasData(); // キャンバス座標とデータ座標の変換

  bool isCalculation = false; // 解析したかどうか
  // 選択番号
  int selectedNumber = -1;

  // 全データ
  List<Node> allNodeList() // 節点データ+新規節点データ
  {
    List<Node> n = List.empty(growable: true);

    for(int i = 0; i < nodeList.length; i++){
      n.add(nodeList[i]);
    }
    if(node != null){
      node!.isSelect = true;
      n.add(node!);
    }

    return n;
  }
  List<Elem> allElemList() // 要素データ+新規要素データ
  {
    List<Elem> e = List.empty(growable: true);

    for(int i = 0; i < elemList.length; i++){
      e.add(elemList[i]);
    }
    if(elem != null){
      elem!.isSelect = true;
      e.add(elem!);
    }

    return e;
  }
  // 節点の範囲座標
  Rect rect(){
    List<Node> nodes = allNodeList();
    if(nodes.isEmpty) return Rect.zero; // 節点データがないとき終了

    double left = nodes[0].pos.dx;
    double right = nodes[0].pos.dx;
    double top = nodes[0].pos.dy;
    double bottom = nodes[0].pos.dy;

    if(allNodeList().length > 1){
      for (int i = 1; i < nodes.length; i++) {
        left = min(left, nodes[i].pos.dx);
        right = max(right, nodes[i].pos.dx);
        top = min(top, nodes[i].pos.dy);
        bottom = max(bottom, nodes[i].pos.dy);
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }


  // 追加削除
  void addNode()
  {
    // バグ対策
    if(node == null) return;
    for(int i = 0; i < nodeList.length; i++){
      if(node!.pos.dx == nodeList[i].pos.dx && node!.pos.dy == nodeList[i].pos.dy){
        return;
      }
    }

    // 追加
    nodeList.add(node!);
    node = Node();
    node!.number = nodeList.length;
  }
  void removeNode(int number)
  {
    // バグ対策
    if(nodeList.length-1 < number && nodeList.isNotEmpty) return;

    // 節点を使っている要素の削除
    for(int i = elemList.length-1; i >= 0; i--){
      for(int j = 0; j < elemNode; j++){
        if(elemList[i].nodeList[j]!.number == number){
          removeElem(i);
        }
      }
    }

    // 節点の削除
    nodeList.removeAt(number);

    // 節点の番号を修正
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].number = i;
    }
  }
  void addElem()
  {
    // バグ対策
    if(elem == null) return;
    for(int i = 0; i < elemNode; i++){
      if(elem!.nodeList[1] == null) return;
    }
    for(int i = 0; i < elemNode; i++){
      for(int j = 0; j < elemNode; j++){
        if(i != j && elem!.nodeList[i] == elem!.nodeList[j]){
          return;
        }
      }
    }
    for(int e = 0; e < elemList.length; e++){
      int count = 0;
      for(int i = 0; i < elemNode; i++){
        for(int j = 0; j < elemNode; j++){
          if(elem!.nodeList[i] == elemList[e].nodeList[j]){
            count ++;
            if(count == elemNode){
              return;
            }
          }
        }
      }
    }

    // 追加
    elemList.add(elem!);
    elem = Elem();
    elem!.number = elemList.length;
  }
  void removeElem(int number)
  {
    // バグ対策
    if(elemList.length-1 < number && elemList.isNotEmpty) return;

    // 要素の削除
    elemList.removeAt(number);

    // 要素の番号を修正
    for(int i = 0; i < elemList.length; i++){
      elemList[i].number = i;
    }
  }

  // 解析
  void calculation(){
    // バグ対策
    if(nodeList.isEmpty) return;
    if(elemList.isEmpty) return;
    for(int i = 0; i < elemList.length; i++){
      if(elemList[i].e <= 0 || elemList[i].v <= 0){
        return;
      }
      for(int j = 0; j < elemNode; j++){
        if(elemList[i].nodeList[j] == null){
          return;
        }
      }
    }

    // データの準備
    List<double> xyz0 = List.filled(nodeList.length, 0);
    List<List<int>> mfix = List.generate(nodeList.length, (_) => List<int>.filled(4, 0));
    List<List<double>> fnod = List.generate(nodeList.length, (_) => List<double>.filled(2, 0));
    for(int i = 0; i < nodeList.length; i++){
      xyz0[i] = nodeList[i].pos.dx;
      mfix[i][0] = nodeList[i].constXYR[0] ? 1 : 0;
      mfix[i][1] = nodeList[i].constXYR[1] ? 1 : 0;
      mfix[i][2] = nodeList[i].constXYR[2] ? 1 : 0;
      mfix[i][3] = nodeList[i].constXYR[3] ? 1 : 0;
      fnod[i][0] = nodeList[i].loadXY[1];
      fnod[i][1] = nodeList[i].loadXY[2];
    }
    List<List<int>> ijk0 = List.generate(elemList.length, (_) => List<int>.filled(2, 0));
    List<List<double>> prp0 = List.generate(elemList.length, (_) => List<double>.filled(2, 0));
    List<double> felm = List.filled(elemList.length, 0);
    for(int i = 0; i < elemList.length; i++){
      ijk0[i][0] = elemList[i].nodeList[0]!.number;
      ijk0[i][1] = elemList[i].nodeList[1]!.number;
      prp0[i][0] = elemList[i].e;
      prp0[i][1] = elemList[i].v;
      felm[i] = elemList[i].load;
    }

    // 解析
    var result = beam2dHingeRemesh(xyz0, mfix, fnod, ijk0, prp0, felm);

    List<double> xyzn = result.$1;
    List<double> dispY = result.$2;
    List<List<int>> ijke = result.$3;
    List<List<double>> resul = result.$4;

    // 細分化後の結果をデータ化
    resultNodeList = [];
    resultElemList = [];
    for(int i = 0; i < xyzn.length; i++){
      Node node = Node();
      node.pos = Offset(xyzn[i], 0);
      node.becPos = Offset(0, dispY[i]);
      node.afterPos = node.pos + node.becPos;
      resultNodeList.add(node);
    }
    for(int i = 0; i < ijke.length; i++){
      Elem elem = Elem();
      elem.nodeList[0] = resultNodeList[ijke[i][0]];
      elem.nodeList[1] = resultNodeList[ijke[i][1]];
      elem.nodeList[0]!.result[0] = resul[i][0];
      elem.nodeList[0]!.result[1] = resul[i][1];
      elem.nodeList[1]!.result[0] = resul[i][2];
      elem.nodeList[1]!.result[2] = resul[i][3];
      elem.result[4] = resul[i][4];
      elem.result[5] = resul[i][5];
      elem.result[6] = resul[i][6];
      resultElemList.add(elem);
    }

    isCalculation = true;
  }
  void resetCalculation(){
    isCalculation = false;
  }

  // キャンバスに要素があるか
  void updateCanvasPos(Rect canvasRect, double nodeRadius, double elemWidth){
    canvasData.setScale(canvasRect, rect());

    List<Node> nodes = allNodeList();
    double maxx = 0;
    for(int i = 0; i < nodes.length; i++){
      maxx = max(maxx, nodes[i].becPos.dx.abs());
      maxx = max(maxx, nodes[i].becPos.dy.abs());
    }
    for(int i = 0; i < nodes.length; i++){
      nodes[i].canvasRadius = nodeRadius*5;
      nodes[i].canvasPos = canvasData.dToC(nodes[i].pos);
      nodes[i].canvasAfterPos = nodes[i].canvasPos + Offset(nodes[i].becPos.dx, -nodes[i].becPos.dy)/maxx*canvasData.percentToCWidth(20);
    }
    List<Elem> elems = allElemList();
    for(int i = 0; i < elems.length; i++){
      if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
        var p = MyCalculator.angleRectanglePos(elems[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, elemWidth*5);
        elems[i].canvasPosList[0] = p.$1;
        elems[i].canvasPosList[1] = p.$2;
        elems[i].canvasPosList[2] = p.$3;
        elems[i].canvasPosList[3] = p.$4;
      }
    }
  }
  void initSelect(){
    selectedNumber = -1;
    for(int i = 0; i < elemList.length; i++){
      elemList[i].isSelect = false;
    }
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].isSelect = false;
    }
  }
  void selectElem(Offset pos){
    initSelect();

    for(int i = 0; i < elemList.length; i++){
      List<Offset> nodePosList = List.empty(growable: true);
      for(int j = 0; j < elemNode; j++){
        nodePosList.add(elemList[i].nodeList[j]!.pos);
      }

      // 四角形のとき
      Offset p0 = elemList[i].canvasPosList[0];
      Offset p1 = elemList[i].canvasPosList[1];
      Offset p2 = elemList[i].canvasPosList[2];
      Offset p3 = elemList[i].canvasPosList[3];

      if(MyCalculator.isPointInRectangle(pos, p0, p1, p2, p3)){
        selectedNumber = i;
        elemList[i].isSelect = true;
        return;
      }
    }
  }
  void selectNode(Offset pos){
    initSelect();

    for(int i = 0; i < nodeList.length; i++){
      double dis = (nodeList[i].canvasPos - pos).distance;
      if(dis <= nodeList[i].canvasRadius){
        selectedNumber = i;
        nodeList[i].isSelect = true;
        break;
      }
    }
  }
}

class Node{
  // 基本データ
  int number = 0;
  Offset pos = Offset.zero;
  List<bool> constXYR = [false, false, false, false]; // 拘束（0:x、1:y、2:回転、3:ヒンジ）
  List<double> loadXY = [0, 0, 0]; // 荷重（0:x、1:y、2:モーメント）

  // 計算結果
  Offset becPos = Offset.zero;
  Offset afterPos = Offset.zero;
  List<double> result = [0, 0, 0]; // 0:たわみ、1:たわみ角1、2:たわみ角2

  // キャンバス情報
  double canvasRadius = 10;
  Offset canvasPos = Offset.zero;
  Offset canvasAfterPos = Offset.zero;
  bool isSelect = false; // 選択されているか
}

class Elem{
  // 基本データ
  int number = 0;
  double e = 1.0;
  double v = 1.0;
  double load = 0.0; // 分布荷重
  List<Node?> nodeList = [null, null];

  // 計算結果
  List<double> result = [0,0,0,0,0,0,0,0,0]; // 4:せん断力、5:曲げモーメント1、6:曲げモーメント2

  // キャンバス情報
  List<Offset> canvasPosList = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];
  bool isSelect = false; // 選択されているか
}
