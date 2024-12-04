import 'dart:math';
import 'dart:ui';

import 'package:kozo/models/data.dart';
import 'package:kozo/utils/beam2dHingeRemesh.dart';
import 'package:kozo/utils/calculator.dart';
import 'package:kozo/utils/des_fem70x25.dart';

 // 解析ができるかどうか
bool _isCanCalculation(List<Node> nodeList, List<Elem> elemList, int elemNode)
{
  if(nodeList.isEmpty) return false;
  if(elemList.isEmpty) return false;
  for(int i = 0; i < elemList.length; i++){
    if(elemList[i].e <= 0 || elemList[i].v <= 0){
      return false;
    }
    for(int j = 0; j < elemNode; j++){
      if(elemList[i].nodeList[j] == null){
        return false;
      }
    }
  }

  return true;
}

// 三角形の解析
void lcst2ebe()
{
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

  // Lcst2ebe lcst2ebe = Lcst2ebe(
  //   onDebug:(value) {
  //     onDebug(value);
  //   },
  // );

  // // 初期化
  // lcst2ebe.nd = 2;
  // lcst2ebe.node = 3;
  // lcst2ebe.nbcm = 3;
  // lcst2ebe.nsk = 6;

  // // 節点
  // lcst2ebe.nx = nodeList.length;
  // lcst2ebe.xyzn = List.generate(lcst2ebe.nx, (i) => List.filled(3, 0.0));
  // for (int i = 0; i < lcst2ebe.nx; i++) {
  //   lcst2ebe.xyzn[i][0] = nodeList[i].pos.dx;
  //   lcst2ebe.xyzn[i][1] = nodeList[i].pos.dy;
  // }

  // // 要素
  // lcst2ebe.nelx = elemList.length;
  // lcst2ebe.node = 3;
  // lcst2ebe.ijke = List.generate(lcst2ebe.nelx, (i) => List.filled(lcst2ebe.node + 2, 0));
  // for (int i = 0; i < lcst2ebe.nelx; i++) {
  //   for (int j = 0; j < lcst2ebe.node; j++) {
  //     lcst2ebe.ijke[i][j] = elemList[i].nodeList[j];
  //   }
  // }

  // // マテリアル
  // lcst2ebe.nmat = 1;
  // lcst2ebe.pmat = List.generate(lcst2ebe.nmat, (i) => List.filled(20, 0.0));
  // for (int i = 0; i < lcst2ebe.nmat; i++) {
  //   lcst2ebe.pmat[i][0] = elemList[0].e;
  //   lcst2ebe.pmat[i][1] = elemList[0].v;
  // }

  // // 拘束
  // lcst2ebe.mspc = List.empty(growable: true);
  // lcst2ebe.vspc = List.empty(growable: true);
  // lcst2ebe.nspc = 0;
  // for(int i = 0; i < nodeList.length; i++){
  //   if(nodeList[i].constXY[0] || nodeList[i].constXY[1] || nodeList[i].loadXY[0] != 0 || nodeList[i].loadXY[1] != 0){
  //     lcst2ebe.mspc.add(List.filled(7, 0));
  //     lcst2ebe.vspc.add(List.filled(6, 0.0));
  //     lcst2ebe.mspc[lcst2ebe.nspc][0] = i;
  //     if(nodeList[i].constXY[0] || nodeList[i].loadXY[0] != 0){
  //       lcst2ebe.mspc[lcst2ebe.nspc][1] = 1;
  //       lcst2ebe.vspc[lcst2ebe.nspc][0] = nodeList[i].loadXY[0];
  //     }
  //     if(nodeList[i].constXY[1] || nodeList[i].loadXY[1] != 0){
  //       lcst2ebe.mspc[lcst2ebe.nspc][2] = 1;
  //       lcst2ebe.vspc[lcst2ebe.nspc][1] = nodeList[i].loadXY[1];
  //     }
  //     lcst2ebe.nspc += 1;
  //   }
  // }

  // lcst2ebe.neq = lcst2ebe.nd * lcst2ebe.nx;

  // // 解析実行
  // final result = lcst2ebe.run();

  // // 結果入手
  // for (int i = 0; i < lcst2ebe.nx; i++) {
  //   nodeList[i].becPos = Offset(result.$1[lcst2ebe.nd*i], result.$1[lcst2ebe.nd*i+1]);
  // }

  // for (int i = 0; i < lcst2ebe.nelx; i++) {
  //   elemList[i].strainXY[0] = result.$2[0][i];
  //   elemList[i].strainXY[1] = result.$2[1][i];
  //   elemList[i].stlessXY[0] = result.$3[0][i];
  //   elemList[i].stlessXY[1] = result.$3[1][i];
  // }
}

