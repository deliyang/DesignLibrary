#' Create a two arm design with blocks and clusters
#'
#' This designer builds a design with blocks and clusters. Normal shocks can be specified at the 
#' individual, cluster, and block levels. If individual level shocks are not specified and cluster and block 
#' level variances sum to less than 1, then individual level shocks are set such that total variance in outcomes equals 1. 
#' Treatment effects can be specified either by providing \code{control_mean} and \code{treatment_mean}
#' or by specifying an \code{ate}.
#' 
#' Key limitations: The designer assumes constant treatment effects 
#' and no covariance between potential outcomes.
#' 
#' Note: Default arguments produce a design without blocks and clusters and
#' with N determined by \code{N_cluster_in_block}. Units are assigned to treatment using complete block cluster random assignment. 
#' Analysis uses differences in means accounting for blocks and clusters. 
#'
#' @param N_blocks Number of blocks, defaults to 1.
#' @param N_clusters_in_block Number of clusters in each block.
#' @param N_i_in_cluster Individuals per cluster: defaults to 1.
#' @param sd_block Standard deviation of block level shocks.
#' @param sd_cluster Standard deviation of cluster level shock.
#' @param sd_i_0 Standard deviation of individual level shock in control.
#' @param sd_i_1 Standard deviation of individual level shock in treatment.
#' @param prob Treatment assignment probability.
#' @param control_mean Average outcome in control.
#' @param ate  Average treatment effect.
#' @param treatment_mean Average outcome in treatment.
#' @param rho Correlation in individual shock to Y(1) and Y(0)
#' @return A function that returns a design.
#' @author \href{https://declaredesign.org/}{DeclareDesign Team}
#' @concept experiment 
#' @concept blocking
#' @export
#' @examples
#' # To make a design using default arguments:
#' block_cluster_two_arm_design <- block_cluster_two_arm_designer()
#' 
#'


block_cluster_two_arm_designer <- function(N_blocks = 1,
                                           N_clusters_in_block = 100,
                                           N_i_in_cluster = 1,
                                           sd_block = .2,
                                           sd_cluster = .2,
                                           sd_i_0 = sqrt(max(0, 1 - sd_block^2 - sd_cluster^2)),
                                           sd_i_1 = sd_i_0,
                                           prob = .5,
                                           control_mean = 0,
                                           ate = 1,
                                           treatment_mean = control_mean + ate,
                                           rho = 1){  
  
  if(sd_block<0) stop("sd_block must be non-negative")
  if(sd_cluster<0) stop("sd_cluster must be non-negative")
  if(sd_i_0<0) stop("sd_i_0 must be non-negative")
  if(sd_i_1<0) stop("sd_i_1 must be non-negative")
  if(prob<0 | prob>1) stop("prob must be in [0,1]")
  {{{
    # M: Model
    population <- declare_population(
      blocks   = add_level(
        N = N_blocks,
        u_b = rnorm(N) * sd_block),
      clusters = add_level(
        N = N_clusters_in_block,
        u_c = rnorm(N) * sd_cluster,
        cluster_size = N_i_in_cluster),
      i = add_level(
        N   = N_i_in_cluster,
        u_0 = rnorm(N),
        u_1 = rnorm(n = N, mean = rho * u_0, sd = sqrt(1 - rho^2)))
      )
    
    pos <- declare_potential_outcomes(
      Y ~ (1 - Z) * (control_mean    + u_0*sd_i_0 + u_b + u_c) + 
          Z *       (treatment_mean  + u_1*sd_i_1 + u_b + u_c) )
    
    # I: Inquiry
    estimand <- declare_estimand(ATE = mean(Y_Z_1 - Y_Z_0))
    
    # D: Data
    assignment <- declare_assignment(prob = prob,
                                     blocks = blocks,
                                     clusters = clusters)
    
    # A: Analysis
    est <- declare_estimator(
      Y ~ Z,
      estimand = estimand,
      model = difference_in_means,
      blocks = blocks,
      clusters = clusters
    )
    
    # Design
    block_cluster_two_arm_design <-  population + pos + estimand + assignment + 
      declare_reveal() + est
  }}}
  
  attr(block_cluster_two_arm_design, "code") <- 
    construct_design_code(block_cluster_two_arm_designer, match.call.defaults())
  
  block_cluster_two_arm_design
  
}

attr(block_cluster_two_arm_designer, "shiny_arguments") <-
  list(
    N_blocks = c(10, 20, 50),
    N_clusters_in_block = c(2, 4),
    N_i_in_cluster = c(1, 5, 10),
    ate = c(0, .1, .3)
  )

attr(block_cluster_two_arm_designer, "tips") <-
  list(
    N_blocks = "Number of blocks",
    N_clusters_in_block = "Number of clusters in each block",
    N_i_in_cluster = "Number of units in each cluster",
    ate = "The average treatment effect"
  )
attr(block_cluster_two_arm_designer, "description") <- "
<p> A two blocked and clustered experiment <code>N_blocks</code> blocks, 
each containing <code>N_clusters_in_block</code> clusters. Each cluster in turn contains 
<code>N_i_in_cluster</code> individual units. 
<p> Estimand is the <code>ate</code> average interaction effect.
"


