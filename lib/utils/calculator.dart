import 'dart:math';
import 'dart:ui';

class Calculator{
  // ベクトルの加算
  List<double> addVectors(List<double> v1, List<double> v2) {
    return List.generate(v1.length, (i) => v1[i] + v2[i]);
  }

  // ベクトルの減算
  List<double> subtractVectors(List<double> v1, List<double> v2) {
    return List.generate(v1.length, (i) => v1[i] - v2[i]);
  }

  // ベクトルとスカラーの乗算
  List<double> multiplyVectorByScalar(List<double> v, double scalar) {
    return v.map((e) => e * scalar).toList();
  }

  // ベクトルのドット積
  double dotProduct(List<double> v1, List<double> v2) {
    return List.generate(v1.length, (i) => v1[i] * v2[i]).reduce((a, b) => a + b);
  }

  // 行列とベクトルの乗算
  List<double> multiplyMatrixByVector(List<List<double>> matrix, List<double> vector) {
    return matrix.map((row) => dotProduct(row, vector)).toList();
  }

  // CG法を実装する関数
  List<double> conjugateGradient(List<List<double>> A, List<double> b, int maxIterations, double tol) {
    int size = b.length;
    List<double> x = List.filled(size, 0.0);
    List<double> r = multiplyMatrixByVector(A, x);
    // 引き算b-r
    r = subtractVectors(b, r);
    List<double> p = List.from(r);
    // ignore: non_constant_identifier_names
    List<double> Ap;
    double alpha, beta, rDotR;

    for (int i = 0; i < maxIterations; i++) {
      Ap = multiplyMatrixByVector(A, p);
      rDotR = dotProduct(r, r);
      alpha = rDotR / dotProduct(p, Ap);
      x = addVectors(x, multiplyVectorByScalar(p, alpha));
      List<double> rNew = subtractVectors(r, multiplyVectorByScalar(Ap, alpha));

      if (dotProduct(rNew, rNew) < tol * tol) {
        return x; // 収束した場合
      }

      beta = dotProduct(rNew, rNew) / rDotR;
      p = addVectors(rNew, multiplyVectorByScalar(p, beta));
      r = rNew;
    }

    return x; // 最大反復回数に達した場合
  }

  // 逆行列
  List<List<double>> invertMatrix(List<List<double>> matrix) {
    int n = matrix.length;
    List<List<double>> inverse = List.generate(n, (i) => List.filled(n, 0.0));

    // 単位行列を作成
    for (int i = 0; i < n; i++) {
      inverse[i][i] = 1.0;
    }

    // 掃き出し法で逆行列を求める
    for (int i = 0; i < n; i++) {
      double pivot = matrix[i][i];
      if (pivot == 0) {
        // ピボットが0の場合、非ゼロのピボットを持つ行と交換
        bool swapped = false;
        for (int k = i + 1; k < n; k++) {
          if (matrix[k][i] != 0) {
            List<double> temp = matrix[i];
            matrix[i] = matrix[k];
            matrix[k] = temp;

            temp = inverse[i];
            inverse[i] = inverse[k];
            inverse[k] = temp;

            pivot = matrix[i][i];
            swapped = true;
            break;
          }
        }
        // 交換後もピボットが0の場合、逆行列は存在しない
        if (!swapped) {
          Exception('行列が逆行列を持たない');
        }
      }
      for (int j = 0; j < n; j++) {
        matrix[i][j] /= pivot;
        inverse[i][j] /= pivot;
      }
      for (int k = 0; k < n; k++) {
        if (k != i) {
          double factor = matrix[k][i];
          for (int j = 0; j < n; j++) {
            matrix[k][j] -= factor * matrix[i][j];
            inverse[k][j] -= factor * inverse[i][j];
          }
        }
      }
    }

    return inverse;
  }

}

// 3角形の面積
double areaOfTriangle(Offset a, Offset b, Offset c) {
  return (a.dx * (b.dy - c.dy) + b.dx * (c.dy - a.dy) + c.dx * (a.dy - b.dy)).abs() / 2.0;
}

// 線分ABと点Pの最短距離を求める関数
double distanceFromPointToSegment(Offset A, Offset B, Offset P) {
  // ベクトルAB
  double abx = B.dx - A.dx;
  double aby = B.dy - A.dy;
  // ベクトルAP
  double apx = P.dx - A.dx;
  double apy = P.dy - A.dy;
  // ベクトルABの長さの2乗
  double abSquared = abx * abx + aby * aby;
  if (abSquared == 0) {
    // AとBが同じ点の場合、APの長さを返す
    return sqrt(apx * apx + apy * apy);
  }
  // 点Pから線分ABへの垂線の足の位置tを求める
  double t = (apx * abx + apy * aby) / abSquared;
  if (t < 0.0) {
    // 垂線の足がAよりも外側にある場合、APの長さを返す
    return sqrt(apx * apx + apy * apy);
  } else if (t > 1.0) {
    // 垂線の足がBよりも外側にある場合、BPの長さを返す
    double bpx = P.dx - B.dx;
    double bpy = P.dy - B.dy;
    return sqrt(bpx * bpx + bpy * bpy);
  } else {
    // 垂線の足が線分AB上にある場合
    double closestPointX = A.dx + t * abx;
    double closestPointY = A.dy + t * aby;
    double distanceX = P.dx - closestPointX;
    double distanceY = P.dy - closestPointY;
    return sqrt(distanceX * distanceX + distanceY * distanceY);
  }
}