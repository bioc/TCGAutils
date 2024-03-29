#' Make a GRangesList from TCGA Copy Number data
#'
#' `makeGRangesListFromCopyNumber` allows the user to convert objects of
#' class `data.frame` or [S4Vectors::DataFrame] to a
#' \linkS4class{GRangesList}. It includes additional features specific to TCGA
#' data such as, hugo symbols, probe numbers, segment means, and
#' ucsc build (if available).
#'
#' @param df A `data.frame` or `DataFrame` class object. `list`
#' class objects are coerced to `data.frame` or `DataFrame`.
#' @param split.field A `character` vector of length one indicating
#' the column to be used as sample identifiers
#' @param names.field A `character` vector of length one indicating the
#' column to be used as names for each of the ranges in the data
#' @param ... Additional arguments to pass on to
#' \link{makeGRangesListFromDataFrame}
#'
#' @return A \link{GRangesList} class object
#'
#' @examples
#' library(GenomicDataCommons)
#'
#' manif <- files() |>
#'     filter(~ cases.project.project_id == "TCGA-COAD" &
#'         data_type == "Copy Number Segment") |>
#'     manifest(size = 1)
#'
#' fname <- gdcdata(manif$id)
#'
#' barcode <- UUIDtoBarcode(names(fname), from_type = "file_id")
#' barcode <- barcode[["associated_entities.entity_submitter_id"]]
#'
#' cndata <- read.delim(fname[[1L]], nrows = 10L)
#'
#' cngrl <- makeGRangesListFromCopyNumber(cndata, split.field = "GDC_Aliquot",
#'     keep.extra.columns = TRUE)
#'
#' names(cngrl) <- barcode
#' GenomeInfoDb::genome(cngrl) <- extractBuild(fname[[1L]])
#' cngrl
#'
#' @export makeGRangesListFromCopyNumber
makeGRangesListFromCopyNumber <-
    function(df, split.field, names.field = "Hugo_Symbol", ...) {
        if (is.list(df) && !inherits(df, "data.frame"))
            df <- do.call(rbind, df)

        if (!S4Vectors::isSingleString(names.field))
            stop("'names.field' must be a single sting")
        if (!S4Vectors::isSingleString(split.field))
            stop("'split.field' must be a single sting")

        twoMeta <- all(c("num_probes", "segment_mean") %in% tolower(names(df)))
        rnames <- tolower(names(df)) %in% tolower(names.field)
        ncbi <- tolower(names(df)) %in% "ncbi_build"

        if (any(rnames) && sum(rnames) == 1L) {
            setrname <- names(df)[rnames]
            grl <- makeGRangesListFromDataFrame(df = df,
                split.field = split.field, names.field = setrname, ...)
        } else {
            grl <- makeGRangesListFromDataFrame(df = df, split.field =
                split.field, ...)
        }

        if (twoMeta) {
            numProb <- names(df)[match("num_probes", tolower(names(df)))]
            segMean <- names(df)[match("segment_mean", tolower(names(df)))]
            mcols(grl) <- cbind(mcols(grl), DataFrame(num_probes = numProb,
                segment_mean = segMean))
        }
        if (any(ncbi) && sum(ncbi) == 1L) {
            ncbi_build <- names(df)[ncbi]
            build_name <- unique(df[[ncbi_build]])
            if (length(build_name) != 1L) {
                warning("inconsistent ncbi_build values in data")
            } else {
                ucscBuild <- translateBuild(build_name, "UCSC")
                GenomeInfoDb::genome(grl) <- ucscBuild
            }
        }
        grl
    }
