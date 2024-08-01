#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --time=11:00:00
#SBATCH --mem=500gb
#SBATCH -o JOB.out
#SBATCH --partition general
#SBATCH -A c00859
#SBATCH --job-name=test_2_sra
#SBATCH --array=1-2

project_folder=/N/scratch/jzayatz/02_test
accession_list=${project_folder}/test_sra.txt
accession=$(head -n $SLURM_ARRAY_TASK_ID $accession_list | tail -n 1)

cd ${project_folder}

mkdir -p ${project_folder}/kneaddata/main
mkdir -p ${project_folder}/metaphlan/main
mkdir -p ${project_folder}/humann/main
mkdir -p ${project_folder}/humann/regrouped
mkdir -p ${project_folder}/humann/relab/pathways
mkdir -p ${project_folder}/humann/relab/ecs 
mkdir -p ${project_folder}/humann/relab/genes

module load python
module load trimmomatic
module load sra-toolkit
module load fastqc

prefetch ${accession}
fasterq-dump ${accession} --split-files
cd "${accession}"
rm "${accession}.sra"
cd ..
mv "${accession}".fastq "${project_folder}" 2>/dev/null || :
mv "${accession}"_1.fastq "${project_folder}" 2>/dev/null || :
mv "${accession}"_2.fastq "${project_folder}" 2>/dev/null || :
rmdir "${accession}" 2>/dev/null || :



kneaddata --input1 ${project_folder}/${accession}_1.fastq --output ${project_folder}/kneaddata/main --threads 24 --output-prefix ${accession}  --input2 ${project_folder}/${accession}_2.fastq --cat-final-output  --reference-db /N/scratch/afdb/nvme/biobakery/kneaddata_db_human_genome --bypass-trf --remove-intermediate-output --serial --run-trf  --remove-intermediate-output  && gzip -f ${project_folder}/kneaddata/main/${accession}.fastq 
metaphlan ${project_folder}/kneaddata/main/${accession}.fastq.gz --input_type fastq --output_file ${project_folder}/metaphlan/main/${accession}_taxonomic_profile.tsv --samout ${project_folder}/metaphlan/main/${accession}_bowtie2.sam --nproc 24 --no_map --tmp_dir ${project_folder}/metaphlan/main 
humann --input ${project_folder}/kneaddata/main/${accession}.fastq.gz --output ${project_folder}/humann/main --o-log ${project_folder}/humann/main/${accession}.log --threads 24 --taxonomic-profile ${project_folder}/metaphlan/main/${accession}_taxonomic_profile.tsv  --remove-temp-output   
humann_regroup_table --input ${project_folder}/humann/main/${accession}_genefamilies.tsv --output ${project_folder}/humann/regrouped/${accession}_ecs.tsv --groups uniref90_level4ec
humann_renorm_table --input ${project_folder}/humann/main/${accession}_genefamilies.tsv --output ${project_folder}/humann/relab/genes/${accession}_genefamilies_relab.tsv --units relab --special n
humann_renorm_table --input ${project_folder}/humann/main/${accession}_pathabundance.tsv --output ${project_folder}/humann/relab/pathways/${accession}_pathabundance_relab.tsv --units relab --special n
humann_renorm_table --input ${project_folder}/humann/regrouped/${accession}_ecs.tsv --output ${project_folder}/humann/relab/ecs/${accession}_ecs_relab.tsv --units relab --special n
