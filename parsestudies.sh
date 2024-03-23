#!/bin/bash

process_accession() {
    local accession=$1
    local project_folder=$2
    prefetch ${accession}
    fasterq-dump ${accession} --split-files
    cd "${accession}"
    rm "${accession}.sra"
    cd ..
    mv "${accession}"_1.fastq "${project_folder}"
    mv "${accession}"_2.fastq "${project_folder}" 2>/dev/null || :
    rmdir "${accession}" 2>/dev/null || :
}

main() {
    module load python
    module load trimmomatic
    module load sra-toolkit
    module load fastqc
    local accession_list=$1
    local project_folder=${accession_list//.txt}
    mkdir -p "${project_folder}"
    while IFS= read -r accession || [ -n "$accession" ]; do
	process_accession "${accession}" "${project_folder}"
    done < "${accession_list}"
}

main "$@"
