% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{mmvstpdfC}
\alias{mmvstpdfC}
\title{C++ implementation of multivariate Normal probability density function for multiple inputs}
\usage{
mmvstpdfC(x, xi, psi, sigma, df, Log = TRUE)
}
\arguments{
\item{x}{data matrix of dimension p x n, p being the dimension of the 
data and n the number of data points}

\item{xi}{mean vectors matrix of dimension p x K, K being the number of 
distributions for which the density probability has to be ealuated}

\item{psi}{skew parameter vectors matrix of dimension p x K, K being the number of 
distributions for which the density probability has to be ealuated}

\item{df}{vector of length K of degree of freedom parameters}

\item{varcovM}{list of length K of variance-covariance matrices, 
each of dimensions p x p}

\item{logical}{flag for returning the log of the probability density 
function. Defaults is \code{TRUE}.}
}
\value{
matrix of densities of dimension K x n
}
\description{
C++ implementation of multivariate Normal probability density function for multiple inputs
}
\examples{

mmvstpdfC(x = matrix(c(3.399890,-5.936962), ncol=1), xi=matrix(c(0.2528859,-2.4234067), ncol=1), 
psi=matrix(c(11.20536,-12.51052), ncol=1), 
sigma=list(matrix(c(0.2134011, -0.2382573, -0.2382573, 0.2660086), ncol=2)), 
df=c(7.784106)
)
mvstpdf(x = matrix(c(3.399890,-5.936962), ncol=1), xi=matrix(c(0.2528859,-2.4234067), ncol=1), 
psi=matrix(c(11.20536,-12.51052), ncol=1), 
sigma=list(matrix(c(0.2134011, -0.2382573, -0.2382573, 0.2660086), ncol=2)), 
df=c(7.784106)
)

#skew-normal limit
mmvsnpdfC(x=matrix(rep(1.96,2), nrow=2, ncol=1), 
         xi=matrix(c(0, 0)), psi=matrix(c(1, 1),ncol=1), sigma=list(diag(2))
         )
mvstpdf(x=matrix(rep(1.96,2), nrow=2, ncol=1),
       xi=c(0, 0), psi=c(1, 1), sigma=diag(2),
       df=100000000
       )
mmvstpdfC(x=matrix(rep(1.96,2), nrow=2, ncol=1), 
         xi=matrix(c(0, 0)), psi=matrix(c(1, 1),ncol=1), sigma=list(diag(2)),
         df=100000000
         )
         
#non-skewed limit         
mmvtpdfC(x=matrix(rep(1.96,2), nrow=2, ncol=1),
        mean=matrix(c(0, 0)), varcovM=list(diag(2)),
        df=10
        )
mmvstpdfC(x=matrix(rep(1.96,2), nrow=2, ncol=1), 
         xi=matrix(c(0, 0)), psi=matrix(c(0, 0),ncol=1), sigma=list(diag(2)),
         df=10
         )

library(microbenchmark)
microbenchmark(mvstpdf(x=matrix(rep(1.96,2), nrow=2, ncol=1), 
                      xi=c(0, 0), psi=c(1, 1), 
                      sigma=diag(2), df=10),
              mmvstpdfC(x=matrix(rep(1.96,2), nrow=2, ncol=1),
                        xi=matrix(c(0, 0)), psi=matrix(c(1, 1),ncol=1), 
                        sigma=list(diag(2)), df=10),
              times=10000L)

}

