FASTQC = ../FastQC/fastqc 
READSDIR = ../2014-12-03-H15DLBGXX 
SPADES = ~/nfs/marco/software/SPAdes-3.1.1-Linux/bin/spades.py
SPADESTHREADS = 16
MASURCA = ~/nfs/marco/software/MaSuRCA-2.3.2/masurca
MASURCATHREADS = 16
INSERTSIZEMEAN = 390 
INSERTSIZESTD = 59

SRCDIR = $(CURDIR)/src

QCDIR = $(CURDIR)/QC
$(QCDIR):
	mkdir -p $(QCDIR)

TRIMDIR = $(CURDIR)/trimmed
$(TRIMDIR):
	mkdir -p $(TRIMDIR)

ASSEMBLYDIR = $(CURDIR)/assembly
$(ASSEMBLYDIR):
	mkdir -p $(ASSEMBLYDIR)

SPADESDIR = $(CURDIR)/spades
$(SPADESDIR):
	mkdir -p $(SPADESDIR)

MASURCADIR = $(CURDIR)/masurca
$(MASURCADIR):
	mkdir -p $(MASURCADIR)

CONTIGSDIR = $(CURDIR)/contigs
$(CONTIGSDIR):
	mkdir -p $(CONTIGSDIR)

CONTIGSSTATSDIR = $(CURDIR)/contigs-stats
$(CONTIGSSTATSDIR):
	mkdir -p $(CONTIGSSTATSDIR)

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
	  deinterleave_pairs -z -o $(TRIMDIR)/$$(basename $$f|sed 's/_sequence.txt.gz/_1_sequence.fq.gz/g') $(TRIMDIR)/$$(basename $$f|sed 's/_sequence.txt.gz/_2_sequence.fq.gz/g'); \
	done

spades: $(SPADESDIR) $(CONTIGSDIR) $(CONTIGSSTATSDIR)
	for f in $$(find $(TRIMDIR) -type f \( -name '*1_sequence.fq.gz' -o -name '*2_sequence.fq.gz' \)|sed 's/_[1-2]_sequence/_sequence/g'|sort|uniq -d); do \
	  $(SPADES) -k $(SPADESKMERS) --only-assembler --careful -t $(SPADESTHREADS) -1 $$(echo $$f|sed 's/_sequence/_1_sequence/g') -2 $$(echo $$f|sed 's/_sequence/_2_sequence/g') -o $(SPADESDIR)/$$(basename $$f .fq.gz); \
	  mkdir -p $(CONTIGSDIR)/$$(basename $$f .fq.gz); \
	  cat $(SPADESDIR)/$$(basename $$f .fq.gz)/contigs.fasta | \
	  $(SRCDIR)/filter_contigs --length 1000 - | \
	  $(SRCDIR)/rename_contigs --prefix contigs_ - > $(CONTIGSDIR)/$$(basename $$f .fq.gz)/contigs.fna; \
	  $(SRCDIR)/assembly_stats $(CONTIGSDIR)/$$(basename $$f .fq.gz)/contigs.fna $$(interleave_pairs $$(echo $$f|sed 's/_sequence/_1_sequence/g') $$(echo $$f|sed 's/_sequence/_2_sequence/g') | count_seqs | awk '{print $2}') > $(CONTIGSSTATSDIR)/$$(basename $$f .fq.gz).tsv;\
	done

masurca: $(MASURCADIR) $(CONTIGSDIR)
	for f in $$(find $(TRIMDIR) -type f \( -name '*1_sequence.fq.gz' -o -name '*2_sequence.fq.gz' \)|sed 's/_[1-2]_sequence/_sequence/g'|sort|uniq -d); do \
	  mkdir -p $(MASURCADIR)/$$(basename $$f .fq.gz); \
	  echo -e "DATA\nPE= pe $(INSERTSIZEMEAN) $(INSERTSIZESTD) $$(echo $$f|sed 's/_sequence/_1_sequence/g') $$(echo $$f|sed 's/_sequence/_2_sequence/g')\nEND" > $(MASURCADIR)/$$(basename $$f .fq.gz)/config.txt; \
	  echo -e "PARAMETERS\nGRAPH_KMER_SIZE = auto\nUSE_LINKING_MATES = 1\nCA_PARAMETERS = cgwErrorRate=0.25 ovlMemory=4GB\nKMER_COUNT_THRESHOLD = 2" >> $(MASURCADIR)/$$(basename $$f .fq.gz)/config.txt; \
	  echo -e "NUM_THREADS = $(MASURCATHREADS)\nJF_SIZE = 2000000000\nEND" >> $(MASURCADIR)/$$(basename $$f .fq.gz)/config.txt; \
	done
	for f in $$(find $(TRIMDIR) -type f \( -name '*1_sequence.fq.gz' -o -name '*2_sequence.fq.gz' \)|sed 's/_[1-2]_sequence/_sequence/g'|sort|uniq -d); do \
	  cd $(MASURCADIR)/$$(basename $$f .fq.gz); \
	  $(MASURCA) config.txt; \
	  bash assemble.sh; \
	  cd $(CURDIR); \
	done

.PHONY: fastqc interleave spades masurca
