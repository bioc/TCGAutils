.find_with_xfix <- function(df_colnames, xfix1, xfix2,
        start.field, end.field, xfixType = "pre") {
    fixint <- intersect(xfix1, xfix2)
    fixint <- fixint[fixint != ""]
    if (length(fixint) > 1L) {
        kword <- "region"
        warning(" Multiple ", xfixType, "fixes found, using keyword '", kword,
                "' or taking first one")
        ## keywords to keep, else take first one
        gfix <- grep(kword, fixint, value = TRUE)
        if (length(gfix) && isSingleString(gfix))
            fixint <- gfix
        fixint <- fixint[[1L]]
    }
    if (!isSingleString(fixint))
        stop("'start.field' and 'end.field' ", xfixType, "fixes do not match")
    names(fixint) <- xfixType

    fixFUN <- switch(xfixType, pre = I, suf = rev)
    start.field <- paste(fixFUN(c(fixint, start.field)), collapse = "")
    validEnd <- vapply(end.field, function(efield)
        paste(fixFUN(c(fixint, efield)), collapse = "") %in% df_colnames,
        logical(1L))
    stopifnot(sum(validEnd) == 1L)
    end.field <- paste(fixFUN(c(fixint, end.field[validEnd])), collapse = "")
    if (!length(start.field) && !length(end.field))
        list(c(start.field = "", end.field = ""), "")
    else
        list(c(start.field = start.field, end.field = end.field), fixint)
}

.tallySameLength <- function(fix1, fix2) {
    if (!length(fix1) && !length(fix2)) {
        0L
    } else {
        hasPos <- sum(vapply(c(fix1, fix2),
            function(x) grepl("pos", x, ignore.case = TRUE),
            logical(1L)
        ))
        sum(
            identical(fix1, fix2),
            identical(length(fix1), length(fix2)),
            hasPos
        )
    }
}

.strMatch <- function(strings, table) {
    unlist(lapply(strings, function(x)
        grep(x, table, ignore.case = TRUE)
    ))
}

## Helper functions
.find_start_end_cols <- function (df_colnames, start.field, end.field) {
    idx1 <- which(df_colnames %in% start.field)
    idx2 <- which(df_colnames %in% end.field)
    if (length(idx1) == 1L && length(idx2) == 1L) {
        return(list(c(start = idx1, end = idx2), list(c(none = ""))))
    }
    idx1 <- .strMatch(start.field, df_colnames)
    idx2 <- .strMatch(end.field, df_colnames)
    if (length(idx1) == 1L && length(idx2) == 1L) {
        return(list(c(start = idx1, end = idx2), list(c(none = ""))))
    }
    prefixes1 <- .collect_prefixes(df_colnames, start.field)
    prefixes2 <- .collect_prefixes(df_colnames, end.field)
    suffixes1 <- .collect_suffixes(df_colnames, start.field)
    suffixes2 <- .collect_suffixes(df_colnames, end.field)
    tallypre <- .tallySameLength(prefixes1, prefixes2)
    tallysuff <- .tallySameLength(suffixes1, suffixes2)
    tally <- sort(c(prefixes = tallypre, suffixes = tallysuff))[2]
    reslist <- list(
        c(start = NA_integer_, end = NA_integer_), list(c(none = ""))
    )
    if (!tally) return(reslist)
    fix <- names(tally)
    startend.fields <- .find_with_xfix(
        df_colnames, get(paste0(fix, 1)), get(paste0(fix, 2)),
        start.field, end.field, substr(fix, 1, 3)
    )
    idx1 <- which(df_colnames %in% startend.fields[[1L]][["start.field"]])
    idx2 <- which(df_colnames %in% startend.fields[[1L]][["end.field"]])
    if (length(idx1) == 1L && length(idx2) == 1L) {
        reslist[[1L]] <- c(start = idx1, end = idx2)
        reslist[[2L]][[1L]] <- startend.fields[[2L]]
    }
    reslist
}

.collect_prefixes <- function (df_colnames, field) {
    df_colnames_nc <- nchar(df_colnames)
    prefixes <- lapply(field, function(suf) {
        pref_nc <- df_colnames_nc - nchar(suf)
        idx <- which(substr(df_colnames, pref_nc + 1L, df_colnames_nc) == suf)
        substr(df_colnames[idx], 1L, pref_nc[idx])
    })
    pref <- unique(unlist(prefixes))
    pref[pref != ""]
}

