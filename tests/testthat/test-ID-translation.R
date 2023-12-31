context("ID translation testing")

test_that("barcodeToUUID translates correctly", {
    pts <- c("TCGA-06-6391", "TCGA-06-6700")
    case_id <- barcodeToUUID(pts)
    expect_true("case_id" %in% names(case_id))
    expect_equal(
        case_id[["case_id"]],
        c("7a4c0a14-ac97-4c2b-a9cc-68cb561b2494",
        "3dddfc44-7bb1-4974-8a65-a84fd4bac484")
    )
    samps <- c("TCGA-06-6700-01A", "TCGA-AD-6888-01A")
    samp_id <- barcodeToUUID(samps)
    expect_true("sample_ids" %in% names(samp_id))
    expect_equal(
        samp_id[["sample_ids"]],
        c("8d35786c-5edb-4a84-b3e5-c401b8c73bd6",
        "ecf0f65b-bf3c-4d0e-899a-f209247cbe97")
    )
    analytes <- c("TCGA-AA-A00L-10A-01X", "TCGA-AA-A00L-10A-01D",
        "TCGA-12-0653-10A-01D")
    analyte_ids <- barcodeToUUID(analytes)
    expect_true("analyte_ids" %in% names(analyte_ids))
    expect_equal(
        analyte_ids[["analyte_ids"]],
        c("4b6a77dc-7a2a-459e-a7a0-253f950f1c8c",
        "1c429d23-89eb-4c35-bef3-9eff2508d9d5",
        "63645523-bb46-40b3-899b-c3fa5fefd121")
    )
    portions <- c("TCGA-AA-A00L-10A-01", "TCGA-AA-A00L-01A-31",
        "TCGA-12-0653-10A-01")
    portion_ids <- barcodeToUUID(portions)
    expect_true("portion_ids" %in% names(portion_ids))
    expect_equal(
        portion_ids[["portion_ids"]],
        c("c72ff462-a355-49fa-8275-c34ef5dd91c9",
        "7d25aecc-9068-463b-adc5-71ec2f4ba7aa",
        "03209a36-67a0-48df-a9f7-a0cedd0db82f")
    )
    aliquots <- c("TCGA-12-0653-10A-01D-0333-01",
        "TCGA-12-0653-10A-01D-0334-04", "TCGA-AA-3556-01A-01D-1953-10")
    aliquot_ids <- barcodeToUUID(aliquots)
    expect_true("aliquot_ids" %in% names(aliquot_ids))
    expect_equal(aliquot_ids[["aliquot_ids"]],
        c("51ddbc44-1cae-454f-bc67-5c5cc3d9e853",
        "2f0fe3f0-6a24-47ee-acba-df9c04d89532",
        "2303247f-9691-4b38-bac2-8a30d6e08cc9")
    )
})


test_that("UUIDtoBarcode translates correctly", {
    file_id <- c(
        "6b7d7a7f-f16d-472d-9b7b-3482c434cc99",
        "2ea70743-f3c6-4b01-8e20-9c8957a71229"
    )
    `associated_entities.entity_submitter_id` <- c(
        "TCGA-NA-A4QY-01A-11D-A28Q-01", "TCGA-NA-A4QY-01A-11D-A28S-05"
    )
    resframe <- UUIDtoBarcode(file_id, from_type = "file_id")
    expect_identical(
        resframe,
        data.frame(
            file_id,
            `associated_entities.entity_submitter_id`
        )
    )

    `portions.analytes.aliquots.aliquot_id` <- c(
        "f8c7d038-1182-42d0-8787-b84b5ca57eaf",
        "b37ea112-340e-4613-8514-d8a8bd47410f",
        "4a9967bf-444c-4573-a082-121a30be7f3b"
    )
    `portions.analytes.aliquots.submitter_id` <- c(
        "TCGA-UF-A71A-06A-11D-A390-01",
        "TCGA-BB-4224-01A-01D-1432-01",
        "TCGA-CN-4735-01A-01D-1432-01"
    )
    resframe <- UUIDtoBarcode(
        `portions.analytes.aliquots.aliquot_id`, from_type = "aliquot_ids"
    )
    expect_identical(
        resframe,
        data.frame(
            `portions.analytes.aliquots.aliquot_id`,
            `portions.analytes.aliquots.submitter_id`
        )
    )

    case_id <- c(
        "ce2b2c41-7d28-4d8b-a037-af842a8fe20f",
        "58574e35-8a30-4207-b127-59fff7c87a43"
    )
    submitter_id <- c("TCGA-NA-A4QY", "TCGA-BB-4224")
    resframe <- UUIDtoBarcode(case_id, from_type = "case_id")
    expect_identical(
        resframe,
        data.frame(
            case_id,
            submitter_id
        )
    )
})


test_that("UUIDtoBarcode shows multiple entries per file_id", {

    file_ids <- c(
        "f9f06937-ac64-4660-baf3-0174736d25b2",
        "5dec335c-83c3-4a4a-80f5-9ec1d1847960",
        "514bc5eb-006d-423b-8432-8fbe7795a312"
    )

    restabs <- lapply(file_ids, UUIDtoBarcode, "file_id")
    results <- do.call(rbind, restabs)

    expect_identical(results, UUIDtoBarcode(file_ids, "file_id"))

    file_ids[2] <- paste(rev(unlist(strsplit(file_ids[2], ""))), collapse = "")

    expect_warning(UUIDtoBarcode(file_ids, "file_id"))
})

test_that("UUIDhistory correctly returns the appropriate identifiers", {

    old_uuids <- c("0001801b-54b0-4551-8d7a-d66fb59429bf",
    "002c67f2-ff52-4246-9d65-a3f69df6789e",
    "003143c8-bbbf-46b9-a96f-f58530f4bb82")

    updated_ids <- vapply(
        stats::setNames(nm = old_uuids),
        function(x) {
            hist <- UUIDhistory(x)
            ## test for data release version 32.0
            cond <- hist[["file_change"]] == "released" &
                hist[["data_release"]] == "32.0"
            hist[cond, "uuid"]
        },
        character(1L)
    )

    ## Updated IDs taken from the GDC Data Portal
    new_uuids <- c("b4bce3ff-7fdc-4849-880b-56f2b348ceac",
    "5ca9fa79-53bc-4e91-82cd-5715038ee23e",
    "b7c3e5ad-4ffc-4fc4-acbf-1dfcbd2e5382")

    expect_identical(updated_ids, setNames(new_uuids, old_uuids))

})
