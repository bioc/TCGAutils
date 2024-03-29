## function to figure out exact endpoint based on TCGA barcode
.barcode_files <- function(startPoint = "cases", submitter_id = TRUE) {
    keywords <- c("cases", "samples", "portions", "analytes", "aliquots")
    last <- match.arg(startPoint, keywords)
    indx <- seq_len(which(keywords == last))
    sub_id <- if (submitter_id) "submitter_id" else NULL
    paste(c(keywords[indx], sub_id), collapse = ".")
}

.subword_id <- function(keyword) {
    ret <- paste0(keyword, "_ids")
    setNames(paste0("submitter_", ret), ret)
}

.barcode_cases <- function(bcodeType = "case") {
    if (identical(bcodeType, "case"))
        setNames("submitter_id", "case_id")
    else
        .subword_id(bcodeType)
}

.findBarcodeLimit <- function(barcode) {
    .checkBarcodes(barcode)
    filler <- .uniqueDelim(barcode)
    splitCodes <- strsplit(barcode, filler)
    obsIdx <- unique(lengths(splitCodes))

    if (obsIdx < 3L)
        stop("Minimum barcode fields required: ", 3L,
            "; first three are 'project-TSS-participant'")

    key <- c(rep("case", 3L), "sample", "analyte", "aliquot", "aliquot")[obsIdx]
    if (identical(key, "analyte")) {
        analyte_chars <- unique(
            vapply(splitCodes, function(x) nchar(x[[obsIdx]]), integer(1L))
        )
        if (!S4Vectors::isSingleInteger(analyte_chars))
            stop("Inconsistent '", key, "' barcodes")
        if (analyte_chars < 3)
            key <- "portion"
    } else if (identical(key, "aliquot")) {
        if (identical(obsIdx, 6L)) {
            ali_chars <- vapply(splitCodes, function(x)
                nchar(x[c(obsIdx-1L, obsIdx)]), integer(2L))
            if (identical(ali_chars, c(2L, 3L)))
                key <- "slide"
        }
    }
    key
}

.buildIDframe <- function(info, id_list) {
    barcodes_per_file <- lengths(id_list)
    # And build the data.frame
    data.frame(
        id = rep(ids(info), barcodes_per_file),
        barcode = if (!length(ids(info))) character(0L) else unlist(id_list),
        row.names = NULL,
        stringsAsFactors = FALSE
    )
}

.cleanExpand <- function(result, ids) {
    samps <- result[["samples"]]
    usamps <- unlist(samps)
    splitsamps <- split(unname(usamps), gsub("[0-9]*$", "", names(usamps)))
    splits <- strsplit(names(splitsamps), "\\.")
    cnames <- unique(vapply(splits, function(x) {
        paste0(x[-1], collapse = ".") }, character(1)))
    first <- unlist(splitsamps[c(TRUE, FALSE)])
    second <- unlist(splitsamps[c(FALSE, TRUE)])
    pos <- match(ids, first)
    resframe <- cbind.data.frame(first[pos], second[pos], row.names = NULL,
        stringsAsFactors = FALSE)
    names(resframe) <- cnames
    resframe
}

.orderedDF <- function(..., orderBy) {
    df <- data.frame(..., stringsAsFactors = FALSE)
    orderIdx <- match(orderBy, df[["info..from_type.."]])
    res <- df[orderIdx, ]
    rownames(res) <- NULL
    res
}

.nestedlisttodf <- function(x, orderBy) {
    .check_ids_found(names(x), orderBy)
    x <- Filter(length, x[orderBy])
    data.frame(
        rep(names(x), vapply(x, nrow, integer(1))),
        unlist(x, use.names = FALSE),
        stringsAsFactors = FALSE
    )
}

.check_ids_found <- function(resnames, id_vector) {
    idin <- id_vector %in% resnames
    if (!all(idin)) {
        mids <- paste(
            BiocBaseUtils::selectSome(id_vector[!idin], 4), collapse = ", "
        )
        warning("Identifiers not found: ", mids, call. = FALSE)
    }
}

