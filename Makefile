FASTQC = ../FastQC/fastqc 
READSDIR = ../reads 

QCDIR = $(CURDIR)/QC
$(QCDIR):
	mkdir -p $(QCDIR)

READS = $(shell find $(READSDIR) -name '*.txt.gz')

fastqc: $(QCDIR)
	for read in $$(find $(READSDIR) -name '*.txt.gz'); do \
	    $(FASTQC) --outdir $(QCDIR) $$read; \
	done

.PHONY: fastqc
