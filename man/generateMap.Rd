% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generateMap.R
\name{generateMap}
\alias{generateMap}
\title{Create a sampleMap from an experiment list and phenoData dataframe}
\usage{
generateMap(
  experiments,
  colData,
  idConverter = identity,
  sampleCol,
  patientCol,
  ...
)
}
\arguments{
\item{experiments}{A named \code{list} of experiments compatible with the
\code{MultiAssayExperiment} API}

\item{colData}{A \code{data.frame} of clinical data with patient identifiers
as rownames}

\item{idConverter}{A function to be used against the sample or specimen
identifiers to match those in the rownames of the \code{colData}
(default NULL)}

\item{sampleCol}{A single string indicating the sample identifiers
column in the colData dataset}

\item{patientCol}{A single string indicating the patient identifiers
in colData, "row.names" extracts the colData row names}

\item{...}{Additonal arguments to pass to the 'idConverter' function.}
}
\value{
A \code{DataFrame} class object of mapped samples and patient
identifiers including assays
}
\description{
This function helps create a sampleMap in preparation of a
\code{MultiAssayExperiment} object. This especially useful when the
sample identifiers are not very different, as in the case of TCGA barcodes.
An \code{idConverter} function can be provided to truncate such sample
identifiers and obtain patient identifiers.
}
\examples{
## Minimal example
expList <- list(assay1 = matrix(1:6, ncol = 2L,
        dimnames = list(paste0("feature", 1:3), c("A-J", "B-J"))),
    assay2 = matrix(1:4, ncol = 2,
        dimnames = list(paste0("gene", 1:2), c("A-L", "B-L"))))

## Mock colData
myPheno <- data.frame(var1 = c("Yes", "No"), var2 = c("High", "Low"),
    row.names = c("a", "b"))

## A look at the identifiers
vapply(expList, colnames, character(2L))
rownames(myPheno)

## Use 'idConverter' to correspond sample names to patient identifiers
generateMap(expList, myPheno,
    idConverter = function(x) substr(tolower(x), 1L, 1L))

}
\author{
M. Ramos, M. Morgan, L. Schiffer
}
