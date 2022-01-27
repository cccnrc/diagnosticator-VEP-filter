# Diagnosticator VEP-filter

#### This is the VEP-filter dependency of [Diagnosticator](https://diagnosticator.com) local app

`VEP-filter` runs the actual filtering on the VCF file through Ensembl VEP [vep_filter](https://m.ensembl.org/info/docs/tools/vep/script/vep_filter.html) function
it runs [dockerized](https://hub.docker.com/r/cccnrc/diagnosticator-vep) and waits for input files
(whatever file ends with `*.input`) to be detected within the shared
docker volume (among [Diagnosticator](https://diagnosticator.com), [VEP-filter](https://github.com/cccnrc/diagnosticator-VEP-filter) and [asilo](https://github.com/cccnrc/diagnosticator-asilo)) and, once detected, launch the VEP filtering analysis on them
input files are created by [Diagnosticator](https://diagnosticator.com)rq-worker

this application basically consists of a script `waiter-filter-v2.sh` which constantly runs;
as soon as a file ending in: `*.input` is detected it operates the VEP filtering step
with the filters specified in that input file and after the analysis

filters for `VEP-filter` are the first column, and they consists of a list
of [VEP consequences](https://m.ensembl.org/info/genome/variation/prediction/predicted_data.html) that need to be excluded by the VCF analysis
the rest of the input file are inputs to be passed to the second step: [`asilo`](https://github.com/cccnrc/diagnosticator-asilo)

once the analysis is terminated, the script creates the `*.asilo_input` for [`asilo`](https://github.com/cccnrc/diagnosticator-asilo)
and moves the `*.input` to `*.output`


### DEVELOPMENT instructions
```
### clone github repo
git clone https://github.com/cccnrc/diagnosticator-VEP-filter.git
APP_DIR=$( realpath ./diagnosticator-VEP-filter )
cd $APP_DIR

### change whatever in the application files
atom ./waiter-filter-v2.sh

### rebuild the docker
docker build -t diagnosticator-vep:0.3 .

### try to run the docker (mount a volume in which you have a VCF file)
#     - you can use VCF-EXAMPLE directory in this repo
docker run --rm -it --name DX-VEP \
  -v ${APP_DIR}/VCF-EXAMPLE:/home/VEP_INPUT \
  diagnosticator-vep:0.3 /bin/bash

### from another terminal window create the *.input file to start the analysis
docker exec -it DX-VEP /bin/bash
echo -e "5_prime_UTR_variant,3_prime_UTR_variant,intron_variant,intergenic_variant\tDIAGNOSTICATOR-TUTORIAL.vcf\tkidney_acmg59.gl\t10E-5\tkidney_acmg59.gl\t10E-5" > /home/VEP_INPUT/try0.input

### you will see analysis logs in the first terminal and
#     if everything works fine the script will generate:
#      - DIAGNOSTICATOR-TUTORIAL.FILTERED.vcf         ### filtered VCF
#      - try0.asilo_input                             ### input file for asilo
#      - try0.output                                  ### from try0.input
```
you can also couple this `VEP-filter` with `asilo` dependency:
```
### run VEP-filter
docker run --rm -it --name DX-VEP \
  -v ${APP_DIR}/VCF-EXAMPLE:/home/VEP_INPUT \
  cccnrc/diagnosticator-vep:latest /bin/bash

### run ASILO (from another terminal)
docker run --rm -it --name DX-ASILO \
  -v ${APP_DIR}/VCF-EXAMPLE:/INPUT \
  cccnrc/diagnosticator-asilo:latest /bin/bash

### from another terminal window create the *.input file to start the analysis
#     you will see that the two dockers will couple their analysis and generate both outputs
docker exec -it DX-VEP /bin/bash
echo -e "5_prime_UTR_variant,3_prime_UTR_variant,intron_variant,intergenic_variant\tDIAGNOSTICATOR-TUTORIAL.vcf\tkidney_acmg59.gl\t10E-5\tkidney_acmg59.gl\t10E-5" > /home/VEP_INPUT/try0.input

### you will see analysis logs in the first and second terminal in succession and
#     if everything works fine the script will generate:
# VEP-filter (step 1):
#      - DIAGNOSTICATOR-TUTORIAL.FILTERED.vcf         ### filtered VCF
#      - try0.asilo_input                             ### input file for asilo
#      - try0.output                                  ### from try0.input
# ASILO (step 2):
#      - DIAGNOSTICATOR-TUTORIAL.csv                  ### converted CSV of the input VCF
#      - analisi_result                               ### DIR with the results to be loaded in Diagnosticator
#      - ASILO.NEW                                    ### flag to store datetime of the last analysis
#      - try0.asilo_input.output                      ### from try0.asilo_input
```

### UPDATE github with your new branch
```
cd $APP_DIR
git branch <your-name>-development
git checkout <your-name>-development
git add .
git commit -m "<your-name>-development ..."
git push https://github.com/cccnrc/diagnosticator-VEP-filter.git <your-name>-development
```

### PULL to dockerhub [diagnosticator-vep](https://hub.docker.com/r/cccnrc/diagnosticator-vep)
```
docker build -t cccnrc/diagnosticator-vep:0.3 .
docker build -t cccnrc/diagnosticator-vep:latest .

docker push cccnrc/diagnosticator-vep:0.3
docker push cccnrc/diagnosticator-vep:latest
```
