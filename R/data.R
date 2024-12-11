#' TCGA Cancer Disease Codes Table
#'
#' A dataset for obtaining the cancer codes in TCGA for about 13 different
#' types of cancers.
#'
#' @format A data frame with 37 rows and 2 variables:
#'   * Study.Abbreviation: Disease Code used in TCGA
#'   * Available: Cancer datasets available via curatedTCGAData
#'   * SubtypeData: Subtype curation data available via curatedTCGAData
#'   * Study.Name: The full length study name (i.e., type of cancer)
#' @return The TCGA `diseaseCodes` table
#'
#' @usage data("diseaseCodes")
#'
#' @source <https://gdc.cancer.gov/resources-tcga-users/tcga-code-tables/tcga-study-abbreviations>
"diseaseCodes"

#' Barcode Sample Type Table
#'
#' A dataset that contains the mappings for sample codes in the TCGA
#' barcodes.
#' @format A data frame with 19 rows and 3 variables:
#'   * Code: Two digit code number found in the barcode
#'   * Definition: Long name for the sample type
#'   * Short.Letter.Code: Letter code for the sample type
#'
#' @return The TCGA `sampleTypes` table
#'
#' @usage data("sampleTypes")
#'
#' @source <https://gdc.cancer.gov/resources-tcga-users/tcga-code-tables/sample-type-codes>
"sampleTypes"

#' Clinical dataset names in TCGA
#'
#' A dataset of names for each of the TCGA cancer codes available.
#' These names were obtained by the clinical datasets from
#' [getFirehoseData][RTCGAToolbox::getFirehoseData]. They serve to subset the
#' current datasets provided by `curatedTCGAData`.
#'
#' @format A [CharacterList][IRanges::CharacterList-class] of names for 33
#'   cancer codes
#'
#' @return The clinical dataset column names in TCGA as provided by the
#' `RTCGAToolbox`
#'
#' @usage data("clinicalNames")
"clinicalNames"
