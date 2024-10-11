import 'dart:math';

// FEM3角形要素
class Lcst2ebe {
  Lcst2ebe({required this.onDebug});
  final Function(String value) onDebug;

  // Parameters with default initialization
  int idcmat = 0; // plane stress or strain
  int nd = 0;     // 2-D or 3-D
  int node = 0;   // nodes per element
  int nbcm = 0;   // size of C-matrix
  int nsk = 0;    // size of element stiffness

  int nx = 0;     // total nodes
  int nelx = 0;   // total elements
  int nmat = 0;   // total materials

  int nspc = 0;   // total displacements
  int npld = 0;   // total point loads

  int neq = 0;    // total DOFs

  double energy = 0.0; // strain energy

  // Allocatable arrays
  late List<List<int>> ijke;
  late List<List<int>> mspc;
  late List<int> mpld;

  late List<List<double>> xyzn;
  late List<List<double>> pmat;
  late List<List<double>> vspc;
  late List<List<double>> vpld;

  (List<int> mdof, List<double> fext, List<double> disp, List<List<List<double>>> vske) assemb() {
    List<int> mdof = List<int>.filled(neq, 0);
    List<double> fext = List<double>.filled(neq, 0.0);
    List<double> disp = List<double>.filled(neq, 0.0);
    List<List<List<double>>> vske = List.generate(nsk, (_) => List.generate(nsk, (_) => List<double>.filled(nelx, 0.0)));

    // Initialize
    for (int i = 0; i < nelx; i++) {
      for (int j = 0; j < nsk; j++) {
        for (int k = 0; k < nsk; k++) {
          vske[j][k][i] = 0.0;
        }
      }
    }

    // Stiffness and mass matrix
    for (int ielm = 0; ielm < nelx; ielm++) {
      int imat = ijke[ielm][node];
      List<List<double>> xe = List.generate(8, (_) => List.filled(3, 0.0));
      List<List<double>> ske = List.generate(24, (_) => List.filled(24, 0.0));

      // Element coordinate ＝節点座標
      for (int i = 0; i < node; i++) {
        xe[i] = xyzn[ijke[ielm][i]];
      }

      // C-Matrix
      double yng = pmat[imat][0];
      double poi = pmat[imat][1];
      final resultCmatrx = cmatrx(yng, poi);
      List<List<double>> ccc = resultCmatrx.$1;

      // B-Matrix
      final resultCstnbm = cstnbm(xe, 0.0, 0.0, 0.0);
      double vol = resultCstnbm.$1;
      // List<List<double>> shm = resultCstnbm.$2;
      List<List<double>> bbb = resultCstnbm.$3;

      // Element stiffness 要素合成行列
      for (int i = 0; i < nd * node; i++) {
        for (int j = 0; j < nd * node; j++) {
          for (int k = 0; k < nbcm; k++) {
            for (int l = 0; l < nbcm; l++) {
              ske[i][j] += bbb[k][i] * ccc[k][l] * bbb[l][j] * vol;
            }
          }
        }
      }

      // for(int i = 0; i < nsk; i++){
      //   onDebug(ske[i].toString());
      // }

      // Store the stiffness　全体剛性行列に関するもの
      for (int i = 0; i < nd * node; i++) {
        for (int j = 0; j < nd * node; j++) {
          vske[i][j][ielm] = ske[i][j];
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
    // double vkp = yng / (3.0 * (1.0 - 2.0 * poi));

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
    double vol = 0.0;
    List<List<double>> shm = List.generate(3, (_) => List.filled(24, 0.0));
    List<List<double>> bbb = List.generate(6, (_) => List.filled(24, 0.0));

    // Initialize array
    for (int i = 0; i < shm.length; i++) {
      for (int j = 0; j < shm[i].length; j++) {
        shm[i][j] = 0.0;
      }
    }
    for (int i = 0; i < bbb.length; i++) {
      for (int j = 0; j < bbb[i].length; j++) {
        bbb[i][j] = 0.0;
      }
    }

    // Coordinate
    double x1 = xe[0][0];
    double y1 = xe[0][1];
    double x2 = xe[1][0];
    double y2 = xe[1][1];
    double x3 = xe[2][0];
    double y3 = xe[2][1];

    // Area of element
    vol = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2);
    vol /= 2.0;
    if (vol <= 0.0) {
      throw Exception('<<===== VOLUME ERROR !!');
    }

    // Parameter for shape-function
    double a1 = (x2 * y3 - x3 * y2) / (2.0 * vol);
    double a2 = (x3 * y1 - x1 * y3) / (2.0 * vol);
    double a3 = (x1 * y2 - x2 * y1) / (2.0 * vol);
    double b1 = (y2 - y3) / (2.0 * vol);
    double b2 = (y3 - y1) / (2.0 * vol);
    double b3 = (y1 - y2) / (2.0 * vol);
    double c1 = (x3 - x2) / (2.0 * vol);
    double c2 = (x1 - x3) / (2.0 * vol);
    double c3 = (x2 - x1) / (2.0 * vol);

    // Shape-function matrix
    shm[0][0] = a1 + b1 * xxx + c1 * yyy;
    shm[1][1] = a1 + b1 * xxx + c1 * yyy;
    shm[0][2] = a2 + b2 * xxx + c2 * yyy;
    shm[1][3] = a2 + b2 * xxx + c2 * yyy;
    shm[0][4] = a3 + b3 * xxx + c3 * yyy;
    shm[1][5] = a3 + b3 * xxx + c3 * yyy;

    // B-Matrix
    bbb[0][0] = b1;
    bbb[0][2] = b2;
    bbb[0][4] = b3;
    bbb[1][1] = c1;
    bbb[1][3] = c2;
    bbb[1][5] = c3;
    bbb[2][0] = bbb[1][1];
    bbb[2][1] = bbb[0][0];
    bbb[2][2] = bbb[1][3];
    bbb[2][3] = bbb[0][2];
    bbb[2][4] = bbb[1][5];
    bbb[2][5] = bbb[0][4];

    return (vol, shm, bbb);
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
    List<double> ev = List.filled(6, 0.0);
    List<double> sv = List.filled(6, 0.0);

    energy = 0.0;
    for (int ielm = 0; ielm < nelx; ielm++) {
      int imat = ijke[ielm][node];
      // Element coordinate
      for (int i = 0; i < node; i++) {
        for (int j = 0; j < 3; j++) {
          xe[i][j] = xyzn[ijke[ielm][i]][j];
        }
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
      double vlm = poi * yng / ((1.0 + poi) * (1.0 - 2.0 * poi));
      final resultCmatrx = cmatrx(yng, poi);
      List<List<double>> ccc = resultCmatrx.$1;
      // B-Matrix
      final resultCstnbm = cstnbm(xe, 0.0, 0.0, 0.0);
      double vol = resultCstnbm.$1;
      // List<List<double>> shm = resultCstnbm.$2;
      List<List<double>> bbb = resultCstnbm.$3;

      // Strain vector ひずみ計算
      ev.fillRange(0, ev.length, 0.0);
      for (int i = 0; i < nbcm; i++) {
        for (int k = 0; k < nd * node; k++) {
          ev[i] += bbb[i][k] * ue[k];
        }
      }
      // Stress vector 応力計算
      sv.fillRange(0, sv.length, 0.0);
      for (int i = 0; i < nbcm; i++) {
        for (int k = 0; k < nbcm; k++) {
          sv[i] += ccc[i][k] * ev[k];
        }
      }

      // Strain energy
      for (int i = 0; i < nbcm; i++) {
        energy += 0.5 * ev[i] * sv[i] * vol;
      }
      // Plane condition
      double ev4, sv4;
      if (idcmat == 1) {
        ev4 = -(poi / yng) * (sv[0] + sv[1]);
        sv4 = 0.0;
      } else {
        ev4 = 0.0;
        sv4 = vlm * (ev[0] + ev[1]);
      }
      // Save the stress and strain
      for (int i = 0; i < 3; i++) {
        stn[i][ielm] = ev[i];
        sts[i][ielm] = sv[i];
      }
      stn[3][ielm] = ev4;
      sts[3][ielm] = sv4;

      // von-Mises and principal stress
      double sv1 = sts[0][ielm];
      double sv2 = sts[1][ielm];
      double sv3 = sts[2][ielm];
      sv4 = sts[3][ielm];

      final resultVonps2 = vonps2(sv1, sv2, sv3, sv4);
      sts[6][ielm] = resultVonps2.$1;
      sts[7][ielm] = resultVonps2.$2;
      sts[8][ielm] = resultVonps2.$3;
      sts[9][ielm] = resultVonps2.$4;
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
    // node = 3;
    // nbcm = 3;
    // nsk = 6;

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

    // onDebug('+++++ outcml +++++');
    // outcml(disp, stn, sts);

    onDebug('Program "LCST2D" was finished successfully !!');

    return (disp, stn, sts);
  }
}
