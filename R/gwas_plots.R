generate_gwas_per_phenotype <- function(genename, pheno_label, filedate) {

  #### Prepare GWAS datasets ----

  # Stop if no matching file is found
  filename <- list.files(path=file.path("tables", genename),
                         pattern = paste0(paste(genename, pheno_label, filedate, sep = "_"), ".*", "glm"),
                         full.names = TRUE)
  stopifnot("filename must be unique" = length(filename) ==1)

  gwas_data <- readr::read_delim(filename,
                                delim = "\t",
                                show_col_types = FALSE) |>
    dplyr::rename(CHR="#CHROM") |>
    dplyr::mutate(SNP=paste0("rs", dplyr::row_number()))

  #### Generate Manhattan plot ----
  manhattan_plot_data <- gwas_data |>
    # Compute chromosome size
    dplyr::group_by(CHR) |>
    dplyr::summarise(chr_len=max(POS)) |>
    # Calculate cumulative position of each chromosome
    dplyr::mutate(tot=cumsum(chr_len)-chr_len)

  manhattan_plot_data <- gwas_data |>
    dplyr::left_join(manhattan_plot_data, by="CHR") |>
    # Add a cumulative position of each SNP
    dplyr::arrange(CHR, POS) |>
    dplyr::mutate( BPcum=POS+tot) |>
    # Add highlight and annotation information
    dplyr::mutate(is_annotate=dplyr::if_else(-log10(P)>2.5, "yes", "no"))

  ## Prepare x-axis special labelling
  axisdf <- manhattan_plot_data |>
    dplyr::group_by(CHR) |>
    dplyr::summarize(center=( max(BPcum) + min(BPcum) ) / 2 )

  manhattan_plot <- ggplot(manhattan_plot_data, aes(x=BPcum, y=-log10(P))) +
    # Show all points
    geom_point( aes(color=as.factor(CHR)), alpha=0.8, size=1.3) +
    scale_color_manual(values = rep(c("grey", "skyblue"), 22 )) +
    # custom X axis:
    scale_x_continuous( label = axisdf$CHR, breaks= axisdf$center ) +
    # Add label using ggrepel to avoid overlapping
    ggrepel::geom_label_repel(data=subset(manhattan_plot_data, is_annotate=="yes"),
                              aes(label=ID), size=1) +
    labs(x="Chromosome", y=expression(-log[10](p)))+
    # minimalist theme
    theme_bw() +
    theme(
      legend.position="none",
      panel.border = element_blank(),
      panel.grid = element_blank())

  #### Generate qqplot, assuming Uniform distribution ----

  # define distribution: under H0, assume Unif[0,1]
  params_unif <- list(min = 0, max = 1)

  # visualise qqplots
  qqplot_pvalues <- ggplot(gwas_data, mapping = aes(sample = P)) +
    ggplot2::stat_qq(distribution = qunif, dparams = params_unif) +
    ggplot2::stat_qq_line(distribution = qunif, dparams = params_unif, colour="red", lwd=1) +
    # Minimalist them
    labs(x = "Theoretical Quantiles", y = "Sample Quantiles") +
    theme_bw() +
    theme(
      legend.position="none",
      panel.border = element_blank(),
      panel.grid = element_blank())

  #### Generate histogram of p-values ----
  histogram_pvalue <- ggplot(gwas_data) +
    geom_histogram(aes(x = P, y = after_stat(count / sum(count))),
                   breaks = seq(0, 1, 0.05),
                   color = "black",
                   fill = "grey") +
    scale_y_continuous(name = "Relative Frequency") +
    geom_hline(yintercept = 0.05, color = "red")+
    labs(title = "Distribution of P-values",
         x = "P-value")+
    # facet_wrap(vars(contrast)) +
    theme_bw()

  # Create bottom row layout (plot2 and plot3 side by side)
  bottom_row <- cowplot::plot_grid(qqplot_pvalues,
                                   histogram_pvalue,
                                   labels = c("b", "c"))

  # Combine top and bottom row
  combined_plot <- cowplot::plot_grid(manhattan_plot, bottom_row,
                                      ncol = 1,
                                      labels = c("a", ""), label_size = 10)

  # Add title using ggdraw and draw_label
  title_content <- paste("GWAS visualisations for Gene:", genename, "\n",
                         "with response variable:", pheno_label, "\n",
                         "and Date:", filedate)
  title_plot <- cowplot::ggdraw() +
    cowplot::draw_label(title_content,
                        fontface = "bold", x = 0.2, hjust = 0, size=16)

  gwas_plot_per_pheno <- cowplot::plot_grid(title_plot, combined_plot,
                                            ncol = 1,rel_heights = c(0.2, 1))

  return(gwas_plot_per_pheno)
}

