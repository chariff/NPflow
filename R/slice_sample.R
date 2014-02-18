slice_sample <- function(c, m, alpha, z, hyperG0, U_mu, U_Sigma){
    
    maxCl <- length(m) #maximum number of clusters
    ind <- unique(c) # non empty clusters
    fullCl <- which(m!=0) # indexes of non empty clusters
    
    # Sample the weights, i.e. the frequency of each existing cluster from a Dirichlet:
    # temp_1 ~ Gamma(m_1,1), ... , temp_K ~ Gamma(m_K,1)    # and sample the rest of the weigth for potential new clusters:
    # temp_{K+1} ~ Gamma(alpha, 1)
    # then renormalise temp
    w <- numeric(maxCl)
    temp <- rgamma(n=(length(ind)+1), shape=c(m[ind], alpha), scale = 1)
    temp_norm <- temp/sum(temp)
    w[ind] <- temp_norm[-length(temp_norm)]
    R <- temp_norm[length(temp_norm)] 
    #R is the rest, i.e. the weight for potential new clusters
    
    
    # Sample the latent u
    u  <- runif(maxCl)*w[c]
    u_star <- min(u)
    
    # Sample the remaining weights that are needed with stick-breaking
    # i.e. the new clusters
    ind_new <- which(m==0) # potential new clusters
    if(length(ind_new)>0){
        t <- 0 # the number of new non empty clusters
        while(R>u_star && (t<length(ind_new))){ 
            # sum(w)<1-min(u) <=> R>min(u) car R=1-sum(w)
            t <- t+1
            beta_temp <- rbeta(n=1, shape1=1, shape2=alpha)
            # weight of the new cluster
            w[ind_new[t]] <- R*beta_temp
            R <- R * (1-beta_temp) # remaining weight
        }
        ind_new <- ind_new[1:t]
        
        # Sample the centers and spread of each new cluster from prior
        for (i in 1:t){
            NiW <- normalinvwishrnd(hyperG0)
            U_mu[, ind_new[i]] <- NiW[["mu"]]
            U_Sigma[, , ind_new[i]] <- NiW[["S"]]
        }
    }
    fullCl <- fullCl + t
    fullCl_ind <- which(w != 0)
    # calcul de la vraisemblance pour chaque données pour chaque clusters
    # assignation de chaque données à 1 cluster
    l <- numeric(length(fullCl)) # likelihood of belonging to each cluster 
    m_new <- numeric(maxCl) # number of observations in each cluster
    
    for(i in 1:maxCl){
        for (j in fullCl_ind){
            l[j] <- mvnpdf(x = matrix(z[,i], nrow= 1, ncol=length(z[,i])) , 
                           mean = U_mu[, j], 
                           varcovM = U_Sigma[, , j])*w[j]  
        }
        c[i] <- which.max(l)
        m_new[c[i]] <- m_new[c[i]] + 1
    }
    
    return(list("c"=c, "m"=m_new, "U_mu"=U_mu, "U_Sigma"=U_Sigma, "weights"=w))
}