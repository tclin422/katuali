.PHONY: install update reads clean_test test_basecall test_align test_subsample test_canu test_flye test_flye_racon test_flye_medaka test_flye_nanopolish test_canu_racon test_canu_medaka test_canu_nanopolish test_miniasm_racon check docs test_pipeline_all_fast_assm_polish test_pipeline_all_standard_assm_polish test_pipeline_all_medaka_eval test_pipeline_all_medaka_feat test_pipeline_all_medaka_train test_pipeline_standard_assm_nanopolish test_nanopolish_from_scratch

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
	JOBS=$(shell sysctl -n hw.physicalcpu)
endif
ifeq ($(UNAME), Linux)
	JOBS=$(shell nproc)
endif

IN_VENV=. ./venv/bin/activate
TEST=${IN_VENV} && cd test && katuali -s Snakefile --configfile config.yaml --printshellcmds -j ${JOBS} --config THREADS_PER_JOB=${JOBS}
OPT='--config SCRAPPIE_OPTS="raw -H mean --model rgrgr_r94 --local 10.0 --uuid --temperature1 0.65 --temperature2 1.7"'

venv/bin/activate:
	test -d venv || virtualenv venv --prompt '(katuali) ' --python=python3
	${IN_VENV} && pip install pip --upgrade
	${IN_VENV} && pip install -r requirements.txt

install: venv/bin/activate
	${IN_VENV} && python setup.py install

update: venv/bin/activate
	git stash
	git checkout master
	git pull origin master
	${IN_VENV} && pip install -r requirements.txt


test: install test_basecall test_align test_subsample test_canu test_flye test_flye_racon test_flye_medaka test_flye_nanopolish test_canu_racon test_canu_medaka test_canu_nanopolish test_miniasm_racon check test_pipeline_all_fast_assm_polish test_pipeline_all_standard_assm_polish test_pipeline_all_medaka_eval test_pipeline_all_medaka_feat test_pipeline_all_medaka_train test_pipeline_standard_assm_nanopolish test_nanopolish_from_scratch 

test/config.yaml:
	mkdir -p test
	${IN_VENV} && katuali_config $@ 

test/Snakefile: test/config.yaml
	${IN_VENV} && katuali_datafile Snakefile | xargs -I {} cp {} $@ 

reads:
	mkdir -p test/MinIonRun1
	${IN_VENV} && cd test/MinIonRun1 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/MinIonRun2
	${IN_VENV} && cd test/MinIonRun2 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/GridIonRun1
	${IN_VENV} && cd test/GridIonRun1 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}
	mkdir -p test/GridIonRun2
	${IN_VENV} && cd test/GridIonRun2 && katuali_datafile test/reads.tgz | xargs -I {} tar -xf {}

test/ref.fasta: test/config.yaml
	${IN_VENV} && cp `katuali_datafile test/ref.fasta` $@ 


# The following targets step through a pipeline

test_basecall: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/basecalls.fasta

test_align: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/align/calls2ref.bam

test_subsample: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/align/all_contigs/25X/basecalls.fasta

test_canu: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/canu_gsz_50k/consensus.fasta

test_flye: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/flye_gsz_50k/consensus.fasta

test_flye_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/flye_gsz_50k/racon/consensus.fasta

test_flye_medaka: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/flye_gsz_50k/racon/medaka/consensus.fasta

test_flye_nanopolish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/flye_gsz_50k/racon/nanopolish/consensus.fasta

test_canu_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/canu_gsz_50k/racon/consensus.fasta

test_canu_medaka: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/canu_gsz_50k/racon/medaka/consensus.fasta

test_canu_nanopolish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/canu_gsz_50k/racon/nanopolish/consensus.fasta

test_miniasm_racon: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} MinIonRun1/basecall/scrappie/miniasm_racon/consensus.fasta

test_pipeline_all_fast_assm_polish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_fast_assm_polish --dryrun

test_pipeline_all_standard_assm_polish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_standard_assm_polish --dryrun

test_pipeline_all_medaka_eval: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_eval --dryrun

test_pipeline_all_medaka_feat: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_feat --dryrun

test_pipeline_all_medaka_train: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_medaka_train --dryrun

test_pipeline_all_standard_assm_nanopolish: reads test/ref.fasta test/config.yaml test/Snakefile
	${TEST} all_standard_assm_nanopolish --dryrun

test_nanopolish_from_scratch: clean_test test_canu_nanopolish 

clean_test:
	rm -rf test

check:
	grep '100%' test/logs/*.log
	grep 'Exception' test/logs/*.log || echo "No exceptions found"


# Build docs
SPHINXOPTS      =
SPHINXBUILD     = sphinx-build
PAPER           =
BUILDDIR        = _build
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
ALLSPHINXOPTS   = -d $(BUILDDIR)/doctrees $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) .
DOCSRC          = docs

docs: venv/bin/activate 
	${IN_VENV} && pip install sphinx sphinx_rtd_theme sphinx-argparse
	${IN_VENV} && cd $(DOCSRC) && $(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(DOCSRC)/$(BUILDDIR)/html."
	touch $(DOCSRC)/$(BUILDDIR)/html/.nojekyll