#' @name ID-translation
#'
#' @title Translate study identifiers from barcode to UUID and vice versa
#'
#' @description These functions allow the user to enter a character vector of
#' identifiers and use the GDC API to translate from TCGA barcodes to
#' Universally Unique Identifiers (UUID) and vice versa. These relationships
#' are not one-to-one. Therefore, a `data.frame` is returned for all
#' inputs. The UUID to TCGA barcode translation only applies to file and case
#' UUIDs. Two-way UUID translation is available from 'file_id' to 'case_id'
#' and vice versa. Please double check any results before using these
#' features for analysis. Case / submitter identifiers are translated by
#' default, see the `from_type` argument for details. All identifiers are
#' converted to lower case.
#'
#' @details
#' Based on the file UUID supplied, the appropriate entity_id (TCGA barcode) is
#' returned. In previous versions of the package, the 'end_point' parameter
#' would require the user to specify what type of barcode needed. This is no
#' longer supported as `entity_id` returns the appropriate one.
#'
#' @param id_vector character() A vector of UUIDs corresponding to
#'     either files or cases (default assumes case_ids)
#'
#' @param from_type character(1) Either `case_id` or `file_id` indicating the
#'     type of `id_vector` entered (default `"case_id"`)
#'
#' @return Generally, a `data.frame` of identifier mappings
#'
#' @md
#'
#' @examples
#' ## Translate UUIDs >> TCGA Barcode
#'
#' uuids <- c("b4bce3ff-7fdc-4849-880b-56f2b348ceac",
#' "5ca9fa79-53bc-4e91-82cd-5715038ee23e",
#' "b7c3e5ad-4ffc-4fc4-acbf-1dfcbd2e5382")
#'
#' UUIDtoBarcode(uuids, from_type = "file_id")
#'
#' UUIDtoBarcode("ae55b2d3-62a1-419e-9f9a-5ddfac356db4", from_type = "case_id")
#'
#' UUIDtoBarcode("d85d8a17-8aea-49d3-8a03-8f13141c163b", "aliquot_ids")
#'
#' @author Sean Davis, M. Ramos
#'
#' @export UUIDtoBarcode
UUIDtoBarcode <-  function(
    id_vector, from_type = c("case_id", "file_id", "aliquot_ids")
) {
    from_type <- match.arg(from_type)
    targetElement <- APIendpoint <- "submitter_id"
    if (identical(from_type, "file_id")) {
        APIendpoint <- "associated_entities.entity_submitter_id"
        targetElement <- "associated_entities"
    } else if (identical(from_type, "aliquot_ids")) {
        APIendpoint <- "samples.portions.analytes.aliquots.submitter_id"
        targetElement <- "samples"
    }
    selector <- switch(from_type,
        case_id = identity,
        aliquot_ids =
            function(x)
                select(
                    x = x,
                    fields = c(
                        APIendpoint,
                        "samples.portions.analytes.aliquots.aliquot_id"
                    )
                ),
        function(x) select(x = x, fields = APIendpoint)
    )

    funcRes <- switch(from_type,
        file_id = files(),
        case_id = cases(),
        aliquot_ids = cases())
    info <- results_all(
        selector(
            GenomicDataCommons::filter(funcRes, as.formula(
                paste("~ ", from_type, "%in% id_vector")
            ))
        )
    )
    if (!length(info))
        stop(
            paste(strwrap(
                "No barcodes were found. Note that legacy files were removed
                as of GDC Data Portal version 1.30.4; see
                https://docs.gdc.cancer.gov/. Only case, file, and aliquot
                UUIDs are supported.",
                exdent = 2
            ), collapse = "\n"),
            call. = FALSE
        )

    rframe <-
        if (identical(from_type, "case_id"))
            .orderedDF(
                info[[from_type]], info[[targetElement]], orderBy = id_vector
            )
        else if (identical(from_type, "file_id"))
            .nestedlisttodf(info[[targetElement]], id_vector)
        else
            return(.cleanExpand(info, id_vector))

    names(rframe) <- c(from_type, APIendpoint)
    rframe
}

