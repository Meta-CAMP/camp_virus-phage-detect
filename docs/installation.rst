.. highlight:: shell

============
Installation
============


Stable release
--------------

1. Clone repo from `github <https://github.com/b-tierney/camp_assembled-virus-characterization>_`. 

2. Set up the conda environment (contains, Snakemake) using ``configs/conda/camp_assembled-virus-characterization.yaml``. 

3. Make sure the installed pipeline works correctly. ``pytest`` only generates temporary outputs so no files should be created.
::
    cd camp_assembled-virus-characterization
    conda env create -f configs/conda/camp_assembled-virus-characterization.yaml
    conda activate camp_assembled-virus-characterization
    pytest .tests/unit/

