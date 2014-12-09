FASTQC = ../FastQC/fastqc 
READSDIR = ../2014-12-03-H15DLBGXX 

QCDIR = $(CURDIR)/QC
$(QCDIR):
	mkdir -p $(QCDIR)

TRIMDIR = $(CURDIR)/trimmed
$(TRIMDIR):
	mkdir -p $(TRIMDIR)

READS = $(shell find $(READSDIR) -name '*.txt.gz')

fastqc: $(QCDIR)
	for read in $$(find $(READSDIR) -name '*.txt.gz'); do \
	  $(FASTQC) --outdir $(QCDIR) $$read; \
	done

trim: $(TRIMDIR)
	for f in $$(find $(READSDIR) -type f \( -name '*1_sequence.txt.gz' -o -name '*2_sequence.txt.gz' \)|sed 's/_[1-2]_sequence/_sequence/g'|sort|uniq -d); do \
	  interleave_pairs $$(echo $$f|sed 's/_sequence/_1_sequence/g') $$(echo $$f|sed 's/_sequence/_2_sequence/g') | \
	  trim_edges -l 9 --paired_reads | \
	  trim_quality -q 20 -w 5 --paired_reads | \
	  deinterleave_pairs -z -o $(TRIMDIR)/$$(basename $$f|sed 's/_sequence/_1_sequence/g') $(TRIMDIR)/$$(basename $$f|sed 's/_sequence/_2_sequence/g'); \
	done

.PHONY: fastqc interleave