#' @rdname ID-translation
#'
#' @param to_type character(1) The desired UUID type to obtain, can either be
#'     `"case_id"` (default) or `"file_id"`
#'
#' @examples
#' ## Translate file UUIDs >> case UUIDs
#'
#' uuids <- c("b4bce3ff-7fdc-4849-880b-56f2b348ceac",
#' "5ca9fa79-53bc-4e91-82cd-5715038ee23e",
#' "b7c3e5ad-4ffc-4fc4-acbf-1dfcbd2e5382")
#'
#' UUIDtoUUID(uuids)
#'
#' @export UUIDtoUUID
UUIDtoUUID <- function(
    id_vector, to_type = c("case_id", "file_id")
) {
    id_vector <- tolower(id_vector)
    type_ops <- c("case_id", "file_id")
    to_type <- match.arg(to_type)
    from_type <- type_ops[!type_ops %in% to_type]
    if (!length(from_type))
        stop("Provide a valid UUID type")

    endpoint <- switch(to_type,
        case_id = "cases.case_id",
        file_id = "files.file_id")
    apifun <- switch(to_type,
        file_id = cases(),
        case_id = files())
    info <- results_all(
        select(filter(apifun, as.formula(
            paste("~ ", from_type, "%in% id_vector")
            )),
        endpoint)
    )
    targetElement <- gsub("(\\w+).*", "\\1", endpoint)
    id_list <- lapply(info[[targetElement]], function(x) {x[[1]]})

    rframe <- .buildIDframe(info, id_list)
    names(rframe) <- c(from_type, endpoint)
    rframe
}

#' @rdname ID-translation
#'
#' @param barcodes character() A vector of TCGA barcodes
#'
#' @examples
#' ## Translate TCGA Barcode >> UUIDs
#'
#' fullBarcodes <- c("TCGA-B0-5117-11A-01D-1421-08",
#' "TCGA-B0-5094-11A-01D-1421-08",
#' "TCGA-E9-A295-10A-01D-A16D-09")
#'
#' sample_ids <- TCGAbarcode(fullBarcodes, sample = TRUE)
#'
#' barcodeToUUID(sample_ids)
#'
#' participant_ids <- c("TCGA-CK-4948", "TCGA-D1-A17N",
#' "TCGA-4V-A9QX", "TCGA-4V-A9QM")
#'
#' barcodeToUUID(participant_ids)
#'
#' @export barcodeToUUID
barcodeToUUID <-
    function(barcodes)
{
    .checkBarcodes(barcodes)
    bend <- .findBarcodeLimit(barcodes)
    endtargets <- .barcode_cases(bend)
    expander <- gsub("cases\\.", "", .barcode_files(bend, FALSE))

    pand <- switch(expander, cases = identity,
        function(x) expand(x = x, expand = expander))
    info <- results_all(
        pand(x = filter(cases(), as.formula(
            paste("~ ", endtargets, "%in% barcodes")
        )))
    )
    if (identical(expander, "cases")) {
        rframe <- as.data.frame(info[c(endtargets, names(endtargets))],
            stringsAsFactors = FALSE)
    } else {
        idnames <- lapply(ids(info), function(ident) {
            info[["samples"]][[ident]]
        })
        if (!identical(expander, "samples")) {
            exFUN <- switch(expander,
                samples.portions =
                    function(x, i) x[["portions"]],
                samples.portions.analytes =
                    function(x, i) unlist(lapply(
                        x[["portions"]], `[[`, "analytes"), recursive = FALSE),
                samples.portions.analytes.aliquots =
                    function(x, i) unlist(lapply(
                        unlist(
                            lapply(x[["portions"]], `[[`, "analytes"),
                            recursive = FALSE), `[[`, "aliquots"),
                        recursive = FALSE)
                )
            idnames <- unlist(lapply(seq_along(idnames), function(i)
                exFUN(x = idnames[[i]], i = i)
            ), recursive = FALSE)
            idnames <- Filter(function(g) length(g) >= 2L, idnames)
        }
        rescols <- lapply(idnames, `[`,
            c("submitter_id", gsub("s$", "", names(endtargets))))
        rframe <- do.call(rbind, c(rescols, stringsAsFactors = FALSE))
        names(rframe) <- c(endtargets, names(endtargets))
    }
    rframe[na.omit(match(barcodes, rframe[[endtargets]])), , drop = FALSE]
}

