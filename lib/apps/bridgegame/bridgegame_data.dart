import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/apps/bridgegame/des_fem70x25.dart';
import 'package:kozo/utils/canvas_data.dart';
import 'package:kozo/utils/my_calculator.dart';

class BridgegameData{
  BridgegameData({required this.onDebug}){
    elemNode = 4;
    int countX = 70;
    int countY = 25;
    for(int i = 0; i <= countY; i++){
      for(int j = 0; j <= countX; j++){
        Node node = Node();
        node.pos = Offset(j.toDouble(), i.toDouble());
        nodeList.add(node);
      }
    }
    for(int i = 0; i < countY; i++){
      for(int j = 0; j < countX; j++){
        Elem elem = Elem();
        elem.nodeList = [nodeList[i*(countX+1)+j],nodeList[i*(countX+1)+j+1],nodeList[(i+1)*(countX+1)+j+1],nodeList[(i+1)*(countX+1)+j]];
        elemList.add(elem);
      }
    }

    // 拘束か荷重がかかる要素は確定
    for(int i = 0; i < countX; i++){
      elemList[i].isCanPaint = false;
      elemList[i].e = 1;
    }
  }

  final Function(String value) onDebug;

  // データ
  int elemNode = 4; // 要素節点数
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
  int powerType = 0; // 荷重条件（0:集中荷重、1:分布荷重、2:自重）

  // 節点の範囲座標
  Rect rect(){
    List<Node> nodes = nodeList;
    if(nodes.isEmpty) return Rect.zero; // 節点データがないとき終了

    double left = nodes[0].pos.dx;
    double right = nodes[0].pos.dx;
    double top = nodes[0].pos.dy;
    double bottom = nodes[0].pos.dy;

    if(nodes.length > 1){
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


  int elemCount(){ // 要素数
    int elemCount = 0;
    for(int i = 0; i < elemList.length; i++){
      if(elemList[i].e > 0){
        elemCount ++;
      }
    }
    return elemCount;
  }
  double vvar = 0; // 荷重中央たわみ/体積（基準モデル）
  double resultPoint = 0; // 点数

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

  // 対称化
  void symmetrical(){
    int countX = 70;
    int countY = 25;

    for(int y = 0; y < countY; y++){
      for(int x = 0; x < countX/2; x++){
        if(elemList[countX*y+countX-x-1].isCanPaint){
          elemList[countX*y+countX-x-1].e = elemList[countX*y+x].e;
        }
      }
    }
  }

  // 解析
  void calculation(){
    const int npx1 = 70;
    const int npx2 = 25;
    const int nd = 2;

    List<List<int>> zeroOneList = List.generate(npx1, (_) => List.filled(npx2, 0));
    for (int n2 = 0; n2 < npx2; n2++) {
      for (int n1 = 0; n1 < npx1; n1++) {
        zeroOneList[n1][n2] = elemList[npx1*(npx2-n2-1)+n1].e.toInt();
      }
    }

    // 解析実行
    final result = desFEM70x25(zeroOneList, powerType);

    // 変位を入手
    for (int n2 = 0; n2 < npx2+1; n2++) {
      for (int n1 = 0; n1 < npx1+1; n1++) {
        nodeList[(npx1+1)*(npx2-n2)+n1].becPos = Offset(result.$1[((npx1+1)*n2+n1)*nd], result.$1[((npx1+1)*n2+n1)*nd+1]);
      }
    }
    // 変位後の座標
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].afterPos = Offset(nodeList[i].pos.dx+nodeList[i].becPos.dx, nodeList[i].pos.dy+nodeList[i].becPos.dy);
    }

    // 結果の入手
    for (int n2 = 0; n2 < npx2; n2++) {
      for (int n1 = 0; n1 < npx1; n1++) {
        elemList[npx1*(npx2-n2-1)+n1].strainXY[0] = result.$2[n1][n2][0];
        elemList[npx1*(npx2-n2-1)+n1].strainXY[1] = result.$2[n1][n2][1];
        elemList[npx1*(npx2-n2-1)+n1].strainXY[2] = result.$2[n1][n2][2];
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[0] = result.$3[n1][n2][0];
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[1] = result.$3[n1][n2][1];
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[2] = result.$3[n1][n2][2];
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[3] = result.$3[n1][n2][3];
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[4] = result.$3[n1][n2][4];
      }
    }

    // 点数
    double maxBecPos = nodeList[35].becPos.dy.abs();
    int elemLength = elemCount();

    // シグモイド関数
    // vvar = 125446.5437*pow(elemLength,-3.4227461);

    // ニュートン補間
    double b0, b1, b2;
    if (elemLength >= 70 && elemLength < 140) {
      b0 = 3.4159242117E+00;
      b1 = -4.5191687192E-02;
      b2 = 2.1786797104E-04;
      vvar = b0 + b1 * (elemLength - 70) + b2 * (elemLength - 70) * (elemLength - 105);
    } else if (elemLength >= 140 && elemLength < 210) {
      b0 = 7.8628263731E-01;
      b1 = -8.3156504589E-03;
      b2 = 3.5738917299E-05;
      vvar = b0 + b1 * (elemLength - 140) + b2 * (elemLength - 140) * (elemLength - 175);
    } else if (elemLength >= 210 && elemLength < 350) {
      b0 = 2.9174745257E-01;
      b1 = -2.0613303788E-03;
      b2 = 8.5850173811E-06;
      vvar = b0 + b1 * (elemLength - 210) + b2 * (elemLength - 210) * (elemLength - 280);
    } else if (elemLength >= 350 && elemLength < 490) {
      b0 = 8.7294369877E-02;
      b1 = -4.4232646612E-04;
      b2 = 1.3426382928E-06;
      vvar = b0 + b1 * (elemLength - 350) + b2 * (elemLength - 350) * (elemLength - 420);
    } else if (elemLength >= 490 && elemLength < 630) {
      b0 = 3.8526519889E-02;
      b1 = -1.5628977445E-04;
      b2 = 3.9630188412E-07;
      vvar = b0 + b1 * (elemLength - 490) + b2 * (elemLength - 490) * (elemLength - 560);
    } else if (elemLength >= 630 && elemLength < 770) {
      b0 = 2.0529709931E-02;
      b1 = -6.7666021124E-05;
      b2 = 1.4764385486E-07;
      vvar = b0 + b1 * (elemLength - 630) + b2 * (elemLength - 630) * (elemLength - 700);
    } else if (elemLength >= 770 && elemLength < 910) {
      b0 = 1.2503376751E-02;
      b1 = -3.3617200755E-05;
      b2 = 6.3902626225E-08;
      vvar = b0 + b1 * (elemLength - 770) + b2 * (elemLength - 770) * (elemLength - 840);
    } else if (elemLength >= 910 && elemLength < 1050) {
      b0 = 8.4232143822E-03;
      b1 = -1.8513034220E-05;
      b2 = 3.1060716901E-08;
      vvar = b0 + b1 * (elemLength - 910) + b2 * (elemLength - 910) * (elemLength - 980);
    }
    vvar = vvar/elemLength;

    double vvvar = maxBecPos/elemLength-vvar;
    double a = 3;
    if(vvvar > 0){
      a = 0.5;
    }
    resultPoint = 100 * (1-1/(1+(pow(e, -a*(vvvar)/vvar))));

    selectResult(3);

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

    resultList = MyCalculator.normalizeArray(resultList);

    resultMax = resultList.reduce(max);
    resultMin = resultList.reduce(min);
  }

