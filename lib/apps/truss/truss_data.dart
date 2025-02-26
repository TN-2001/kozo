import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/utils/canvas_data.dart';
import 'package:kozo/utils/my_calculator.dart';

class TrussData{
  TrussData({required this.onDebug});
  final Function(String value) onDebug;

  // データ
  int elemNode = 2; // 要素節点数
  List<Node> nodeList = []; // 節点データ
  List<Elem> elemList = []; // 要素データ
  // 追加データ
  Node? node; // 新規節点データ
  Elem? elem; // 新規要素データ

  bool isCalculation = false; // 解析したかどうか
  List<double> resultList = [];
  double resultMin = 0, resultMax = 0;
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
  CanvasData canvasData = CanvasData();


  // 追加削除
  void addNode(){
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
  void removeNode(int number){
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
  void addElem(){
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
  void removeElem(int number){
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

    // 要素データ
    List<double> lengthList = List.empty(growable: true);
    List<double> cosList = List.empty(growable: true);
    List<double> sinList = List.empty(growable: true);

    for(int i = 0; i < elemList.length; i++){
      Offset pos0 = elemList[i].nodeList[0]!.pos;
      Offset pos1 = elemList[i].nodeList[1]!.pos;

      lengthList.add((pos1 - pos0).distance);

      double angle = atan2(pos1.dy - pos0.dy, pos1.dx - pos0.dx);
      cosList.add(cos(angle));
      sinList.add(sin(angle));
    }

    // 全体剛性行列
    List<List<double>> kkk = List.generate(nodeList.length * 2, (i) => List.generate(nodeList.length * 2, (j) => 0.0));
    
    for(int i = 0; i < elemList.length; i++){
      double eal = elemList[i].e * elemList[i].v / lengthList[i];
      double k11 = eal * cosList[i] * cosList[i];
      double k12 = eal * cosList[i] * sinList[i];
      double k21 = k12;
      double k22 = eal * sinList[i] * sinList[i];

      kkk[elemList[i].nodeList[0]!.number*2][elemList[i].nodeList[0]!.number*2] += k11;
      kkk[elemList[i].nodeList[0]!.number*2][elemList[i].nodeList[0]!.number*2+1] += k12;
      kkk[elemList[i].nodeList[0]!.number*2+1][elemList[i].nodeList[0]!.number*2] += k21;
      kkk[elemList[i].nodeList[0]!.number*2+1][elemList[i].nodeList[0]!.number*2+1] += k22;

      kkk[elemList[i].nodeList[0]!.number*2][elemList[i].nodeList[1]!.number*2] -= k11;
      kkk[elemList[i].nodeList[0]!.number*2][elemList[i].nodeList[1]!.number*2+1] -= k12;
      kkk[elemList[i].nodeList[0]!.number*2+1][elemList[i].nodeList[1]!.number*2] -= k21;
      kkk[elemList[i].nodeList[0]!.number*2+1][elemList[i].nodeList[1]!.number*2+1] -= k22;

      kkk[elemList[i].nodeList[1]!.number*2][elemList[i].nodeList[0]!.number*2] -= k11;
      kkk[elemList[i].nodeList[1]!.number*2][elemList[i].nodeList[0]!.number*2+1] -= k12;
      kkk[elemList[i].nodeList[1]!.number*2+1][elemList[i].nodeList[0]!.number*2] -= k21;
      kkk[elemList[i].nodeList[1]!.number*2+1][elemList[i].nodeList[0]!.number*2+1] -= k22;

      kkk[elemList[i].nodeList[1]!.number*2][elemList[i].nodeList[1]!.number*2] += k11;
      kkk[elemList[i].nodeList[1]!.number*2][elemList[i].nodeList[1]!.number*2+1] += k12;
      kkk[elemList[i].nodeList[1]!.number*2+1][elemList[i].nodeList[1]!.number*2] += k21;
      kkk[elemList[i].nodeList[1]!.number*2+1][elemList[i].nodeList[1]!.number*2+1] += k22;
    }

    // 縮約行列
    List<List<double>> kk = List.generate(kkk.length, (i) => List.generate(kkk[i].length, (j) => kkk[i][j]));

    for(int i = nodeList.length - 1; i > - 1; i--){
      if(nodeList[i].constXY[1]){
        for (var row in kk) {
          row.removeAt(i*2+1);
        }
        kk.removeAt(i*2+1);
      }
      if(nodeList[i].constXY[0]){
        for (var row in kk) {
          row.removeAt(i*2);
        }
        kk.removeAt(i*2);
      }
    }

    // 荷重
    List<double> powList = List.empty(growable: true);
    for(int i = 0; i < nodeList.length; i++){
      if(nodeList[i].constXY[0] == false){
        powList.add(nodeList[i].loadXY[0]);
      }
      if(nodeList[i].constXY[1] == false) powList.add(nodeList[i].loadXY[1]);
    }

    // 変位計算
    List<double> becList = MyCalculator.conjugateGradient(kk, powList, 100, 1e-10);
    int count = 0;
    for(int i = 0; i < nodeList.length; i++){
      if(nodeList[i].constXY[0] == false){
        nodeList[i].becPos = Offset(becList[count], nodeList[i].becPos.dy);
        count ++;
      }
      if(nodeList[i].constXY[1] == false){
        nodeList[i].becPos = Offset(nodeList[i].becPos.dx, becList[count]);
        count ++;
      }
      nodeList[i].afterPos = Offset(nodeList[i].pos.dx+nodeList[i].becPos.dx, nodeList[i].pos.dy+nodeList[i].becPos.dy); // 変位後の座標
    }

    // ひずみ
    for(int i = 0; i < elemList.length; i++){
      elemList[i].strainXY[0] = ((cosList[i]*elemList[i].nodeList[1]!.becPos.dx + sinList[i]*elemList[i].nodeList[1]!.becPos.dy) 
        - (cosList[i]*elemList[i].nodeList[0]!.becPos.dx + sinList[i]*elemList[i].nodeList[0]!.becPos.dy)) / lengthList[i];
    }

    // 応力
    for(int i = 0; i < elemList.length; i++){
      elemList[i].stlessXY[0] = elemList[i].e * elemList[i].strainXY[0];
    }

    isCalculation = true;
  }
  void resetCalculation(){
    for(int i = 0; i < elemList.length; i++){
      for(int j = 0; j < elemList[i].stlessXY.length; j++){
        elemList[i].stlessXY[j] = 0;
      }
      for(int j = 0; j < elemList[i].strainXY.length; j++){
        elemList[i].strainXY[j] = 0;
      }
    }

    isCalculation = false;
  }
  void selectResult(int num){ // 結果
    resultList = List.filled(elemList.length, 0);
    for (int i = 0; i < elemList.length; i++) {
      if(num == 0) {
        resultList[i] = elemList[i].stlessXY[0];
      } else if(num == 1) {
        resultList[i] = elemList[i].stlessXY[1];
      } else if(num == 2) {
        resultList[i] = elemList[i].stlessXY[2];
      } else if(num == 3) {
        resultList[i] = elemList[i].stlessXY[3];
      } else if(num == 4) {
        resultList[i] = elemList[i].stlessXY[4];
      } else if(num == 5) {
        resultList[i] = elemList[i].strainXY[0];
      } else if(num == 6) {
        resultList[i] = elemList[i].strainXY[1];
      } else if(num == 7) {
        resultList[i] = elemList[i].strainXY[2];
      } else {
        resultList = List.empty();
      }
    }

    for (int i = 0; i < resultList.length; i++) {
      if(i == 0){
        resultMax = resultList[i];
        resultMin = resultList[i];
      }else{
        resultMax = max(resultMax, resultList[i]);
        resultMin = min(resultMin, resultList[i]);
      }
    }
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
  List<bool> constXY = [false, false]; // 拘束（0:x、1:y）
  List<double> loadXY = [0, 0]; // 荷重（0:x、1:y）

  // 計算結果
  Offset becPos = Offset.zero;
  Offset afterPos = Offset.zero;
  List<double> result = [0,0,0,0,0,0,0,0,0]; // 0:たわみ、1:たわみ角1、2:たわみ角2

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
  List<Node?> nodeList = [null, null];

  // 計算結果
  List<double> strainXY = [0,0,0]; // 0:X方向ひずみ、1:Y方向ひずみ、2:せん断ひずみ
  List<double> stlessXY = [0,0,0,0,0,0,0]; // 0:X方向応力、1:Y方向応力、2:せん断応力、3:最大主応力、4:最小主応力、5:曲げモーメント左、6:曲げモーメント右

  // キャンバス情報
  List<Offset> canvasPosList = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];
  bool isSelect = false; // 選択されているか
}
