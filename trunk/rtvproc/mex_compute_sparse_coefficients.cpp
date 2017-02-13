/*********************************************
 * Mixed L1/L2 norm sparse coefficients solver
 *
 * Usage:
 * alpha = mex_compute_sparse_coefficients(D,X,[lambda1 lambda2]);
 *********************************************/
#include "mex.h"
#include <algorithm>
#include <vector>
#include <math.h>
#include <string>
#include <string.h>
#include <iostream>
#include <Eigen/Dense>
using namespace Eigen;

using std::max;
using std::vector;
using std::string;

template<class T> inline T& access2DMatrix(T* M, const int& i, const int& j, const int& rows, const int& cols)
{
    return M[i+(j*rows)];
}
template<class T> inline const T& access2DMatrix(const T* M, int i, int j, const int& rows, const int& cols)
{
    return M[i+(j*rows)];
}
template<class T> inline T mymax(const T& a,const T& b)
{
    if (a>=b) return a;
    else return b;
}

template<class T> inline T myabs(const T& a)
{
    if (a>=0) return a;
    else return -a;
}
template<class T> inline T mysign(const T& a)
{
    if (a>=0) return T(1);
    else return T(-1);
}
template<class T> inline T sqr(const T& a)
{
    return a*a;
}
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    if (nrhs<3) {
        mexErrMsgTxt("Wrong number of input arguments");
    }
    if (nlhs<1) {
        mexErrMsgTxt("Wrong number of output arguments");
    }
    
    // Load matlab variables into Eigen, etc
    float* dictionary = (float*) mxGetPr(prhs[0]);
    float* signal = (float*) mxGetPr(prhs[1]);
    unsigned int num_atoms=mxGetDimensions(prhs[0])[1];
    unsigned int signal_dim=mxGetDimensions(prhs[0])[0];
    unsigned int num_signals=mxGetDimensions(prhs[1])[1];
    unsigned int num_iters=100;
    float lambda1=((float*)mxGetPr(prhs[2]))[0];
    float lambda2=((float*)mxGetPr(prhs[2]))[1];
    plhs[0]=mxCreateNumericMatrix(num_atoms, num_signals, mxSINGLE_CLASS, mxREAL);
    float* coeffs = (float*) mxGetPr(plhs[0]);
    MatrixXf D(signal_dim,num_atoms);
    // Load dictionary
   for (unsigned int d=0;d<signal_dim;++d){
   for (unsigned int i=0;i<num_atoms;++i){
       D(d,i)=access2DMatrix(dictionary,d,i,signal_dim,num_atoms);
   }
   }
    
    // Compute sparse coefficients
    for (unsigned int s=0;s<num_signals;++s){
       VectorXf a(num_atoms);
       
       VectorXf x(signal_dim);
       for (unsigned int d=0;d<signal_dim;++d){
           x[d]=access2DMatrix(signal,d,s,signal_dim,num_signals);
       }
       VectorXf rt(signal_dim);
       VectorXf rt2(signal_dim);
        a.setZero(num_atoms);
        float w=1.6f;// SOR
       for (unsigned int iter=0;iter<num_iters;++iter){
           rt=x-D*a;
           for (unsigned int at=0;at<num_atoms;++at){
               rt2=rt+D.col(at)*a(at);
           float ip_rt=(D.col(at)).dot(rt2);
           float na=(mysign(ip_rt)*mymax(myabs(ip_rt)-lambda1,0.f))/(lambda2+(D.col(at)).dot(D.col(at)));
           float na2=a(at)*(1.f-w)+w*na;
           rt=rt-(D.col(at)*(na2-a(at)));
           a(at)=na2;
           }
       }
        
    // Copy eigen vector into matlab result
       for (unsigned int i=0;i<num_atoms;++i){
           access2DMatrix(coeffs,i,s,num_atoms,num_signals)=a[i];
       }
    }
}