.collect_suffixes <- function(df_colnames, field) {
    suffixes <- lapply(field, function(pre) {
        idx <- which(startsWith(df_colnames, pre))
        substr(df_colnames[idx], nchar(field) + 1L,
            nchar(df_colnames[idx]))
    })
    suff <- unique(unlist(suffixes))
    suff[suff != ""]
}

.find_strands_col <- function(df_colnames, strand.field, xfix) {
    fixFUN <- switch(names(xfix[[1]]), pre = I, suf = rev, none = I)
    idx <- which(df_colnames %in%
        paste(fixFUN(c(xfix, strand.field)), collapse = ""))
    if (length(idx) == 0L)
        idx <- which(df_colnames %in% strand.field)
    if (length(idx) == 0L)
        return(NA_integer_)
    if (length(idx) >= 2L) {
        warning("Multiple strand measurements detected, taking first one")
        idx <- idx[[1L]]
    }
    idx
}

.find_seqnames_col <- function (df_colnames, seqnames.field, xfix) {
    fixFUN <- switch(names(xfix[[1]]), pre = I, suf = rev, none = I)
    idx <- which(df_colnames %in%
        paste(fixFUN(c(xfix, seqnames.field)), collapse = ""))
    if (length(idx) == 0L)
        idx <- which(df_colnames %in% seqnames.field)
    if (length(idx) == 0L)
        return(NA_integer_)
    if (length(idx) >= 2L)
        warning("cannnot determine seqnames column unambiguously")
        return(idx[[1L]])
    idx
}

.find_width_col <- function (df_colnames, width.field, xfix) {
    fixFUN <- switch(names(xfix[[1]]), pre = I, suf = rev, none = I)
    idx <- which(df_colnames %in%
        paste(fixFUN(c(xfix, width.field)), collapse = ""))
    if (length(idx) == 0L)
        idx <- which(df_colnames %in% width.field)
    if (length(idx) == 0L)
        return(NA_integer_)
    if (length(idx) >= 2L) {
        warning("cannnot determine width column unambiguously")
        return(idx[[1L]])
    }
    idx
}

#' Obtain minimum necessary names for the creation of a GRangesList object
#'
#' This function attempts to match chromosome, start position, end position and
#' strand names in the given character vector. Modified helper from the
#' `GenomicRanges` package.
#'
#' @param df_colnames A `character` vector of names in a dataset
#' @param seqnames.field A `character` vector of the chromosome name
#' @param start.field A `character` vector that indicates the column name
#' of the start positions of ranged data
#' @param end.field A `character` vector that indicates the end position
#' of ranged data
#' @param strand.field A `character` vector of the column name that
#' indicates the strand type
#' @param ignore.strand logical (default FALSE) whether to ignore the strand
#' field in the data
#' @return Index positions vector indicating columns with appropriate names
#'
#' @examples
#' myDataColNames <- c("Start_position", "End_position", "strand",
#'                  "chromosome", "num_probes", "segment_mean")
#' findGRangesCols(myDataColNames)
#'
#' @export findGRangesCols
findGRangesCols <- function (df_colnames,
    seqnames.field = c("seqnames", "seqname", "chromosome",
        "chrom", "chr", "chromosome_name", "seqid", "om"),
    start.field = "start",
    end.field = c("end", "stop"),
    strand.field = "strand",
    ignore.strand = FALSE) {

    df_colnames0 <- tolower(df_colnames)
    seqnames.field0 <-
        GenomicRanges:::.normarg_field(seqnames.field, "seqnames")
    start.field0 <- GenomicRanges:::.normarg_field(start.field, "start")
    end.field0 <- GenomicRanges:::.normarg_field(end.field, "end")
    start_end_cols <- .find_start_end_cols(df_colnames0, start.field0,
        end.field0)
    xfix <- start_end_cols[[2L]]
    width_col <- .find_width_col(df_colnames0, "width", xfix)
    seqnames_col <- .find_seqnames_col(df_colnames0, seqnames.field0, xfix)
    if (ignore.strand) {
        strand_col <- NA_integer_
    } else {
        strand.field0 <- GenomicRanges:::.normarg_field(strand.field, "strand")
        strand_col <- .find_strands_col(df_colnames0, strand.field0, xfix)
    }
    c(seqnames = seqnames_col, start_end_cols[[1L]], width = width_col,
        strand = strand_col)
}