  // キャンバス
  void updateCanvasPos(Rect canvasRect, int type){
    canvasData.setScale(canvasRect, rect());

    double a = 3;
    // if(resultPoint < 50){
    //   a = a * 2*(1/(1+pow(e, -0.025*(resultPoint-50))));
    // }

    List<Node> nodes = nodeList;
    for(int i = 0; i < nodes.length; i++){
      nodes[i].canvasPos = canvasData.dToC(nodes[i].pos);
      nodes[i].canvasAfterPos = nodes[i].canvasPos + Offset(nodes[i].becPos.dx, -nodes[i].becPos.dy)*canvasData.scale*a/(vvar*elemCount()); // 変形
    }
    List<Elem> elems = elemList;
    for(int i = 0; i < elems.length; i++){
      if(type == 0){
        for(int j = 0; j < elemNode; j++){
          elems[i].canvasPosList[j] = canvasData.dToC(elems[i].nodeList[j]!.pos);
        }
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
  void selectElem(Offset pos, int type){
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
      if(isCalculation){
        p0 = elemList[i].nodeList[0]!.canvasAfterPos;
        p1 = elemList[i].nodeList[1]!.canvasAfterPos;
        p2 = elemList[i].nodeList[2]!.canvasAfterPos;
        p3 = elemList[i].nodeList[3]!.canvasAfterPos;
      }

      if(MyCalculator.isPointInRectangle(pos, p0, p1, p2, p3)){
        selectedNumber = i;
        elemList[i].isSelect = true;
        return;
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
  double load = 0.0; // 分布荷重

  // 計算結果
  List<double> strainXY = [0,0,0]; // 0:X方向ひずみ、1:Y方向ひずみ、2:せん断ひずみ
  List<double> stlessXY = [0,0,0,0,0,0,0]; // 0:X方向応力、1:Y方向応力、2:せん断応力、3:最大主応力、4:最小主応力、5:曲げモーメント左、6:曲げモーメント右
  List<double> result = [0,0,0,0,0,0,0,0,0]; // 0:たわみ1、1:たわみ角1、2:たわみ2、3:たわみ角2、4:せん断力、5:曲げモーメント1、6:曲げモーメント2

  // キャンバス情報
  List<Offset> canvasPosList = [Offset.zero, Offset.zero, Offset.zero, Offset.zero];
  bool isSelect = false; // 選択されているか
  bool isCanPaint = true; // 色がかわるか
}