.matchSort <- function(major, minor) {
    hits <- S4Vectors::findMatches(major, minor)
    order(S4Vectors::subjectHits(hits))
}

#' @rdname ID-translation
#'
#' @param filenames character() A vector of file names usually obtained
#'     from a `GenomicDataCommons` query
#'
#' @param slides logical(1L) Whether the provided file names correspond to
#'   slides typically with an `.svs` extension. **Note** The barcodes returned
#'   correspond 1:1 with the `filename` inputs. Always triple check the
#'   output against the Genomic Data Commons Data Portal by searching the
#'   file name and comparing associated "Entity ID" with the `submitter_id`
#'   given by the function.
#'
#' @examples
#' library(GenomicDataCommons)
#'
#' ### Query CNV data and get file names
#'
#' cnv <- files() |>
#'     filter(
#'         ~ cases.project.project_id == "TCGA-COAD" &
#'         data_category == "Copy Number Variation" &
#'         data_type == "Copy Number Segment"
#'     ) |>
#'     results(size = 6)
#'
#' filenameToBarcode(cnv$file_name)
#'
#' ### Query slides data and get file names
#'
#' slides <- files() |>
#'     filter(
#'         ~ cases.project.project_id == "TCGA-BRCA" &
#'         cases.samples.sample_type == "Primary Tumor" &
#'         data_type == "Slide Image" &
#'         experimental_strategy == "Diagnostic Slide"
#'     ) |>
#'     results(size = 3)
#'
#' filenameToBarcode(slides$file_name, slides = TRUE)
#'
#' @export filenameToBarcode
filenameToBarcode <- function(filenames, slides = FALSE) {
    filesres <- files()
    endpoint <- "cases.samples.portions.analytes.aliquots.submitter_id"
    reselem <- "cases"
    if (slides) {
        endpoint <- c(
            "cases.samples.portions.slides.submitter_id",
            "associated_entities.entity_submitter_id"
        )
        reselem <- "associated_entities"
    }

    info <- GenomicDataCommons::filter(filesres, ~ file_name %in% filenames) |>
        GenomicDataCommons::select(c("file_name", endpoint))  |>
        results_all()

    if (!length(info))
        stop("Query did not return any results. Check 'filenames' input.")

    reps <- lengths(lapply(info[[reselem]], unlist))
    res <- data.frame(
        file_name = rep(info[["file_name"]], reps),
        file_id = rep(info[["file_id"]], reps),
        placeholder = unname(unlist(info[[reselem]])),
        row.names = NULL,
        stringsAsFactors = FALSE
    )
    names(res)[3] <- head(endpoint, 1L)
    idx <- .matchSort(res[["file_name"]], filenames)
    res[idx, ]
}

.HISTORY_ENDPOINT <- "https://api.gdc.cancer.gov/history"

#' @rdname ID-translation
#'
#' @param id character(1) A UUID whose history of versions is sought
#'
#' @param endpoint character(1) Generally a constant pertaining to the location
#'     of the history api endpoint. This argument rarely needs to change.
#'
#' @return UUIDhistory: A `data.frame` containting a list of associated UUIDs
#'     for the given input along with `file_change` status, `data_release`
#'     versions, etc.
#'
#' @examples
#' ## Get the version history of a BAM file in TCGA-KIRC
#' UUIDhistory("0001801b-54b0-4551-8d7a-d66fb59429bf")
#'
#' @export
UUIDhistory <- function(id, endpoint = .HISTORY_ENDPOINT) {
    if (!requireNamespace("httr", quietly = TRUE))
        stop("Install 'httr' to check UUID status")
    qurl <- paste(endpoint, id, sep = "/")
    resp <- httr::GET(qurl)
    do.call(rbind.data.frame, httr::content(resp))
}
