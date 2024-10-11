import 'dart:math';

// FEM4角形要素
class Lcst2ebe4 {
  Lcst2ebe4({required this.onDebug});
  final Function(String value) onDebug;

  // パラメータ
  int idcmat = 0; // 平面応力（1）または平面ひずみ（2）の識別子
  int nd = 0;     // 次元数（2-Dまたは3-D）
  int node = 0;   // 要素あたりのノード数
  int nbcm = 0;   // C行列のサイズ
  int nsk = 0;    // 要素剛性行列のサイズ

  int nx = 0;     // 総ノード数
  int nelx = 0;   // 総要素数
  int nmat = 0;   // 総材料数

  int nspc = 0;   // 総変位数
  int npld = 0;   // 総点荷重数

  int neq = 0;    // 総自由度数

  double energy = 0.0; // ひずみエネルギー

  // Allocatable arrays
  late List<List<int>> ijke;
  late List<List<int>> mspc;
  late List<int> mpld;

  late List<List<double>> xyzn;
  late List<List<double>> pmat;
  late List<List<double>> vspc;
  late List<List<double>> vpld;

  (List<int> mdof, List<double> fext, List<double> disp, List<List<List<double>>> vske) assemb() {
    // 初期化
    List<int> mdof = List<int>.filled(neq, 0);
    List<double> fext = List<double>.filled(neq, 0.0);
    List<double> disp = List<double>.filled(neq, 0.0);
    List<List<List<double>>> vske = List.generate(nsk, (_) => List.generate(nsk, (_) => List<double>.filled(nelx, 0.0)));
    List<List<double>> gaussPoints =[[-1/sqrt(3),-1/sqrt(3)],[1/sqrt(3),1/sqrt(3)]];

    for (int e = 0; e < nelx; e++) {
      // 各要素のノードを取得
      List<List<double>> xe = [];
      for (int i = 0; i < node; i++) {
        xe.add(xyzn[ijke[e][i]]);
      }

      // C-Matrix
      int imat = ijke[e][node];
      double yng = pmat[imat][0];
      double poi = pmat[imat][1];
      final resultCmatrx = cmatrx(yng, poi);
      List<List<double>> D = resultCmatrx.$1;

      // 剛性行列の初期化
      List<List<double>> ke = List.generate(8, (_) => List.filled(8, 0.0)); // 8x8の剛性行列

      // 各ガウスポイントでの剛性行列の積分
      for (int gp = 0; gp < 2; gp++) {
        for (int gp2 = 0; gp2 < 2; gp2++) {
          // 形状関数とB行列の計算
          final resultCstnbm = cstnbm(xe, gaussPoints[gp][0], gaussPoints[gp2][1], 0);
          double vol = resultCstnbm.$1;
          List<List<double>> B = resultCstnbm.$3;

          // 剛性行列を計算
          for (int i = 0; i < 8; i++) {
            for (int j = 0; j < 8; j++) {
              for (int k = 0; k < 3; k++) {
                for (int l = 0; l < 3; l++) {
                  ke[i][j] += B[k][i] * D[k][l] * B[l][j] * vol;
                }
              }
            }
          }
        }
      }

      // グローバルの自由度番号を取得
      List<int> edof = [];
      for (int i = 0; i < node; i++) {
        edof.add(ijke[e][i] * 2);
        edof.add(ijke[e][i] * 2 + 1);
      }

      // 剛性行列を全体剛性行列に組み込む
      for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
          vske[edof[i]][edof[j]][e] += ke[i][j];
        }
      }
    }

    // Initialize
    for (int i = 0; i < neq; i++) {
      mdof[i] = 1;// 拘束条件
      fext[i] = 0.0;// 外力ベクトル
      disp[i] = 0.0;// 変位ベクトル
    }

    // Loading B.C.
    for (int i = 0; i < npld; i++) {
      int ipld = mpld[i];
      for (int j = 0; j < nd; j++) {
        int ijd = nd * (ipld - 1) + j;
        fext[ijd] = vpld[i][j];
      }
    }

    // Displacement B.C.
    for (int i = 0; i < nspc; i++) {
      int ispc = mspc[i][0]; // 強制されている点番号
      for (int j = 0; j < nd; j++) {
        if (mspc[i][1 + j] == 1) {
          int ijd = nd * ispc + j;
          mdof[ijd] = 0;
          disp[ijd] = vspc[i][j];
        }
      }
    }

    return (mdof, fext, disp, vske);
  }

  (List<List<double>> ccc,) cmatrx(double yng, double poi) {
    List<List<double>> ccc = List.generate(6, (_) => List.filled(6, 0.0));

    // Initialize array
    for (int i = 0; i < ccc.length; i++) {
      for (int j = 0; j < ccc[i].length; j++) {
        ccc[i][j] = 0.0;
      }
    }

    // Material property
    double vmu = yng / (2.0 * (1.0 + poi));
    double vlm = poi * yng / ((1.0 + poi) * (1.0 - 2.0 * poi));

    // Plane STRESS
    if (idcmat == 1) {
      ccc[0][0] = 1.0;
      ccc[1][1] = 1.0;
      ccc[2][2] = (1.0 - poi) / 2.0;
      ccc[0][1] = poi;
      ccc[1][0] = poi;
      for (int i = 0; i < ccc.length; i++) {
        for (int j = 0; j < ccc[i].length; j++) {
          ccc[i][j] *= yng / (1.0 - poi * poi);
        }
      }
    }
    // Plane STRAIN
    else if (idcmat == 2) {
      double rmd = yng / ((1.0 + poi) * (1.0 - 2.0 * poi));
      ccc[0][0] = 1.0;
      ccc[1][1] = 1.0;
      ccc[2][2] = (1.0 - 2.0 * poi) / 2.0 / (1.0 - poi);
      ccc[0][1] = poi / (1.0 - poi);
      ccc[1][0] = poi / (1.0 - poi);
      for (int i = 0; i < ccc.length; i++) {
        for (int j = 0; j < ccc[i].length; j++) {
          ccc[i][j] *= rmd * (1.0 - poi);
        }
      }
    }
    // 3-DIMENSION
    else {
      double rmd = yng / ((1.0 + poi) * (1.0 - 2.0 * poi));
      for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 3; j++) {
          if (i == j) {
            ccc[i][j] = rmd * (1.0 - poi);
          } else {
            ccc[i][j] = vlm;
          }
        }
      }
      ccc[3][3] = vmu;
      ccc[4][4] = vmu;
      ccc[5][5] = vmu;
    }

    return (ccc,);
  }

  (double vol, List<List<double>> shm, List<List<double>> bbb) cstnbm(List<List<double>> xe, double xxx, double yyy, double zzz) {
    // 四角形要素の形状関数の計算
    double xi = xxx;// E
    double eta = yyy;// n
    List<List<double>> ge = [
      [0.25*(eta-1), 0.25*(xi-1)], [0.25*(-eta+1), 0.25*(-xi-1)], [0.25*(eta+1), 0.25*(xi+1)], [0.25*(-eta-1), 0.25*(-xi+1)]
    ];
    
    // ジャコビアン行列の計算
    List<List<double>> jacobian = [[0, 0], [0, 0]];
    for (int i = 0; i < 4; i++) {
      jacobian[0][0] += xe[i][0] * ge[i][0];
      jacobian[0][1] += xe[i][0] * ge[i][1];
      jacobian[1][0] += xe[i][1] * ge[i][0];
      jacobian[1][1] += xe[i][1] * ge[i][1];
    }
    
    // ジャコビアンの行列式と逆行列の計算
    double detJ = jacobian[0][0] * jacobian[1][1] - jacobian[0][1] * jacobian[1][0];
    List<List<double>> invJ = [[jacobian[1][1] / detJ, -jacobian[0][1] / detJ], [-jacobian[1][0] / detJ, jacobian[0][0] / detJ]];

    // gx=ge*invJ
    List<List<double>> gx = List.generate(4, (_) => List<double>.filled(2, 0.0));
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 2; j++) {
        for (int k = 0; k < 2; k++) {
          gx[i][j] += ge[i][k]*invJ[k][j];
        }
      }
    }

    // B行列の計算
    List<List<double>> B = List.generate(3, (_) => List.filled(8, 0.0));
    for (int i = 0; i < 4; i++) {
      B[0][2*i] = gx[i][0];
      B[1][2*i + 1] = gx[i][1];
      B[2][2*i] = gx[i][1];
      B[2][2*i + 1] = gx[i][0];
    }
    
    return (detJ, ge, B);
  }

  (List<double> disp,) ebecgm(List<int> mdof, List<List<List<double>>> vske, List<double> xx, List<double> bb) {
    int kcg = 0;
    List<double> dg = List<double>.filled(neq, 0.0);
    List<double> rr = List<double>.filled(neq, 0.0);
    List<double> pp = List<double>.filled(neq, 0.0);
    List<double> ap = List<double>.filled(neq, 0.0);
    double ctol = 1e-10;

    // mdof:各節点の各軸がなにもされていないと1，拘束や強制変位されてると0
    // xx=disp：各節点各軸の強制変位

    // --- Diagonal component ---全体剛性行列の対角成分(dg)を計算
    for (int i = 0; i < neq; i++) {
      dg[i] = 0.0;
    }
    for (int ie = 0; ie < nelx; ie++) {
      for (int io = 0; io < node; io++) {
        int ic = ijke[ie][io];
        for (int id = 0; id < nd; id++) {
          int ii = nd * io + id;
          int ig = nd * ic + id;
          dg[ig] += vske[ii][ii][ie];
        }
      }
    }

    // --- Diagonal scaling ---上記のつづき
    for (int i = 0; i < neq; i++) {
      double dv = dg[i].abs();
      if (dv > 1.0e-9) {
        dg[i] = 1.0 / sqrt(dv);
      } else {
        dg[i] = 1.0;
      }
    }

    // Diagonal scaling & initialize
    for (int i = 0; i < neq; i++) {
      rr[i] = 0.0;
      ap[i] = 0.0;
      xx[i] /= dg[i];
    }
    for (int i = 0; i < neq; i++) {
      if (mdof[i] == 1) {
        rr[i] = bb[i] * dg[i];
      }
    }

    double rR = 0.0;
    double r0R0 = 0.0;
    double beta = 0.0;
    double alph = 0.0;
    int limit = neq;

    // --- (matrix) x (vector) ---CG法の反復計算
    for (int ie = 0; ie < nelx; ie++) {
      for (int io = 0; io < node; io++) {
        int ic = ijke[ie][io];
        for (int id = 0; id < nd; id++) {
          int ii = nd * io + id;
          int ig = nd * ic + id;
          double di = dg[ig];
          if (mdof[ig] >= 1) {
            for (int ko = 0; ko < node; ko++) {
              int kc = ijke[ie][ko];
              for (int kd = 0; kd < nd; kd++) {
                int kk = nd * ko + kd;
                int kg = nd * kc + kd;
                double dk = dg[kg];
                ap[ig] += di * dk * vske[ii][kk][ie] * xx[kg];
              }
            }
          }
        }
      }
    }

    // Residual norm
    for (int i = 0; i < neq; i++) {
      rr[i] -= ap[i];
      pp[i] = rr[i];
      ap[i] = 0.0;
    }
    r0R0 = rr.reduce((a, b) => a + b * b);

    if (sqrt(r0R0) < ctol) return (xx,);

    // CG法の反復処理
    while (true) {
      // (matrix) x (vector)　
      for (int ie = 0; ie < nelx; ie++) {
        for (int io = 0; io < node; io++) {
          int ic = ijke[ie][io];
          for (int id = 0; id < nd; id++) {
            int ii = nd * io + id;
            int ig = nd * ic + id;
            double di = dg[ig];
            if (mdof[ig] >= 1) {
              for (int ko = 0; ko < node; ko++) {
                int kc = ijke[ie][ko];
                for (int kd = 0; kd < nd; kd++) {
                  int kk = nd * ko + kd;
                  int kg = nd * kc + kd;
                  double dk = dg[kg];
                  ap[ig] += di * dk * vske[ii][kk][ie] * pp[kg];
                }
              }
            }
          }
        }
      }

      // Dot product
      double apP = 0.0;
      for (int i = 0; i < neq; i++) {
        apP += ap[i] * pp[i];
      }
      rR = rr.reduce((a, b) => a + b * b);
      alph = rR / apP;

      // Update
      for (int i = 0; i < neq; i++) {
        xx[i] += alph * pp[i];
        rr[i] -= alph * ap[i];
        ap[i] = 0.0;
      }
      double r1R1 = rr.reduce((a, b) => a + b * b);

      // Output to check
      kcg++;
      onDebug('kcg: $kcg, Residual: ${sqrt(rR / r0R0)}');

      // Convergence check
      if (sqrt(rR / r0R0) < ctol) {
        for (int i = 0; i < neq; i++) {
          xx[i] *= dg[i];
        }
        break;
      } else if (kcg > limit) {
        onDebug('ERROR: Iteration limit exceeded in ebecgm');
        break;
      } else {
        beta = r1R1 / rR;
        for (int i = 0; i < neq; i++) {
          pp[i] = rr[i] + beta * pp[i];
        }
      }

      rR = r1R1;
    }

    // Output results
    onDebug('-----------------------------------------------');
    onDebug('(*) Iteration of CGM: $kcg / $limit');
    onDebug('(*) Residual of CGM: ${sqrt(rR / r0R0)} / $ctol');
    onDebug('-----------------------------------------------');

    return (xx,);
  }

  (List<List<double>> stn, List<List<double>> sts) postpr(List<double> disp) {
    List<List<double>> stn = List.generate(10, (_) => List<double>.filled(nelx, 0.0));
    List<List<double>> sts = List.generate(10, (_) => List<double>.filled(nelx, 0.0));

    // Temporary arrays
    List<List<double>> xe = List.generate(8, (i) => List.filled(3, 0.0));
    List<double> ue = List.filled(24, 0.0);
    List<double> ev = List.filled(8, 0.0);
    List<double> sv = List.filled(8, 0.0);

    energy = 0.0;
    for (int ielm = 0; ielm < nelx; ielm++) {
      int imat = ijke[ielm][node];
      // Element coordinate
      for (int i = 0; i < node; i++) {
        xe[i] = xyzn[ijke[ielm][i]];
      }
      // Element displacement
      for (int ind = 0; ind < node; ind++) {
        int icnc = ijke[ielm][ind];
        for (int idf = 0; idf < nd; idf++) {
          int iee = nd * ind + idf;
          int igg = nd * icnc + idf;
          ue[iee] = disp[igg];
        }
      }
      // C-Matrix
      double yng = pmat[imat][0];
      double poi = pmat[imat][1];
      // double vlm = poi * yng / ((1.0 + poi) * (1.0 - 2.0 * poi));
      final resultCmatrx = cmatrx(yng, poi);
      List<List<double>> ccc = resultCmatrx.$1;
      // B-Matrix
      final resultCstnbm = cstnbm(xe, 0.0, 0.0, 0.0);
      // double vol = resultCstnbm.$1;
      List<List<double>> bbb = resultCstnbm.$3;

      // Strain vector ひずみ計算
      ev.fillRange(0, ev.length, 0.0);
      for (int i = 0; i < 3; i++) {
        for (int k = 0; k < 8; k++) {
          ev[i] += bbb[i][k] * ue[k];
        }
      }
      // Stress vector 応力計算
      sv.fillRange(0, sv.length, 0.0);
      for (int i = 0; i < 3; i++) {
        for (int k = 0; k < 3; k++) {
          sv[i] += ccc[i][k] * ev[k];
        }
      }

      for (int i = 0; i < 3; i++) {
        stn[i][ielm] = ev[i];
        sts[i][ielm] = sv[i];
      }
    }

    return(stn, sts);
  }

  (double von, double sp1, double sp2, double sp3) vonps2(double sv1, double sv2, double sv3, double sv4) {
    double von = 0.0;
    double sp1 = 0.0;
    double sp2 = 0.0;
    double sp3 = 0.0;

    // Mean stress
    double smean = (sv1 + sv2 + sv3) / 3.0;

    // Deviatoric stress
    double s11 = sv1 - smean;
    double s22 = sv2 - smean;
    double s33 = sv4 - smean;
    double s12 = sv3;
    double s21 = sv3;

    // von-Mises stress
    von = sqrt(1.5 * (s11 * s11 + s12 * s12 + s21 * s21 + s22 * s22 + s33 * s33));

    // Morl's circle
    double s1 = 0.5 * (sv1 + sv2);
    double s2 = 0.5 * (sv1 - sv2);
    double s3 = sqrt(s2 * s2 + sv3 * sv3);

    // Principal stress
    sp1 = s1 + s3;
    sp2 = s1 - s3;
    sp3 = 0.0;

    return (von, sp1, sp2, sp3);
  }

  (List<double> disp, List<List<double>> stn, List<List<double>> sts) run() {
    // nd = 2;
    // node = 4;
    // nbcm = 3;
    // nsk = 8;

    onDebug(
        " ______________________________________________ \n"
        "                                                \n"
        "                                                \n"
        "          Welcome to \"LCST2D\" ver.X  !!         \n"
        "                                                \n"
        " ______________________________________________ \n"
    );

    // readcml();

    onDebug('*) Total nodes     : $nx');
    onDebug('*) Total elements  : $nelx');
    onDebug('*) Total materials : $nmat');
    onDebug('*) Total disp. BCs : $nspc');
    onDebug('*) Total load. BCs : $npld');
    onDebug('*) Total DOFs      : $neq');

    onDebug('1) Plane stress');
    onDebug('2) Plane strain    :');
    idcmat = 1;
    onDebug(idcmat.toString());

    onDebug('+++++ assemb +++++');
    final resultAssemb = assemb();
    List<int> mdof = resultAssemb.$1;
    List<double> fext = resultAssemb.$2;
    List<double> disp = resultAssemb.$3;
    List<List<List<double>>> vske = resultAssemb.$4;

    onDebug('+++++ ebecgm +++++');
    final resultEbecgm = ebecgm(mdof, vske, disp, fext);
    disp = resultEbecgm.$1;

    onDebug('+++++ postpr +++++');
    final resultPostpr = postpr(disp);
    List<List<double>> stn = resultPostpr.$1;
    List<List<double>> sts = resultPostpr.$2;

    onDebug('Program "LCST2D" was finished successfully !!');

    return (disp, stn, sts);
  }
}
