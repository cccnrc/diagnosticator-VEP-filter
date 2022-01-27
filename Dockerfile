FROM ensemblorg/ensembl-vep

USER root

COPY waiter-filter-v2.sh ./

ENTRYPOINT bash waiter-filter-v2.sh
