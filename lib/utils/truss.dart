// import 'dart:math';
// import 'dart:ui';

// class Truss{
//   late List<List<int>> ijke; // エレメント
//   late List<List<double>> xyzn; // 節点
//   late List<List<double>> pmat; // マテリアル

//   late List<List<int>> mspc;
//   late List<List<double>> vspc;

//   run(){
//     // 要素データ
//     List<double> lengthList = List.empty(growable: true);
//     List<double> cosList = List.empty(growable: true);
//     List<double> sinList = List.empty(growable: true);

//     for(int i = 0; i < ijke.length; i++){
//       List<double> pos0 = xyzn[ijke[i][0]];
//       List<double> pos1 = xyzn[ijke[i][1]];

//       lengthList.add((pos1 - pos0).distance);

//       double angle = atan2(pos1[1] - pos0[1], pos1[0] - pos0[0]);
//       cosList.add(cos(angle));
//       sinList.add(sin(angle));
//     }

//     // 全体剛性行列
//     List<List<double>> kkk = List.generate(xyzn.length * 2, (i) => List.generate(xyzn.length * 2, (j) => 0.0));
    
//     for(int i = 0; i < ijke.length; i++){
//       double eal = pmat[0][0] * pmat[0][1] / lengthList[i];
//       double k11 = eal * cosList[i] * cosList[i];
//       double k12 = eal * cosList[i] * sinList[i];
//       double k21 = k12;
//       double k22 = eal * sinList[i] * sinList[i];

//       kkk[ijke[i][0]*2][ijke[i][0]*2] += k11;
//       kkk[ijke[i][0]*2][ijke[i][0]*2+1] += k12;
//       kkk[ijke[i][0]*2+1][ijke[i][0]*2] += k21;
//       kkk[ijke[i][0]*2+1][ijke[i][0]*2+1] += k22;

//       kkk[ijke[i][0]*2][ijke[i][1]*2] -= k11;
//       kkk[ijke[i][0]*2][ijke[i][1]*2+1] -= k12;
//       kkk[ijke[i][0]*2+1][ijke[i][1]*2] -= k21;
//       kkk[ijke[i][0]*2+1][ijke[i][1]*2+1] -= k22;

//       kkk[ijke[i][1]*2][ijke[i][0]*2] -= k11;
//       kkk[ijke[i][1]*2][ijke[i][0]*2+1] -= k12;
//       kkk[ijke[i][1]*2+1][ijke[i][0]*2] -= k21;
//       kkk[ijke[i][1]*2+1][ijke[i][0]*2+1] -= k22;

//       kkk[ijke[i][1]*2][ijke[i][1]*2] += k11;
//       kkk[ijke[i][1]*2][ijke[i][1]*2+1] += k12;
//       kkk[ijke[i][1]*2+1][ijke[i][1]*2] += k21;
//       kkk[ijke[i][1]*2+1][ijke[i][1]*2+1] += k22;
//     }

//     // 縮約行列
//     List<List<double>> kk = List.generate(kkk.length, (i) => List.generate(kkk[i].length, (j) => kkk[i][j]));

//     for(int i = xyzn.length - 1; i > - 1; i--){
//       if(xyzn[i].constXY[1]){
//         for (var row in kk) {
//           row.removeAt(i*2+1);
//         }
//         kk.removeAt(i*2+1);
//       }
//       if(nodeList[i].constXY[0]){
//         for (var row in kk) {
//           row.removeAt(i*2);
//         }
//         kk.removeAt(i*2);
//       }
//     }

//     // 荷重
//     List<double> powList = List.empty(growable: true);
//     for(int i = 0; i < xyzn.length; i++){
//       if(nodeList[i].constXY[0] == false){
//         powList.add(nodeList[i].loadXY[0]);
//       }
//       if(nodeList[i].constXY[1] == false) powList.add(nodeList[i].loadXY[1]);
//     }

//     List<double> becList = Calculator().conjugateGradient(kk, powList, 100, 1e-10);
//     int count = 0;
//     for(int i = 0; i < nodeList.length; i++){
//       if(nodeList[i].constXY[0] == false){
//         nodeList[i].becPos = Offset(becList[count], nodeList[i].becPos.dy);
//         count ++;
//       }
//       if(nodeList[i].constXY[1] == false){
//         nodeList[i].becPos = Offset(nodeList[i].becPos.dx, becList[count]);
//         count ++;
//       }
//     }

//     List<List<double>> stn = List.generate(10, (_) => List<double>.filled(ijke.length, 0.0));
//     List<List<double>> sts = List.generate(10, (_) => List<double>.filled(ijke.length, 0.0));

//     // 変位計算
//     for(int i = 0; i < xyzn.length; i++){
//       nodeList[i].afterPos = Offset(nodeList[i].pos.dx + nodeList[i].becPos.dx, nodeList[i].pos.dy + nodeList[i].becPos.dy);
//     }

//     // ひずみ
//     for(int i = 0; i < ijke.length; i++){
//       stn[i][0] = ((cosList[i]*nodeList[elemList[i].nodeList[1]].becPos.dx + sinList[i]*nodeList[elemList[i].nodeList[1]].becPos.dy) 
//         - (cosList[i]*nodeList[elemList[i].nodeList[0]].becPos.dx + sinList[i]*nodeList[elemList[i].nodeList[0]].becPos.dy)) / lengthList[i];
//     }

//     // 応力
//     for(int i = 0; i < ijke.length; i++){
//       sts[i][0] = pmat[i][0] * stn[i][0];
//     }
//   }
// }