import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:kozo/utils/calculator.dart';
import 'package:kozo/utils/des_fem70x25.dart';
import 'package:kozo/utils/lcst2ebe.dart';
import 'package:kozo/utils/lcst2ebe4.dart';

class Data{
  Data({required this.onDebug});
  final Function(String value) onDebug;

  int elemNode = 2;
  List<Node> nodeList = List.empty(growable: true);
  List<Elem> elemList = List.empty(growable: true);
  List<Mat> matList = List.empty(growable: true);

  bool isCalculation = false;
  List<double> resultList = List.empty(growable: true);
  double resultMin = 0, resultMax = 0;
  int type = 0;
  // 選択タイプ（0:節点）
  int selectType = 0;
  // 選択番号
  int selectedNumber = -1;
  // キャンバスのサイズ
  late double width, height = 0;
  // データの座標のキャンバス上での倍率
  double canvasPerData = 1;
  // キャンバス上での原点座標
  Offset canvasOrigin = Offset.zero;

  void removeNode(int number){
    nodeList.removeAt(number);

    if(nodeList.isNotEmpty){
      for(int i = 0; i < elemList.length; i++){
        for(int j = 0; j < elemList[i].nodeList.length; j++){
          // 要素で消された節点を選択していたら0番節点にする
          if(elemList[i].nodeList[j] == number - 1){
            elemList[i].nodeList[j] = 0;
          }
          // 要素で消された節点より後の節点を選択していたら一つ前にする
          else if(elemList[i].nodeList[j] > number - 1){
            elemList[i].nodeList[j] -= 1;
          }
        }
      }
    }
    else{
      elemList.clear();
    }
  }

