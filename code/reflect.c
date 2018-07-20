#include <iostream>
#include <fstream>
#include <cmath>
#include <complex>
using namespace std;

int main(){
  int     w,i;
  double  phi, T, Re, Im, R;
  complex<double> epsilon, a, b, r;

  phi=75*M_PI/180;

  cout << " Data stored in 'reflect.Si' file!!!\n";
  fstream sink("reflect.Si", ios::out);
  sink << "T\t";
  sink << "R\n";

  for(i=0; i<1010; i=i+10){
    T=double(i);

    Re=15+2.1e-3*T+1.5e-6*T*T;
    Im=.132*exp(2.5e-3*T);
    epsilon=complex<double>(Re,Im);

    a=epsilon*sqrt(1-sin(phi)*sin(phi));
    b=sqrt(epsilon-sin(phi)*sin(phi));

    r=(a-b)/(a+b);
    R=real(r*conj(r));

    sink << T << "\t";
    sink << R << endl;
  }
  sink.close();

  return 0;
}