// 四角形の解析
void lcst2ebe4()
{
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

  // Lcst2ebe4 lcst2ebe4 = Lcst2ebe4(
  //   onDebug:(value) {
  //     onDebug(value);
  //   },
  // );

  // // 初期化
  // lcst2ebe4.nd = 2;// ２次元
  // lcst2ebe4.node = 4;// 四角形
  // lcst2ebe4.nbcm = 3;
  // lcst2ebe4.nsk = 8;

  // // 節点
  // lcst2ebe4.nx = nodeList.length;
  // lcst2ebe4.xyzn = List.generate(lcst2ebe4.nx, (i) => List.filled(3, 0.0));
  // for (int i = 0; i < lcst2ebe4.nx; i++) {
  //   lcst2ebe4.xyzn[i][0] = nodeList[i].pos.dx;
  //   lcst2ebe4.xyzn[i][1] = nodeList[i].pos.dy;
  // }

  // // 要素
  // lcst2ebe4.nelx = elemList.length;
  // lcst2ebe4.ijke = List.generate(lcst2ebe4.nelx, (i) => List.filled(lcst2ebe4.node + 2, 0));
  // for (int i = 0; i < lcst2ebe4.nelx; i++) {
  //   for (int j = 0; j < lcst2ebe4.node; j++) {
  //     lcst2ebe4.ijke[i][j] = elemList[i].nodeList[j];
  //   }
  // }

  // // マテリアル
  // lcst2ebe4.nmat = 1;
  // lcst2ebe4.pmat = List.generate(lcst2ebe4.nmat, (i) => List.filled(20, 0.0));
  // for (int i = 0; i < lcst2ebe4.nmat; i++) {
  //   lcst2ebe4.pmat[i][0] = elemList[0].e;
  //   lcst2ebe4.pmat[i][1] = elemList[0].v;
  // }

  // // 拘束
  // lcst2ebe4.mspc = List.empty(growable: true);
  // lcst2ebe4.vspc = List.empty(growable: true);
  // lcst2ebe4.nspc = 0;
  // for(int i = 0; i < nodeList.length; i++){
  //   if(nodeList[i].constXY[0] || nodeList[i].constXY[1] || nodeList[i].loadXY[0] != 0 || nodeList[i].loadXY[1] != 0){
  //     lcst2ebe4.mspc.add(List.filled(7, 0));
  //     lcst2ebe4.vspc.add(List.filled(6, 0.0));
  //     lcst2ebe4.mspc[lcst2ebe4.nspc][0] = i;
  //     if(nodeList[i].constXY[0] || nodeList[i].loadXY[0] != 0){
  //       lcst2ebe4.mspc[lcst2ebe4.nspc][1] = 1;
  //       lcst2ebe4.vspc[lcst2ebe4.nspc][0] = nodeList[i].loadXY[0];
  //     }
  //     if(nodeList[i].constXY[1] || nodeList[i].loadXY[1] != 0){
  //       lcst2ebe4.mspc[lcst2ebe4.nspc][2] = 1;
  //       lcst2ebe4.vspc[lcst2ebe4.nspc][1] = nodeList[i].loadXY[1];
  //     }
  //     lcst2ebe4.nspc += 1;
  //   }
  // }

  // lcst2ebe4.neq = lcst2ebe4.nd * lcst2ebe4.nx;

  // // 解析実行
  // final result = lcst2ebe4.run();

  // // 結果入手
  // for (int i = 0; i < lcst2ebe4.nx; i++) {
  //   nodeList[i].becPos = Offset(result.$1[lcst2ebe4.nd*i], result.$1[lcst2ebe4.nd*i+1]);
  // }

  // for (int i = 0; i < lcst2ebe4.nelx; i++) {
  //   elemList[i].strainXY[0] = result.$2[0][i];
  //   elemList[i].strainXY[1] = result.$2[1][i];
  //   elemList[i].stlessXY[0] = result.$3[0][i];
  //   elemList[i].stlessXY[1] = result.$3[1][i];
  // }
}

// 橋の解析
void calculationDes(List<Node> nodeList, List<Elem> elemList, int elemNode, int powerType)
{
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
  // 変位を最大3に変更
  double maxDirY = 0;
  for(int i = 0; i < nodeList.length; i++){
    maxDirY = max(maxDirY, nodeList[i].becPos.dy.abs());
  }
  double size = 3 / maxDirY;
  for (int n2 = 0; n2 < npx2+1; n2++) {
    for (int n1 = 0; n1 < npx1+1; n1++) {
      nodeList[(npx1+1)*(npx2-n2)+n1].becPos *= size;
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
}

// トラスの解析
void calculationTruss(List<Node> nodeList, List<Elem> elemList, int elemNode)
{
  if(!_isCanCalculation(nodeList, elemList, elemNode)) return;

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
    if(nodeList[i].constXYR[1]){
      for (var row in kk) {
        row.removeAt(i*2+1);
      }
      kk.removeAt(i*2+1);
    }
    if(nodeList[i].constXYR[0]){
      for (var row in kk) {
        row.removeAt(i*2);
      }
      kk.removeAt(i*2);
    }
  }

  // 荷重
  List<double> powList = List.empty(growable: true);
  for(int i = 0; i < nodeList.length; i++){
    if(nodeList[i].constXYR[0] == false){
      powList.add(nodeList[i].loadXY[0]);
    }
    if(nodeList[i].constXYR[1] == false) powList.add(nodeList[i].loadXY[1]);
  }

  // 変位計算
  List<double> becList = Calculator().conjugateGradient(kk, powList, 100, 1e-10);
  int count = 0;
  for(int i = 0; i < nodeList.length; i++){
    if(nodeList[i].constXYR[0] == false){
      nodeList[i].becPos = Offset(becList[count], nodeList[i].becPos.dy);
      count ++;
    }
    if(nodeList[i].constXYR[1] == false){
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
}

// はりの解析
(List<Node> resultNodeList, List<Elem> resultElemList) calculationBeam(List<Node> nodeList, List<Elem> elemList, int elemNode)
{
  if(!_isCanCalculation(nodeList, elemList, elemNode)) return ([],[]);

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
  List<Node> resultNodeList = [];
  List<Elem> resultElemList = [];
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

  return (resultNodeList, resultElemList);
}