  // 解析
  void calculation(){
    if(nodeList.isEmpty) return;

    if(elemNode == 2){
      truss();
      isCalculation = true;
    }else if(elemNode == 3){
      lcst2ebe();
      isCalculation = true;
    }else if(elemNode == 4){
      lcst2ebe4();
      isCalculation = true;
    }
  }
  void truss(){ // トラス
    // 要素データ
    List<double> lengthList = List.empty(growable: true);
    List<double> cosList = List.empty(growable: true);
    List<double> sinList = List.empty(growable: true);

    for(int i = 0; i < elemList.length; i++){
      Offset pos0 = nodeList[elemList[i].nodeList[0]].pos;
      Offset pos1 = nodeList[elemList[i].nodeList[1]].pos;

      lengthList.add((pos1 - pos0).distance);

      double angle = math.atan2(pos1.dy - pos0.dy, pos1.dx - pos0.dx);
      cosList.add(math.cos(angle));
      sinList.add(math.sin(angle));
    }

    // 全体剛性行列
    List<List<double>> kkk = List.generate(nodeList.length * 2, (i) => List.generate(nodeList.length * 2, (j) => 0.0));
    
    for(int i = 0; i < elemList.length; i++){
      double eal = elemList[i].e * elemList[i].v / lengthList[i];
      double k11 = eal * cosList[i] * cosList[i];
      double k12 = eal * cosList[i] * sinList[i];
      double k21 = k12;
      double k22 = eal * sinList[i] * sinList[i];

      kkk[elemList[i].nodeList[0]*2][elemList[i].nodeList[0]*2] += k11;
      kkk[elemList[i].nodeList[0]*2][elemList[i].nodeList[0]*2+1] += k12;
      kkk[elemList[i].nodeList[0]*2+1][elemList[i].nodeList[0]*2] += k21;
      kkk[elemList[i].nodeList[0]*2+1][elemList[i].nodeList[0]*2+1] += k22;

      kkk[elemList[i].nodeList[0]*2][elemList[i].nodeList[1]*2] -= k11;
      kkk[elemList[i].nodeList[0]*2][elemList[i].nodeList[1]*2+1] -= k12;
      kkk[elemList[i].nodeList[0]*2+1][elemList[i].nodeList[1]*2] -= k21;
      kkk[elemList[i].nodeList[0]*2+1][elemList[i].nodeList[1]*2+1] -= k22;

      kkk[elemList[i].nodeList[1]*2][elemList[i].nodeList[0]*2] -= k11;
      kkk[elemList[i].nodeList[1]*2][elemList[i].nodeList[0]*2+1] -= k12;
      kkk[elemList[i].nodeList[1]*2+1][elemList[i].nodeList[0]*2] -= k21;
      kkk[elemList[i].nodeList[1]*2+1][elemList[i].nodeList[0]*2+1] -= k22;

      kkk[elemList[i].nodeList[1]*2][elemList[i].nodeList[1]*2] += k11;
      kkk[elemList[i].nodeList[1]*2][elemList[i].nodeList[1]*2+1] += k12;
      kkk[elemList[i].nodeList[1]*2+1][elemList[i].nodeList[1]*2] += k21;
      kkk[elemList[i].nodeList[1]*2+1][elemList[i].nodeList[1]*2+1] += k22;
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

    List<double> becList = Calculator().conjugateGradient(kk, powList, 100, 1e-10);
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
    }

    // 変位計算
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].afterPos = Offset(nodeList[i].pos.dx + nodeList[i].becPos.dx, nodeList[i].pos.dy + nodeList[i].becPos.dy);
    }

    // ひずみ
    for(int i = 0; i < elemList.length; i++){
      elemList[i].strainXY[0] = ((cosList[i]*nodeList[elemList[i].nodeList[1]].becPos.dx + sinList[i]*nodeList[elemList[i].nodeList[1]].becPos.dy) 
        - (cosList[i]*nodeList[elemList[i].nodeList[0]].becPos.dx + sinList[i]*nodeList[elemList[i].nodeList[0]].becPos.dy)) / lengthList[i];
    }

    // 応力
    for(int i = 0; i < elemList.length; i++){
      elemList[i].stlessXY[0] = elemList[i].e * elemList[i].strainXY[0];
    }
  }
  void lcst2ebe(){ // 三角形
    // 要素の節点を反時計回りに
    for(int i = 0; i < elemList.length; i++){
      Offset pos1 = nodeList[elemList[i].nodeList[0]].pos;
      Offset pos2 = nodeList[elemList[i].nodeList[1]].pos;
      Offset pos3 = nodeList[elemList[i].nodeList[2]].pos;
      if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) == 0){
        onDebug("要素の大きさが0");
        return;
      }
      if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) < 0){
        int num = elemList[i].nodeList[0];
        elemList[i].nodeList[0] = elemList[i].nodeList[2];
        elemList[i].nodeList[2] = num;
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
        lcst2ebe.ijke[i][j] = elemList[i].nodeList[j];
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
      nodeList[i].afterPos = nodeList[i].becPos + nodeList[i].pos;
    }

    for (int i = 0; i < lcst2ebe.nelx; i++) {
      elemList[i].strainXY[0] = result.$2[0][i];
      elemList[i].strainXY[1] = result.$2[1][i];
      elemList[i].stlessXY[0] = result.$3[0][i];
      elemList[i].stlessXY[1] = result.$3[1][i];
    }
  }
  void lcst2ebe4(){ // 四角形
    // 要素の節点を反時計回りに
    // for(int i = 0; i < elemList.length; i++){
    //   Offset pos1 = nodeList[elemList[i].nodeList[0]].pos;
    //   Offset pos2 = nodeList[elemList[i].nodeList[1]].pos;
    //   Offset pos3 = nodeList[elemList[i].nodeList[2]].pos;
    //   if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) == 0){
    //     onDebug("要素の大きさが0");
    //     return;
    //   }
    //   if(pos1.dx * (pos2.dy - pos3.dy) + pos2.dx * (pos3.dy - pos1.dy) + pos3.dx * (pos1.dy - pos2.dy) < 0){
    //     int num = elemList[i].nodeList[0];
    //     elemList[i].nodeList[0] = elemList[i].nodeList[2];
    //     elemList[i].nodeList[2] = num;
    //   }
    // }

    Lcst2ebe4 lcst2ebe4 = Lcst2ebe4(
      onDebug:(value) {
        onDebug(value);
      },
    );

    // 初期化
    lcst2ebe4.nd = 2;// ２次元
    lcst2ebe4.node = 4;// 四角形
    lcst2ebe4.nbcm = 3;
    lcst2ebe4.nsk = 8;

    // 節点
    lcst2ebe4.nx = nodeList.length;
    lcst2ebe4.xyzn = List.generate(lcst2ebe4.nx, (i) => List.filled(3, 0.0));
    for (int i = 0; i < lcst2ebe4.nx; i++) {
      lcst2ebe4.xyzn[i][0] = nodeList[i].pos.dx;
      lcst2ebe4.xyzn[i][1] = nodeList[i].pos.dy;
    }

    // 要素
    lcst2ebe4.nelx = elemList.length;
    lcst2ebe4.ijke = List.generate(lcst2ebe4.nelx, (i) => List.filled(lcst2ebe4.node + 2, 0));
    for (int i = 0; i < lcst2ebe4.nelx; i++) {
      for (int j = 0; j < lcst2ebe4.node; j++) {
        lcst2ebe4.ijke[i][j] = elemList[i].nodeList[j];
      }
    }

    // マテリアル
    lcst2ebe4.nmat = 1;
    lcst2ebe4.pmat = List.generate(lcst2ebe4.nmat, (i) => List.filled(20, 0.0));
    for (int i = 0; i < lcst2ebe4.nmat; i++) {
      lcst2ebe4.pmat[i][0] = elemList[0].e;
      lcst2ebe4.pmat[i][1] = elemList[0].v;
    }

    // 拘束
    lcst2ebe4.mspc = List.empty(growable: true);
    lcst2ebe4.vspc = List.empty(growable: true);
    lcst2ebe4.nspc = 0;
    for(int i = 0; i < nodeList.length; i++){
      if(nodeList[i].constXY[0] || nodeList[i].constXY[1] || nodeList[i].loadXY[0] != 0 || nodeList[i].loadXY[1] != 0){
        lcst2ebe4.mspc.add(List.filled(7, 0));
        lcst2ebe4.vspc.add(List.filled(6, 0.0));
        lcst2ebe4.mspc[lcst2ebe4.nspc][0] = i;
        if(nodeList[i].constXY[0] || nodeList[i].loadXY[0] != 0){
          lcst2ebe4.mspc[lcst2ebe4.nspc][1] = 1;
          lcst2ebe4.vspc[lcst2ebe4.nspc][0] = nodeList[i].loadXY[0];
        }
        if(nodeList[i].constXY[1] || nodeList[i].loadXY[1] != 0){
          lcst2ebe4.mspc[lcst2ebe4.nspc][2] = 1;
          lcst2ebe4.vspc[lcst2ebe4.nspc][1] = nodeList[i].loadXY[1];
        }
        lcst2ebe4.nspc += 1;
      }
    }

    lcst2ebe4.neq = lcst2ebe4.nd * lcst2ebe4.nx;

    // 解析実行
    final result = lcst2ebe4.run();

    // 結果入手
    for (int i = 0; i < lcst2ebe4.nx; i++) {
      nodeList[i].becPos = Offset(result.$1[lcst2ebe4.nd*i], result.$1[lcst2ebe4.nd*i+1]);
      nodeList[i].afterPos = nodeList[i].becPos + nodeList[i].pos;
    }

    for (int i = 0; i < lcst2ebe4.nelx; i++) {
      elemList[i].strainXY[0] = result.$2[0][i];
      elemList[i].strainXY[1] = result.$2[1][i];
      elemList[i].stlessXY[0] = result.$3[0][i];
      elemList[i].stlessXY[1] = result.$3[1][i];
    }
  }
  void calculationDes(){ // 橋の解析
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
    final result = desFEM70x25(zeroOneList);

    // 変位を入手
    for (int n2 = 0; n2 < npx2+1; n2++) {
      for (int n1 = 0; n1 < npx1+1; n1++) {
        nodeList[(npx1+1)*(npx2-n2)+n1].becPos = Offset(result.$1[((npx1+1)*n2+n1)*nd], result.$1[((npx1+1)*n2+n1)*nd+1]);
        nodeList[(npx1+1)*(npx2-n2)+n1].afterPos = nodeList[(npx1+1)*(npx2-n2)+n1].becPos + nodeList[(npx1+1)*(npx2-n2)+n1].pos;
      }
    }
    // 変位を最大3に変更
    double maxDirY = 0;
    for(int i = 0; i < nodeList.length; i++){
      maxDirY = math.max(maxDirY, nodeList[i].becPos.dy.abs());
    }
    double size = 3 / maxDirY;
    for (int n2 = 0; n2 < npx2+1; n2++) {
      for (int n1 = 0; n1 < npx1+1; n1++) {
        nodeList[(npx1+1)*(npx2-n2)+n1].becPos *= size;
        nodeList[(npx1+1)*(npx2-n2)+n1].afterPos = nodeList[(npx1+1)*(npx2-n2)+n1].becPos + nodeList[(npx1+1)*(npx2-n2)+n1].pos;
      }
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
        elemList[npx1*(npx2-n2-1)+n1].stlessXY[3] = result.$3[n1][n2][3];
      }
    }

    isCalculation = true;
    selectResult(0);
    selectedNumber = -1;
  }
  void calculationTruss(){
    if(elemList.isEmpty){
      return;
    }

    // 要素データ
    List<double> lengthList = List.empty(growable: true);
    List<double> cosList = List.empty(growable: true);
    List<double> sinList = List.empty(growable: true);

    for(int i = 0; i < elemList.length; i++){
      Offset pos0 = elemList[i].nodes[0].pos;
      Offset pos1 = elemList[i].nodes[1].pos;

      lengthList.add((pos1 - pos0).distance);

      double angle = math.atan2(pos1.dy - pos0.dy, pos1.dx - pos0.dx);
      cosList.add(math.cos(angle));
      sinList.add(math.sin(angle));
    }

    // 全体剛性行列
    List<List<double>> kkk = List.generate(nodeList.length * 2, (i) => List.generate(nodeList.length * 2, (j) => 0.0));
    
    for(int i = 0; i < elemList.length; i++){
      double eal = elemList[i].e * elemList[i].v / lengthList[i];
      double k11 = eal * cosList[i] * cosList[i];
      double k12 = eal * cosList[i] * sinList[i];
      double k21 = k12;
      double k22 = eal * sinList[i] * sinList[i];

      kkk[elemList[i].nodes[0].number*2][elemList[i].nodes[0].number*2] += k11;
      kkk[elemList[i].nodes[0].number*2][elemList[i].nodes[0].number*2+1] += k12;
      kkk[elemList[i].nodes[0].number*2+1][elemList[i].nodes[0].number*2] += k21;
      kkk[elemList[i].nodes[0].number*2+1][elemList[i].nodes[0].number*2+1] += k22;

      kkk[elemList[i].nodes[0].number*2][elemList[i].nodes[1].number*2] -= k11;
      kkk[elemList[i].nodes[0].number*2][elemList[i].nodes[1].number*2+1] -= k12;
      kkk[elemList[i].nodes[0].number*2+1][elemList[i].nodes[1].number*2] -= k21;
      kkk[elemList[i].nodes[0].number*2+1][elemList[i].nodes[1].number*2+1] -= k22;

      kkk[elemList[i].nodes[1].number*2][elemList[i].nodes[0].number*2] -= k11;
      kkk[elemList[i].nodes[1].number*2][elemList[i].nodes[0].number*2+1] -= k12;
      kkk[elemList[i].nodes[1].number*2+1][elemList[i].nodes[0].number*2] -= k21;
      kkk[elemList[i].nodes[1].number*2+1][elemList[i].nodes[0].number*2+1] -= k22;

      kkk[elemList[i].nodes[1].number*2][elemList[i].nodes[1].number*2] += k11;
      kkk[elemList[i].nodes[1].number*2][elemList[i].nodes[1].number*2+1] += k12;
      kkk[elemList[i].nodes[1].number*2+1][elemList[i].nodes[1].number*2] += k21;
      kkk[elemList[i].nodes[1].number*2+1][elemList[i].nodes[1].number*2+1] += k22;
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
      if(nodeList[i].constXY[1] == false){
        powList.add(nodeList[i].loadXY[1]);
      }
    }

    List<double> becList = Calculator().conjugateGradient(kk, powList, 100, 1e-10);
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
    }

    // 変位計算
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].afterPos = Offset(nodeList[i].pos.dx + nodeList[i].becPos.dx, nodeList[i].pos.dy + nodeList[i].becPos.dy);
    }

    // ひずみ
    for(int i = 0; i < elemList.length; i++){
      elemList[i].strainXY[0] = ((cosList[i]*elemList[i].nodes[1].becPos.dx + sinList[i]*elemList[i].nodes[1].becPos.dy) 
        - (cosList[i]*elemList[i].nodes[0].becPos.dx + sinList[i]*elemList[i].nodes[0].becPos.dy)) / lengthList[i];
    }

    // 応力
    for(int i = 0; i < elemList.length; i++){
      elemList[i].stlessXY[0] = elemList[i].e * elemList[i].strainXY[0];
    }

    isCalculation = true;
  }

  void resetCalculation(){
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].afterPos = const Offset(0, 0);
    }
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

  List<Node> getCanvasNodeList(double width, double height){
    if(nodeList.isEmpty) return List.empty();

    this.width = width;
    this.height = height;

    List<Node> canvasNodeList = List.empty(growable: true);

    for(int i = 0; i < nodeList.length; i++){
      canvasNodeList.add(Node());
      canvasNodeList[i].constXY = nodeList[i].constXY;
      canvasNodeList[i].loadXY = nodeList[i].loadXY;
    }

    // 節点座標の最大最小
    double minX = nodeList[0].pos.dx;
    double maxX = nodeList[0].pos.dx;
    double minY = nodeList[0].pos.dy;
    double maxY = nodeList[0].pos.dy;

    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        minX = math.min(minX, nodeList[i].pos.dx);
        maxX = math.max(maxX, nodeList[i].pos.dx);
        minY = math.min(minY, nodeList[i].pos.dy);
        maxY = math.max(maxY, nodeList[i].pos.dy);
      }
    }

    // 拡大率
    canvasPerData = 1;
    double xpar = (maxX-minX)/(width == 0 ? 1 : width); 
    double ypar = (maxY-minY)/(height == 0 ? 1 : height);
    if (xpar > 0 || ypar > 0) { 
      if (xpar > ypar) {
        canvasPerData = 0.6 / xpar;
      } else {
        canvasPerData = 0.6 / ypar;
      }
    }

    // 原点
    Offset midPos = Offset((minX+maxX)/2, (minY+maxY)/2);
    canvasOrigin = Offset(width/2 - midPos.dx*canvasPerData, height/2 - midPos.dy*canvasPerData);

    // 節点座標
    List<Offset> pos = List.empty(growable: true);
    for(int i = 0; i < nodeList.length; i++){
      pos.add(Offset(nodeList[i].pos.dx*canvasPerData + canvasOrigin.dx, nodeList[i].pos.dy*canvasPerData + canvasOrigin.dy));
      // y座標を逆に
      pos[i] = Offset(pos[i].dx, height - pos[i].dy);
    }

    // 変位絶対値の最大最小
    double bminX = nodeList[0].becPos.dx.abs();
    double bmaxX = nodeList[0].becPos.dx.abs();
    double bminY = nodeList[0].becPos.dy.abs();
    double bmaxY = nodeList[0].becPos.dy.abs();

    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        bminX = math.min(bminX, nodeList[i].becPos.dx.abs());
        bmaxX = math.max(bmaxX, nodeList[i].becPos.dx.abs());
        bminY = math.min(bminY, nodeList[i].becPos.dy.abs());
        bmaxY = math.max(bmaxY, nodeList[i].becPos.dy.abs());
      }
    }

    // 拡大率
    double bscale = 1;
    double bxpar = (bmaxX-bminX)/(width == 0 ? 1 : width); 
    double bypar = (bmaxY-bminY)/(height == 0 ? 1 : height);
    if (bxpar > 0 || bypar > 0) { 
      if (bxpar > bypar) {
        bscale = 0.1 / bxpar;
      } else {
        bscale = 0.1 / bypar;
      }
    }

    // 計算後の節点座標
    List<Offset> afterPos = List.empty(growable: true);
    for(int i = 0; i < nodeList.length; i++){
      afterPos.add(Offset(pos[i].dx + nodeList[i].becPos.dx * bscale, pos[i].dy - nodeList[i].becPos.dy * bscale));
    }

    for(int i = 0; i < pos.length; i++){
      canvasNodeList[i].pos = pos[i];
      canvasNodeList[i].afterPos = afterPos[i];
    }

    return canvasNodeList;
  }

  // 端の座標取得
  double getNodeMinX(){
    if(nodeList.isEmpty) return 0;

    double minX = nodeList[0].pos.dx;
    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        minX = math.min(minX, nodeList[i].pos.dx);
      }
    }

    return minX;
  }
  double getNodeMinY(){
    if(nodeList.isEmpty) return 0;

    double minY = nodeList[0].pos.dy;
    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        minY = math.min(minY, nodeList[i].pos.dy);
      }
    }

    return minY;
  }
  double getNodeMaxX(){
    if(nodeList.isEmpty) return 0;

    double maxX = nodeList[0].pos.dx;
    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        maxX = math.max(maxX, nodeList[i].pos.dx);
      }
    }

    return maxX;
  }
  double getNodeMaxY(){
    if(nodeList.isEmpty) return 0;

    double maxY = nodeList[0].pos.dy;
    if(nodeList.length > 1){
      for (int i = 1; i < nodeList.length; i++) {
        maxY = math.max(maxY, nodeList[i].pos.dy);
      }
    }

    return maxY;
  }

  // ある座標に要素があるか
  void selectElem(Offset pos){
    selectedNumber = -1;    

    for(int i = 0; i < elemList.length; i++){
      List<Offset> nodePosList = List.empty(growable: true);
      for(int j = 0; j < elemNode; j++){
        Node node = nodeList[elemList[i].nodeList[j]];
        nodePosList.add(Offset(node.pos.dx*canvasPerData + canvasOrigin.dx, height - (node.pos.dy*canvasPerData + canvasOrigin.dy)));
      }

      if(elemNode == 2){
        double distance = distanceFromPointToSegment(nodePosList[0], nodePosList[1], pos);

        if(distance < 10){
          selectedNumber = i;
          return;
        }
      }
      else if(elemNode == 3){
        double totalArea = areaOfTriangle(nodePosList[0], nodePosList[1], nodePosList[2]);
        double area1 = areaOfTriangle(pos, nodePosList[1], nodePosList[2]);
        double area2 = areaOfTriangle(nodePosList[0], pos, nodePosList[2]);
        double area3 = areaOfTriangle(nodePosList[0], nodePosList[1], pos);

        if (math.pow(totalArea, 1.0001) >= area1 + area2 + area3){
          selectedNumber = i;
          return;
        }
      }
      else if(elemNode == 4){
        int crossings = 0;

        for (int j = 0; j < elemNode; j++) {
          Offset p1 = elemList[i].nodes[j].pos;
          Offset p2 = elemList[i].nodes[(j + 1) % elemNode].pos;
          if(isCalculation){
            p1 = elemList[i].nodes[j].afterPos;
            p2 = elemList[i].nodes[(j + 1) % elemNode].afterPos;
          }

          if ((p1.dy > pos.dy) != (p2.dy > pos.dy)) {
            final double intersectX = (p2.dx - p1.dx) * (pos.dy - p1.dy) / (p2.dy - p1.dy) + p1.dx;
            if (pos.dx < intersectX) {
              crossings++;
            }
          }
        }

        // 2で割った余りが1か
        if (crossings % 2 == 1){
          selectedNumber = i;
          return;
        }
      }
    }
  }
  void selectNode(Offset pos){
    selectedNumber = -1;

    for(int i = 0; i < nodeList.length; i++){
      Offset nodePos = Offset(nodeList[i].pos.dx*canvasPerData + canvasOrigin.dx, height - (nodeList[i].pos.dy*canvasPerData + canvasOrigin.dy));
      double dis = (nodePos - pos).distance;
      if(dis <= 10.0){
        selectedNumber = i;
        break;
      }
    }
  }

  // 整数座標に配置
  void addIntNode(Offset pos){
    int x = pos.dx.round();
    int y = pos.dy.round();

    for(int i = 0; i < nodeList.length; i++){
      if(x == nodeList[i].pos.dx.round() && y == nodeList[i].pos.dy.round()){
        return;
      }
    }

    Node node = Node();
    node.pos = Offset(x.toDouble(), y.toDouble());
    nodeList.add(node);

    // ノード番号
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].number = i;
    }
  }
  Node? getIntNode(Offset pos){
    int x = pos.dx.round();
    int y = pos.dy.round();

    for(int i = 0; i < nodeList.length; i++){
      if(x == nodeList[i].pos.dx.round() && y == nodeList[i].pos.dy.round()){
        return nodeList[i];
      }
    }

    return null;
  }
  void removeIntNode(Node node){
    if(nodeList.isNotEmpty){
      // 要素の削除
      for(int i = 0; i < elemList.length; i++){
        for(int j = 0; j < elemList[i].nodes.length; j++){
          if(node == elemList[i].nodes[j]){
            elemList.remove(elemList[i]);
          }
        }
      }
      // 節点の削除
      nodeList.remove(node);
    }

    // ノード番号
    for(int i = 0; i < nodeList.length; i++){
      nodeList[i].number = i;
    }
  }
  void addElem(List<Node> nodeList){
    // 同じノードがないか確認
    for(int i = 0; i < nodeList.length; i++){
      for(int j = 0; j < nodeList.length; j++){
        if(i != j && nodeList[i] == nodeList[j]){
          return;
        }
      }
    }
    // 既存の要素とかぶってないか確認
    for(int e = 0; e < elemList.length; e++){
      int count = 0;
      for(int i = 0; i < nodeList.length; i++){
        for(int j = 0; j < nodeList.length; j++){
          if(nodeList[i] == elemList[e].nodes[j]){
            count ++;
            if(count == nodeList.length){
              return;
            }
          }
        }
      }
    }
    
    Elem elem = Elem();
    elem.e = 1;
    elem.v = 1;
    for(int i = 0; i < nodeList.length; i++){
      elem.nodes.add(nodeList[i]);
    }
    elemList.add(elem);
  }
  Elem? getElem(Offset pos){
    for(int i = 0; i < elemList.length; i++){
      double distance = distanceFromPointToSegment(elemList[i].nodes[0].pos, elemList[i].nodes[1].pos, pos);

      if(distance < 1){
        selectedNumber = i;
        return elemList[i];
      }
    }
    return null;
  }


  // 計算結果の最大最小
  (double max, double min) getValue(){
    double max = 0;
    double min = 0;

    if(type == 0){
      max = elemList[0].stlessXY[0];
      min = elemList[0].stlessXY[0];
      if(elemList.length > 1){
        for (int i = 1; i < elemList.length; i++) {
          if(max < elemList[i].stlessXY[0]) max = elemList[i].stlessXY[0];
          if(min > elemList[i].stlessXY[0]) min = elemList[i].stlessXY[0];
        }
      }
    }
    else if(type == 1){
      max = elemList[0].stlessXY[1];
      min = elemList[0].stlessXY[1];
      if(elemList.length > 1){
        for (int i = 1; i < elemList.length; i++) {
          if(max < elemList[i].stlessXY[1]) max = elemList[i].stlessXY[1];
          if(min > elemList[i].stlessXY[1]) min = elemList[i].stlessXY[1];
        }
      }
    }
    else if(type == 2){
      max = elemList[0].strainXY[0];
      min = elemList[0].strainXY[0];
      if(elemList.length > 1){
        for (int i = 1; i < elemList.length; i++) {
          if(max < elemList[i].strainXY[0]) max = elemList[i].strainXY[0];
          if(min > elemList[i].strainXY[0]) min = elemList[i].strainXY[0];
        }
      }
    }
    else if(type == 3){
      max = elemList[0].strainXY[1];
      min = elemList[0].strainXY[1];
      if(elemList.length > 1){
        for (int i = 1; i < elemList.length; i++) {
          if(max < elemList[i].strainXY[1]) max = elemList[i].strainXY[1];
          if(min > elemList[i].strainXY[1]) min = elemList[i].strainXY[1];
        }
      }
    }

    return (max, min);
  }

  // 結果
  void selectResult(int num){
    if(num == 0){
      type = 0;
    }
    else if(num == 1){
      type = 2;
    }
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
}

class Node{
  int number = 0;
  Offset pos = const Offset(0, 0);
  List<bool> constXY = [false, false];
  List<double> loadXY = [0, 0];

  // 計算結果
  Offset becPos = const Offset(0, 0);
  Offset afterPos = const Offset(0, 0);
}
class Elem{
  int number = 0;
  List<int> nodeList = [0, 0, 0, 0];
  double e = 0;
  double v = 0;
  List<Node> nodes = List.empty(growable: true);
  Mat? mat;

  // 計算結果
  List<double> strainXY = [0,0,0]; // 0:X方向の正規ひずみ、1:Y方向の正規ひずみ、2:XY方向のせん断ひずみ
  List<double> stlessXY = [0,0,0,0,0]; // 0:X方向の正規応力、1:Y方向の正規応力、2:XY方向のせん断応力、3:最大主応力、4:最小主応力
}
class Mat{
  int number = 0;
  double e = 0;
  double v = 0;
}