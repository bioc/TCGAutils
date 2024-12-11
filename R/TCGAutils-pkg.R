#' TCGAutils: Helper functions for working with TCGA and MultiAssayExperiment
#' data
#'
#' TCGAutils is a toolbox to work with TCGA specific datasets. It allows the
#' user to manipulate and translate TCGA barcodes, conveniently convert a list
#' of data files to [GRangesList][GenomicRanges::GRangesList-class]. Take
#' datasets from GISTIC and return a
#' [SummarizedExperiment][SummarizedExperiment::SummarizedExperiment-class]
#' class object. The package also provides functions for working with data from
#' the `curatedTCGAData`
#' experiment data package. It provides convenience functions for extracting
#' subtype metadata data and adding clinical data to existing
#' [MultiAssayExperiment][MultiAssayExperiment::MultiAssayExperiment-class]
#' objects.
"_PACKAGE"
