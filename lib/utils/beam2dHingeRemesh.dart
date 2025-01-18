import 'dart:math';

// xyz0：元のX、mfix：拘束条件（0: x, 1: y, 2: 回転, 3: ヒンジ）、fnod：（0:点荷重、1:モーメント荷重）、
// ijk0：要素の節点番号、prop0：要素の（0:E、1:I）、felm：分布荷重w
(List<double> xyzn, List<double> dispY, List<List<int>> ijke, List<List<double>> result) beam2dHingeRemesh
  (List<double> xyz0, List<List<int>> mfix, List<List<double>> fnod, 
  List<List<int>> ijk0, List<List<double>> prp0, List<double> felm) 
{
  int nx = xyz0.length; // 節点数
  int nelx = ijk0.length; // 要素数

  List<List<int>> ijke = []; // 細分化されたIJK
  List<int> mdof = []; // 拘束のためのDOFテーブル
  List<List<List<int>>> mhng = []; // 中間ヒンジのためのDOFテーブル
  List<int> ndiv = List<int>.filled(nelx, 0); // 要素分割の数

  List<double> xyzn = []; // 細分化されたXYZ
  List<List<double>> prop = []; // 細分化された要素のE, I
  List<List<List<double>>> vske = []; // 要素剛性マトリックス
  List<double> fext = []; // 外部荷重ベクトル
  List<double> disp = []; // 変位ベクトル

  // CGM用
  List<double> diag = [];
  List<double> cgw1 = [];
  List<double> cgw2 = [];
  List<double> cgw3 = [];

  // Se, Ma, Mb
  List<List<double>> fint = [];


  // ヒンジの数をカウント
  int nhng = 0;
  for (int i = 0; i < nx; i++) {
    if (mfix[i][3] == 1) nhng++;
  }

  int node = 2;
  int ndof = 2;

  // IJKの修正 (a -> b)
  for (int ie = 0; ie < nelx; ie++) {
    int n1 = ijk0[ie][0];
    int n2 = ijk0[ie][1];
    if (xyz0[n2] - xyz0[n1] < 0.0) {
      ijk0[ie][0] = n2;
      ijk0[ie][1] = n1;
    }
  }

  //-----------------------------------------------------------------------------------------------
  // REMESH
  //-----------------------------------------------------------------------------------------------

  // 要素分割数を計算
  double xmax = xyz0.reduce(max);
  double xmin = xyz0.reduce(min);
  double hmax = xmax - xmin;
  double dhe = hmax / 100;

  for (int ie = 0; ie < nelx; ie++) {
    int n1 = ijk0[ie][0];
    int n2 = ijk0[ie][1];
    ndiv[ie] = ((xyz0[n2] - xyz0[n1]).abs() / dhe).toInt();
  }

  // 新しい要素数を計算
  int nelx2 = ndiv.reduce((a, b) => a + b); // 合計値
  int nx2 = nelx2 + 1;
  int neq = ndof * nx2 + nhng;

  // メモリの割り当て
  ijke = List.generate(nelx2, (_) => List<int>.filled(2, 0));
  xyzn = List<double>.filled(nx2, 0.0);
  prop = List.generate(nelx2, (_) => List<double>.filled(2, 0.0));

  // 新しいノードとXYZを計算
  int kn = nx-1;
  for (int ie = 0; ie < nelx; ie++) {
    double x1 = xyz0[ijk0[ie][0]];
    double x2 = xyz0[ijk0[ie][1]];
    for (int je = 1; je < ndiv[ie]; je++) {
      kn++;
      double dh = (x2 - x1) / ndiv[ie];
      xyzn[kn] = x1 + dh * je;
    }
  }
  xyzn.setRange(0, nx, xyz0); // 0~nxまでは元のxyzを入れる

  // 新しい要素とIJKを計算
  int ke = 1;
  kn = nx-1;
  for (int ie = 0; ie < nelx; ie++) {
    for (int je = 0; je < ndiv[ie]; je++) {
      prop[ke - 1] = List.from(prp0[ie]);
      if (je == 0) {
        kn++;
        ijke[ke - 1][0] = ijk0[ie][0];
        ijke[ke - 1][1] = kn;
      } else if (je == ndiv[ie] - 1) {
        ijke[ke - 1][0] = kn;
        ijke[ke - 1][1] = ijk0[ie][1];
      } else {
        kn++;
        ijke[ke - 1][0] = kn - 1;
        ijke[ke - 1][1] = kn;
      }
      ke++;
    }
  }

  // メモリの割り当て (2)
  mdof = List<int>.filled(neq, 0);
  fext = List<double>.filled(neq, 0.0);
  disp = List<double>.filled(neq, 0.0);
  diag = List<double>.filled(neq, 0.0);
  cgw1 = List<double>.filled(neq, 0.0);
  cgw2 = List<double>.filled(neq, 0.0);
  cgw3 = List<double>.filled(neq, 0.0);

  // メモリの割り当て (3)
  vske = List.generate(nelx2, (_) => List.generate(4, (_) => List<double>.filled(4, 0.0)));
  fint = List.generate(nelx2, (_) => List<double>.filled(3, 0.0));
  mhng = List.generate(nelx2, (_) => List.generate(node, (_) => List<int>.filled(ndof, 0)));

  //-----------------------------------------------------------------------------------------------
  // DOFTAB
  //-----------------------------------------------------------------------------------------------

  // DOFテーブル（拘束用）を初期化
  mdof.fillRange(0, mdof.length, 1);
  for (int ix = 0; ix < nx; ix++) {
    if (mfix[ix][1] == 1) mdof[2 * ix] = 0;
    if (mfix[ix][2] == 1) mdof[2 * ix + 1] = 0;
  }

  // DOFテーブル（中間ヒンジ用）を初期化
  for (int ie = 0; ie < nelx2; ie++) {
    for (int jn = 0; jn < node; jn++) {
      for (int kd = 0; kd < ndof; kd++) {
        mhng[ie][jn][kd] = ndof * ijke[ie][jn] + kd;
      }
    }
  }

  // 中間ヒンジを考慮
  int ihng = 0;
  for (int ix = 0; ix < nx; ix++) {
    if (mfix[ix][3] == 1) {
      ihng++;
      bool iend = false;
      for (int je = 0; je < nelx2; je++) {
        for (int jn = 0; jn < ndof; jn++) {
          if (ijke[je][jn] == ix && !iend) {
            mhng[je][jn][1] = ndof * nx2 + ihng-1;
            iend = true;
          }
        }
      }
    }
  }

  //-----------------------------------------------------------------------------------------------
  // MATRIX
  //-----------------------------------------------------------------------------------------------

  // 剛性マトリックスの計算
  for (int ie = 0; ie < nelx2; ie++) {
    double ei = prop[ie][0] * prop[ie][1];
    int n1 = ijke[ie][0];
    int n2 = ijke[ie][1];
    double he = (xyzn[n2] - xyzn[n1]).abs();

    vske[ie][0][0] = 12.0 * ei / pow(he, 3);
    vske[ie][0][1] = 6.0 * he * ei / pow(he, 3);
    vske[ie][0][2] = -12.0 * ei / pow(he, 3);
    vske[ie][0][3] = 6.0 * he * ei / pow(he, 3);
    vske[ie][1][0] = 6.0 * he * ei / pow(he, 3);
    vske[ie][1][1] = 4.0 * pow(he, 2) * ei / pow(he, 3);
    vske[ie][1][2] = -6.0 * he * ei / pow(he, 3);
    vske[ie][1][3] = 2.0 * pow(he, 2) * ei / pow(he, 3);
    vske[ie][2][0] = -12.0 * ei / pow(he, 3);
    vske[ie][2][1] = -6.0 * he * ei / pow(he, 3);
    vske[ie][2][2] = 12.0 * ei / pow(he, 3);
    vske[ie][2][3] = -6.0 * he * ei / pow(he, 3);
    vske[ie][3][0] = 6.0 * he * ei / pow(he, 3);
    vske[ie][3][1] = 2.0 * pow(he, 2) * ei / pow(he, 3);
    vske[ie][3][2] = -6.0 * he * ei / pow(he, 3);
    vske[ie][3][3] = 4.0 * pow(he, 2) * ei / pow(he, 3);
  }

  // 分布荷重ベクトルの計算
  fext.fillRange(0, fext.length, 0.0);
  ke = 0;
  for (int ie = 0; ie < nelx; ie++) {
    double we = felm[ie];
    for (int je = 0; je < ndiv[ie]; je++) {
      ke++;
      int n1 = ijke[ke - 1][0];
      int n2 = ijke[ke - 1][1];
      double he = (xyzn[n2] - xyzn[n1]).abs();

      fext[mhng[ke - 1][0][0]] += we * he / 2.0;
      fext[mhng[ke - 1][0][1]] += we * he / 2.0 * he / 6.0;
      fext[mhng[ke - 1][1][0]] += we * he / 2.0;
      fext[mhng[ke - 1][1][1]] -= we * he / 2.0 * he / 6.0;
    }
  }

  // 点荷重ベクトルの計算
  for (int ix = 0; ix < nx; ix++) {
    fext[ndof * ix] += fnod[ix][0];
    if (mfix[ix][3] == 0) {
      fext[ndof * ix + 1] += fnod[ix][1];
    }
  }

  // 変位ベクトルの初期化
  disp.fillRange(0, disp.length, 0.0);

  //-----------------------------------------------------------------------------------------------
  // SOLVER
  //-----------------------------------------------------------------------------------------------

  // 対角スケーリング
  for (int ie = 0; ie < nelx2; ie++) {
    for (int io = 0; io < node; io++) {
      int ic = ijke[ie][io];
      for (int id = 0; id < ndof; id++) {
        int ii = ndof * io + id;
        int ig = ndof * (ic - 1) + id;
        ig = mhng[ie][io][id];
        diag[ig] += vske[ie][ii][ii];
      }
    }
  }

  for (int i = 0; i < neq; i++) {
    double dv = diag[i].abs();
    diag[i] = dv > 1e-9 ? 1.0 / sqrt(dv) : 1.0;
  }

  // 外部荷重のスケーリング
  for (int i = 0; i < neq; i++) {
    if (mdof[i] >= 1) {
      cgw1[i] = fext[i] * diag[i];
      cgw2[i] = cgw1[i];
    }
  }

  // 初期のr0_r0の計算
  double r0r0 = 0.0;
  for (int i = 0; i < neq; i++) {
    r0r0 += cgw1[i] * cgw1[i];
  }

  // CG反復法のループ
  for (int kcg = 1; kcg <= neq * 10; kcg++) {
    // 行列ベクトル積
    cgw3.fillRange(0, cgw3.length, 0.0);
    for (int ie = 0; ie < nelx2; ie++) {
      for (int io = 0; io < 2; io++) {
        int ic = ijke[ie][io];
        for (int id = 0; id < 2; id++) {
          int ii = 2 * io + id;
          int ig = 2 * (ic - 1) + id;
          ig = mhng[ie][io][id];
          double di = diag[ig];
          if (mdof[ig] >= 1) {
            for (int ko = 0; ko < 2; ko++) {
              int kc = ijke[ie][ko];
              for (int kd = 0; kd < 2; kd++) {
                int kk = 2 * ko + kd;
                int kg = 2 * (kc - 1) + kd;
                kg = mhng[ie][ko][kd];
                double dk = diag[kg];
                cgw3[ig] += di * dk * vske[ie][ii][kk] * cgw2[kg];
              }
            }
          }
        }
      }
    }

    // 内積の計算
    double app = 0.0;
    double rr = 0.0;
    for (int i = 0; i < neq; i++) {
      app += cgw3[i] * cgw2[i];
      rr += cgw1[i] * cgw1[i];
    }
    double alph = rr / app;

    // 変位ベクトルの更新
    for (int i = 0; i < neq; i++) {
      disp[i] += alph * cgw2[i];
      cgw1[i] -= alph * cgw3[i];
    }

    // 新しいr1_r1の計算
    double r1r1 = 0.0;
    for (int i = 0; i < neq; i++) {
      r1r1 += cgw1[i] * cgw1[i];
    }
    if (r1r1 < 1e-99) r1r1 = 1e-9;

    // 収束のチェック
    if (sqrt(rr / r0r0) < 1e-12) {
      for (int i = 0; i < neq; i++) {
        disp[i] *= diag[i];
      }
      break;
    } else {
      double beta = r1r1 / rr;
      for (int i = 0; i < neq; i++) {
        cgw2[i] = cgw1[i] + beta * cgw2[i];
      }
    }

    if(kcg == neq * 10){ // エラー時
      return (xyzn, disp, ijke, fint);
    }
  }

  //-----------------------------------------------------------------------------------------------
  // POSTPR
  //-----------------------------------------------------------------------------------------------

  // せん断力と曲げモーメントの計算
  for (int ie = 0; ie < nelx2; ie++) {
    int n1 = ijke[ie][0];
    int n2 = ijke[ie][1];
    double v1 = disp[mhng[ie][0][0]];
    double q1 = disp[mhng[ie][0][1]];
    double v2 = disp[mhng[ie][1][0]];
    double q2 = disp[mhng[ie][1][1]];

    double ei = prop[ie][0] * prop[ie][1];
    double he = (xyzn[n2] - xyzn[n1]).abs();

    double se = -ei / (he * he) * (12.0 / he * v1 + 6.0 * q1 - 12.0 / he * v2 + 6.0 * q2);
    double b1 = ei / he * (-6.0 / he * v1 - 4.0 * q1 + 6.0 / he * v2 - 2.0 * q2);
    double b2 = ei / he * (6.0 / he * v1 + 2.0 * q1 - 6.0 / he * v2 + 4.0 * q2);

    fint[ie][0] = -se; // せん断力
    fint[ie][1] = b1; // 曲げモーメント
    fint[ie][2] = b2; // 曲げモーメント
  }

  // 本来せん断力が0のとき（モーメント荷重のときは普通0、解析だと誤差がでる）
  double sumShear = 0.0;
  double sumBend = 0.0;
  for (int ie = 0; ie < nelx2; ie++) {
    sumShear += fint[ie][0].abs();
    sumBend += fint[ie][1].abs();
  }

  if ( sumShear < sumBend * 0.001 ) {
    for (int ie = 0; ie < nelx2; ie++) {
      fint[ie][0] = 0.0;
    }
  } 

  //-----------------------------------------------------------------------------------------------
  // WRITE
  //-----------------------------------------------------------------------------------------------

  List<double> dispY = List.filled(nx2, 0);
  for(int i = 0; i < nx2; i++){
    dispY[i] = disp[ndof*i];
  }

  List<List<double>> result = List.generate(nelx2, (_) => List<double>.filled(7, 0));
  for(int i = 0; i < nelx2; i++){
    for(int j = 0; j < node; j++){
      result[i][j*2] = disp[mhng[i][j][0]]; //たわみ
      result[i][j*2+1] = disp[mhng[i][j][1]]; // たわみ角
    }
    result[i][4] = fint[i][0]; // せん断力
    result[i][5] = fint[i][1]; // 曲げモーメント
    result[i][6] = fint[i][2]; // 曲げモーメント
  }

  return (xyzn, dispY, ijke, result);
}
