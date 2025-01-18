import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/models/calculation_data.dart';
import 'package:kozo/models/canvas_data.dart';
import 'package:kozo/utils/calculator.dart';

class Data
{
  Data({required this.onDebug});
  final Function(String value) onDebug;

  // データ
  int elemNode = 2; // 要素節点数
  List<Node> nodeList = []; // 節点データ
  List<Elem> elemList = []; // 要素データ
  List<Mat> matList = []; // 要素パラメータデータ（まだ使ったいない）
  // 追加データ
  Node? node; // 新規節点データ
  Elem? elem; // 新規要素データ

  bool isCalculation = false; // 解析したかどうか
  List<double> resultList = [];
  double resultMin = 0, resultMax = 0;
  // 選択番号
  int selectedNumber = -1;
  int powerType = 0; // 荷重条件（橋のとき、0:集中荷重、1:分布荷重、2:自重）

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
  Rect rect()
  {
    List<Node> nodes = allNodeList();
    if(nodes.isEmpty) return Rect.zero; // 節点データがないとき終了

    double left = nodes[0].pos.dx;
    double right = nodes[0].pos.dx;
    double top = nodes[0].pos.dy;
    double bottom = nodes[0].pos.dy;

    if(allNodeList().length > 1){
      for (int i = 1; i < nodes.length; i++) {
        left = math.min(left, nodes[i].pos.dx);
        right = math.max(right, nodes[i].pos.dx);
        top = math.min(top, nodes[i].pos.dy);
        bottom = math.max(bottom, nodes[i].pos.dy);
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }
  CanvasData canvasData = CanvasData();
  List<Node> resultNodeList = [];
  List<Elem> resultElemList = [];

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
  void calculation(int type)
  {
    if(type == 0){
      elemNode = 4;
      calculationDes(nodeList, elemList, elemNode, powerType);
      selectResult(0);
    }else if(type == 1){
      elemNode = 2;
      calculationTruss(nodeList, elemList, elemNode);
      selectResult(0);
    }else if(type == 2){
      elemNode = 2;
      var result = calculationBeam(nodeList, elemList, elemNode);
      resultNodeList = result.$1;
      resultElemList = result.$2;
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
  void selectResult(int num) // 結果
  {
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
        resultMax = math.max(resultMax, resultList[i]);
        resultMin = math.min(resultMin, resultList[i]);
      }
    }
  }

  // キャンバスに要素があるか
  void updateCanvasPos(Rect canvasRect, int type)
  {
    canvasData.setScale(canvasRect, rect());

    List<Node> nodes = allNodeList();
    double max = 0;
    for(int i = 0; i < nodes.length; i++){
      max = math.max(max, nodes[i].becPos.dx.abs());
      max = math.max(max, nodes[i].becPos.dy.abs());
    }
    for(int i = 0; i < nodes.length; i++){
      nodes[i].canvasPos = canvasData.dToC(nodes[i].pos);
      nodes[i].canvasAfterPos = nodes[i].canvasPos + Offset(nodes[i].becPos.dx, -nodes[i].becPos.dy)/max*canvasData.percentToCWidth(20);
    }
    List<Elem> elems = allElemList();
    for(int i = 0; i < elems.length; i++){
      if(type == 0){
        for(int j = 0; j < elemNode; j++){
          elems[i].canvasPosList[j] = canvasData.dToC(elems[i].nodeList[j]!.pos);
        }
      }else if(type == 1){ // トラス、はり
        if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
          var p = angleRectanglePos(elems[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, canvasData.percentToCWidth(5));
          elems[i].canvasPosList[0] = p.$1;
          elems[i].canvasPosList[1] = p.$2;
          elems[i].canvasPosList[2] = p.$3;
          elems[i].canvasPosList[3] = p.$4;
        }
      }
    }
  }
  void initSelect()
  {
    selectedNumber = -1;
    for(int i = 0; i < elemList.length; i++){
      elemList[i].isSelect = false;
    }
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].isSelect = false;
    }
  }
  void selectElem(Offset pos, int type)
  {
    initSelect();

    for(int i = 0; i < elemList.length; i++){
      List<Offset> nodePosList = List.empty(growable: true);
      for(int j = 0; j < elemNode; j++){
        nodePosList.add(elemList[i].nodeList[j]!.pos);
      }

      // if(elemNode == 2){
      //   double distance = distanceFromPointToSegment(nodePosList[0], nodePosList[1], pos);

      //   if(distance < 0.1){
      //     selectedNumber = i;
      //     elemList[i].isSelect = true;
      //     return;
      //   }
      // }
      // else if(elemNode == 3){
      //   double totalArea = areaOfTriangle(nodePosList[0], nodePosList[1], nodePosList[2]);
      //   double area1 = areaOfTriangle(pos, nodePosList[1], nodePosList[2]);
      //   double area2 = areaOfTriangle(nodePosList[0], pos, nodePosList[2]);
      //   double area3 = areaOfTriangle(nodePosList[0], nodePosList[1], pos);

      //   if (math.pow(totalArea, 1.0001) >= area1 + area2 + area3){
      //     selectedNumber = i;
      //     return;
      //   }
      // }
      if(type == 0){ // 四角形のとき
        Offset p0 = elemList[i].canvasPosList[0];
        Offset p1 = elemList[i].canvasPosList[1];
        Offset p2 = elemList[i].canvasPosList[2];
        Offset p3 = elemList[i].canvasPosList[3];
        if(isCalculation){
          p0 = elemList[i].nodeList[0]!.canvasAfterPos;
          p1 = elemList[i].nodeList[1]!.canvasAfterPos;
          p2 = elemList[i].nodeList[2]!.canvasAfterPos;
          p3 = elemList[i].nodeList[3]!.canvasAfterPos;
        }

        if(isPointInRectangle(pos, p0, p1, p2, p3)){
          selectedNumber = i;
          elemList[i].isSelect = true;
          return;
        }
      }
    }
  }
  void selectNode(Offset pos)
  {
    initSelect();

    for(int i = 0; i < nodeList.length; i++){
      double dis = (nodeList[i].canvasPos - pos).distance;
      if(dis <= 15){
        selectedNumber = i;
        nodeList[i].isSelect = true;
        break;
      }
    }
  }
}

