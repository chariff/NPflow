#include <RcppArmadillo.h>
#include <omp.h>
// #define ARMA_64BIT_WORD // to enable matrix with more than 4 billions elements
// requires a 64bits machine
using namespace Rcpp;
using namespace arma;

// [[Rcpp::plugins(openmp)]]
// [[Rcpp::depends(RcppArmadillo)]]

//' Parallel C++ implementation of the F-measure computation
//' 
//'@param pred
//'@param ref
//'
//'@export
//'
//'@examples
//'c <- list(c(1,1,2,3,2,3), c(1,1,1,2,3,3),c(2,2,1,1,1,1))
//'similarityMatC(sapply(c, "["))
//'
//'c2 <- list()
//'for(i in 1:100){
//'     c2 <- c(c2, list(rmultinom(n=1, size=3000, prob=rexp(n=3000))))
//'}
//'library(microbenchmark)
//'f <- function(){c3 <-sapply(c2, "[")
//'             similarityMatC(c3)}
//'microbenchmark(f(), time=1L)
//'
// [[Rcpp::export]]
double FmeasureC_par(NumericVector pred, 
                     NumericVector ref,
                     int ncores=1){
    
    vec K = unique(pred);
    K = sort(K);
    vec C = unique(ref);
    C = sort(C);
    const int m = K.size();
    const int n = C.size();
    
    mat M = mat(n, m);
    mat Pr = mat(n, m);
    mat Re = mat(n, m);
    mat Fmat = mat(n, m);
    
    vec C_card = vec(n);
    vec K_card = vec(m);
    
    omp_set_num_threads(ncores);
    
    for(int i=0; i<n; i++){
        C_card(i) = sum(ref == C(i));
        #pragma omp parallel for shared(ref, pred, K, C)
        for(int j=0; j<m; j++){
            K_card(j) = sum(pred == K(j));
            M(i,j) = sum((ref==C(i)) & (pred==K(j)));
            Pr(i,j) = M(i,j)/K_card(j);
            Re(i,j) = M(i,j)/C_card(i);
            if((Pr(i,j) + Re(i,j)) == 0.0){
                Fmat(i,j) = 0;
            }else{
                Fmat(i,j) = 2.0*Pr(i,j)*Re(i,j)/(Pr(i,j) + Re(i,j));
            }
        }
    } 
    
    double C_card_sum = sum(C_card);
    vec Ffinal = vec(n);
    vec Fsum = vec(n);
    
    #pragma omp parallel for shared(Fmat, C_card, C_card_sum, Ffinal, Fsum)
    for(int i=0; i<n; i++){
        Ffinal(i) = max(Fmat.row(i));
        Fsum(i) = Ffinal(i)*C_card(i)/C_card_sum;
    }
    double Ftotal = sum(Fsum);
    
    return Ftotal;
}

//' Parallel C++ implementation of cost computation with Fmeasure as loss function
//' 
//'
//'@param c list of MCMC partitions
//'
//'@export
//'
//'@examples
//'c <- list(c(1,1,2,3,2,3), c(1,1,1,2,3,3),c(2,2,1,1,1,1))
//'Fmeasure_costC(sapply(c, "["))
//'
//'c2 <- list()
//'for(i in 1:500){
//'     c2 <- c(c2, list(rmultinom(n=1, size=10000, prob=rexp(n=10000))))
//'}
//'library(microbenchmark)
//'f <- function(){c3 <-sapply(c2, "[")
//'             Fmeasure_costC(c3)}
//'fa <- function(){c3 <-sapply(c2, "[")
//'             Fmeasure_costC_arma(c3)}
//'microbenchmark(f(), fa(), times=10L)
//'
// [[Rcpp::export]]
List Fmeasure_costC_par(NumericMatrix c,
                        int ncores=1){
    
    //mat cc = as<mat>(c);
    //double N = cc.n_cols;
    //double n = cc.n_rows;
    const int N = c.ncol();
    const int n = c.nrow();
    
    NumericVector cost = NumericVector(N);
    mat Fmeas = mat(N, N, fill::eye);
    
    for(int i=0; i<N-1; i++){
        for(int j=i+1; j<N; j++){
            NumericVector pred_i = c(_,i);
            NumericVector ref_j = c(_,j);
            Fmeas(i,j) = FmeasureC_par(pred_i, ref_j, ncores);
            Fmeas(j,i) = Fmeas(i,j);
        }
    }
    
    omp_set_num_threads(ncores);
    #pragma omp parallel for shared(Fmeas, cost)
    for(int k=0; k<N; k++){
        cost(k) = 1-(sum(Fmeas.col(k))-1)/N;
    }
    
    return Rcpp::List::create(Rcpp::Named("Fmeas") = Fmeas,
    Rcpp::Named("cost")=cost);
}

//' Parallel C++ implementation of cost computation with Fmeasure as loss function
//' using the Armadillo library
//' 
//'
//'@param c list of MCMC partitions
//'
//'@export
// [[Rcpp::export]]
List Fmeasure_costC_arma_par(NumericMatrix c,
                             int ncores=1){
    
    const mat cc = as<mat>(c);
    const int N = cc.n_cols;
    const int n = cc.n_rows;
    
    NumericVector cost = NumericVector(N);
    mat Fmeas = mat(N, N, fill::eye);
    
    for(int i=0; i<N-1; i++){
        for(int j=i+1; j<N; j++){
            vec pred_i_temp = cc.col(i);
            vec ref_j_temp = cc.col(j);
            NumericVector pred_i = as<NumericVector>(wrap(pred_i_temp));
            NumericVector ref_j = as<NumericVector>(wrap(ref_j_temp));
            Fmeas(i,j) = FmeasureC_par(pred_i, ref_j, ncores);
            Fmeas(j,i) = Fmeas(i,j);
        }
    }
    
    omp_set_num_threads(ncores);
    #pragma omp parallel for shared(Fmeas, cost)
    for(int k=0; k<N; k++){
        cost(k) = 1-(sum(Fmeas.col(k))-1)/N;
    }
    
    return Rcpp::List::create(Rcpp::Named("Fmeas") = Fmeas,
    Rcpp::Named("cost")=cost);
}
