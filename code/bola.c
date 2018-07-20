#include <iostream>
#include <fstream>
#include <cmath>
using namespace std;

const int j=200;

class array{
  public:
	 double x, y;
	 array(){}
};
int main(){
  char   ch;
  int    i, m;
  double var1, var2, s1, s2, s3, s4, sumy, sumxy, sumx2y,
         det, p0, p1, p2, sumr2, ycalc, r, sigma;
  array  *a[j];

  fstream source("reflect.Si", ios::in);
  source >> ch >> ch;
  for(m=0; source >> var1 >> var2; m=m+1){
	 a[m] = new array;
	 a[m]->x = var1;
	 a[m]->y = var2;
  }
  source.close();

  s1     =0;
  s2     =0;
  s3     =0;
  s4     =0;
  sumy   =0;
  sumxy  =0;
  sumx2y =0;

  for(i=0; i<m; i=i+1){
    s1     =s1     + a[i]->x;
    s2     =s2     + pow(a[i]->x,2);
    s3     =s3     + pow(a[i]->x,3);
    s4     =s4     + pow(a[i]->x,4);
    sumy   =sumy   + a[i]->y;
    sumxy  =sumxy  + a[i]->x*a[i]->y;
    sumx2y =sumx2y + a[i]->x*a[i]->x*a[i]->y;
  }
  det=m*(s2*s4-s3*s3)+s1*(s2*s3-s1*s4)+s2*(s1*s3-s2*s2);
  p0 =((s2*s4-s3*s3)*sumy+(s2*s3-s1*s4)*sumxy+(s1*s3-s2*s2)*sumx2y)/det;
  p1 =((s2*s3-s1*s4)*sumy+( m*s4-s2*s2)*sumxy+(s1*s2- m*s3)*sumx2y)/det;
  p2 =((s1*s3-s2*s2)*sumy+(s1*s2- m*s3)*sumxy+( m*s2-s1*s1)*sumx2y)/det;

  sumr2=0;
  for(i=0; i<m; i=i+1){
    ycalc=p0+p1*a[i]->x+p2*a[i]->x*a[i]->x;
    r=a[i]->y-ycalc;
    sumr2=sumr2+r*r;
  }
  sigma=sqrt(sumr2/(m-2));

  ofstream sink("parameter.Si", ios::out);
  cout << " Parameters stored in 'parameter.Si' file: "
       << m  << " data points counted!!!\n";
  sink << "p0    = " << p0    << endl
		 << "p1    = " << p1    << endl
       << "p2    = " << p2    << endl
       << "sigma = " << sigma << endl;
  sink.close();

  return 0;
}
