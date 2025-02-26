import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/apps/fem/lcst2ebe.dart';
import 'package:kozo/utils/canvas_data.dart';
import 'package:kozo/utils/my_calculator.dart';

class FemData
{
  FemData({required this.onDebug});
  final Function(String value) onDebug;

  // データ
  int elemNode = 3; // 要素節点数
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
        left = min(left, nodes[i].pos.dx);
        right = max(right, nodes[i].pos.dx);
        top = min(top, nodes[i].pos.dy);
        bottom = max(bottom, nodes[i].pos.dy);
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
  void calculation(){
    // 要素の節点を反時計回りに
    for(int i = 0; i < elemList.length; i++){
      Offset pos1 = elemList[i].nodeList[0]!.pos;
      Offset pos2 = elemList[i].nodeList[1]!.pos;
      Offset pos3 = elemList[i].nodeList[2]!.pos;
      if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) == 0){
        onDebug("要素の大きさが0");
        return;
      }
      if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) < 0){
        Node n = elemList[i].nodeList[0]!;
        elemList[i].nodeList[0] = elemList[i].nodeList[2];
        elemList[i].nodeList[2] = n;
      }
    }

    Lcst2ebe lcst2ebe = Lcst2ebe(
      onDebug:(value) {
        onDebug(value);
      },
    );

    // 初期化
    lcst2ebe.nd = 2;
    lcst2ebe.node = 3;
    lcst2ebe.nbcm = 3;
    lcst2ebe.nsk = 6;

    // 節点
    lcst2ebe.nx = nodeList.length;
    lcst2ebe.xyzn = List.generate(lcst2ebe.nx, (i) => List.filled(3, 0.0));
    for (int i = 0; i < lcst2ebe.nx; i++) {
      lcst2ebe.xyzn[i][0] = nodeList[i].pos.dx;
      lcst2ebe.xyzn[i][1] = nodeList[i].pos.dy;
    }

    // 要素
    lcst2ebe.nelx = elemList.length;
    lcst2ebe.node = 3;
    lcst2ebe.ijke = List.generate(lcst2ebe.nelx, (i) => List.filled(lcst2ebe.node + 2, 0));
    for (int i = 0; i < lcst2ebe.nelx; i++) {
      for (int j = 0; j < lcst2ebe.node; j++) {
        lcst2ebe.ijke[i][j] = elemList[i].nodeList[j]!.number;
      }
    }

    // マテリアル
    lcst2ebe.nmat = 1;
    lcst2ebe.pmat = List.generate(lcst2ebe.nmat, (i) => List.filled(20, 0.0));
    for (int i = 0; i < lcst2ebe.nmat; i++) {
      lcst2ebe.pmat[i][0] = elemList[0].e;
      lcst2ebe.pmat[i][1] = elemList[0].v;
    }

    // 拘束
    lcst2ebe.mspc = List.empty(growable: true);
    lcst2ebe.vspc = List.empty(growable: true);
    lcst2ebe.nspc = 0;
    for(int i = 0; i < nodeList.length; i++){
      if(nodeList[i].constXY[0] || nodeList[i].constXY[1] || nodeList[i].loadXY[0] != 0 || nodeList[i].loadXY[1] != 0){
        lcst2ebe.mspc.add(List.filled(7, 0));
        lcst2ebe.vspc.add(List.filled(6, 0.0));
        lcst2ebe.mspc[lcst2ebe.nspc][0] = i;
        if(nodeList[i].constXY[0] || nodeList[i].loadXY[0] != 0){
          lcst2ebe.mspc[lcst2ebe.nspc][1] = 1;
          lcst2ebe.vspc[lcst2ebe.nspc][0] = nodeList[i].loadXY[0];
        }
        if(nodeList[i].constXY[1] || nodeList[i].loadXY[1] != 0){
          lcst2ebe.mspc[lcst2ebe.nspc][2] = 1;
          lcst2ebe.vspc[lcst2ebe.nspc][1] = nodeList[i].loadXY[1];
        }
        lcst2ebe.nspc += 1;
      }
    }

    lcst2ebe.neq = lcst2ebe.nd * lcst2ebe.nx;

    // 解析実行
    final result = lcst2ebe.run();

    // 結果入手
    for (int i = 0; i < lcst2ebe.nx; i++) {
      nodeList[i].becPos = Offset(result.$1[lcst2ebe.nd*i], result.$1[lcst2ebe.nd*i+1]);
      nodeList[i].afterPos = nodeList[i].pos + nodeList[i].becPos;
    }

    for (int i = 0; i < lcst2ebe.nelx; i++) {
      elemList[i].strainXY[0] = result.$2[0][i];
      elemList[i].strainXY[1] = result.$2[1][i];
      elemList[i].strainXY[2] = result.$2[2][i];
      elemList[i].stlessXY[0] = result.$3[0][i];
      elemList[i].stlessXY[1] = result.$3[1][i];
      elemList[i].stlessXY[2] = result.$3[2][i];
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
        resultList[i] = elemList[i].strainXY[0];
      } else if(num == 4) {
        resultList[i] = elemList[i].strainXY[1];
      } else if(num == 5) {
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
  void updateCanvasPos(Rect canvasRect, int type)
  {
    canvasData.setScale(canvasRect, rect());

    List<Node> nodes = allNodeList();
    double maxx = 0;
    for(int i = 0; i < nodes.length; i++){
      maxx = max(maxx, nodes[i].becPos.dx.abs());
      maxx = max(maxx, nodes[i].becPos.dy.abs());
    }
    for(int i = 0; i < nodes.length; i++){
      nodes[i].canvasPos = canvasData.dToC(nodes[i].pos);
      nodes[i].canvasAfterPos = nodes[i].canvasPos + Offset(nodes[i].becPos.dx, -nodes[i].becPos.dy)/maxx*canvasData.percentToCWidth(20);
    }
    List<Elem> elems = allElemList();
    for(int i = 0; i < elems.length; i++){
      if(type == 0){
        for(int j = 0; j < elemNode; j++){
          elems[i].canvasPosList[j] = canvasData.dToC(elems[i].nodeList[j]!.pos);
        }
      }else if(type == 1){ // トラス、はり
        if(elems[i].nodeList[0] != null && elems[i].nodeList[1] != null){
          var p = MyCalculator.angleRectanglePos(elems[i].nodeList[0]!.canvasPos, elems[i].nodeList[1]!.canvasPos, canvasData.percentToCWidth(5));
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
        nodePosList.add(elemList[i].nodeList[j]!.canvasPos);
      }

      if(elemNode == 3){
        double totalArea = MyCalculator.areaOfTriangle(nodePosList[0], nodePosList[1], nodePosList[2]);
        double area1 = MyCalculator.areaOfTriangle(pos, nodePosList[1], nodePosList[2]);
        double area2 = MyCalculator.areaOfTriangle(nodePosList[0], pos, nodePosList[2]);
        double area3 = MyCalculator.areaOfTriangle(nodePosList[0], nodePosList[1], pos);

        if (pow(totalArea, 1.0001) >= area1 + area2 + area3){
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
  List<bool> constXY = [false, false]; // 拘束（0:x、1:y）
  List<double> loadXY = [0, 0]; // 荷重（0:x、1:y）

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
  double e = 1.0;
  double v = 1.0;
  List<Node?> nodeList = [null, null, null, null];
  Mat? mat;
  double load = 0.0; // 分布荷重

  // 計算結果
  List<double> strainXY = [0,0,0]; // 0:X方向ひずみ、1:Y方向ひずみ、2:せん断ひずみ
  List<double> stlessXY = [0,0,0]; // 0:X方向応力、1:Y方向応力、2:せん断応力
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