class Node
{
  // 基本データ
  int number = 0;
  Offset pos = Offset.zero;
  List<bool> constXYR = [false, false, false, false]; // 拘束（0:x、1:y、2:回転、3:ヒンジ）
  List<double> loadXY = [0, 0, 0]; // 荷重（0:x、1:y、2:モーメント）

  // 計算結果
  Offset becPos = Offset.zero;
  Offset afterPos = Offset.zero;
  List<double> result = [0,0,0,0,0,0,0,0,0]; // 0:たわみ、1:たわみ角1、2:たわみ角2

  // キャンバス情報
  Offset canvasPos = Offset.zero;
  Offset canvasAfterPos = Offset.zero;
  bool isSelect = false; // 選択されているか
}

class Elem
{
  // 基本データ
  int number = 0;
  double e = 0.0;
  double v = 0.0;
  List<Node?> nodeList = [null, null, null, null];
  Mat? mat;
  double load = 0.0; // 分布荷重

  // 計算結果
  List<double> strainXY = [0,0,0]; // 0:X方向ひずみ、1:Y方向ひずみ、2:せん断ひずみ
  List<double> stlessXY = [0,0,0,0,0,0,0]; // 0:X方向応力、1:Y方向応力、2:せん断応力、3:最大主応力、4:最小主応力、5:曲げモーメント左、6:曲げモーメント右
  List<double> result = [0,0,0,0,0,0,0,0,0]; // 0:たわみ1、1:たわみ角1、2:たわみ2、3:たわみ角2、4:せん断力、5:曲げモーメント1、6:曲げモーメント2

  // キャンバス情報
  List<Offset> canvasPosList = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];
  bool isSelect = false; // 選択されているか
}

class Mat
{
  int number = 0;
  double e = 0;
  double v = 0;
}