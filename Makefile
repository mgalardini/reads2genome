# Organism details
GENUS = Escherichia
SPECIES = coli
STRAIN = k12

# Input files
READ1 = READ1.txt.gz
READ2 = READ2.txt.gz

# Directories and parameters
FASTQC = $(SOFTDIR)FastQC/fastqc 
SPADES = $(SOFTDIR)SPAdes-3.1.1-Linux/bin/spades.py
SPADESTHREADS = 16
SPADESKMERS = 21,33,55,77,99,127
MASURCA = $(SOFTDIR)MaSuRCA-2.3.2/bin/masurca
MASURCATHREADS = 16
INSERTSIZEMEAN = 390 
INSERTSIZESTD = 59
PROKKA = $(SOFTDIR)prokka-1.10/bin/prokka
PROKKATHREADS = 16

# Anything below this point should be changed

# Directories
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

CONTIGSANNOTATIONDIR = $(CURDIR)/contigs-annotation
$(CONTIGSANNOTATIONDIR):
	mkdir -p $(CONTIGSANNOTATIONDIR)

# QC
QCREAD1 = $(QCDIR)/$(addsuffix _fastqc.zip, $(basename $(notdir $(READ1)) .txt))
QCREAD2 = $(QCDIR)/$(addsuffix _fastqc.zip, $(basename $(notdir $(READ2)) .txt))

$(QCREAD1): $(QCDIR) $(READ1)
	$(FASTQC) --outdir $(QCDIR) $(READ1)
$(QCREAD2): $(QCDIR) $(READ2)
	$(FASTQC) --outdir $(QCDIR) $(READ2)
fastqc: $(QCREAD1) $(QCREAD2)

# Trimming
TREAD1 = $(addsuffix .fq.gz, $(TRIMDIR)/$(basename $(notdir $(READ1)) .txt))
TREAD2 = $(addsuffix .fq.gz, $(TRIMDIR)/$(basename $(notdir $(READ2)) .txt))

$(TREAD1): $(TRIMDIR) $(READ1) $(READ2)
	interleave_pairs $(READ1) $(READ2) | \
	trim_edges -l 9 --paired_reads | \
	trim_quality -q 20 -w 5 --paired_reads | \
	deinterleave_pairs -z -o $(TREAD1) $(TREAD2)
trim: $(TREAD1)

# Assembly
CONTIGS = $(CONTIGSDIR)/$(STRAIN)/contigs.fna

$(CONTIGS): $(SPADESDIR) $(CONTIGSDIR) $(CONTIGSSTATSDIR) $(READ1) $(READ2)
	$(SPADES) -k $(SPADESKMERS) --only-assembler --careful -t $(SPADESTHREADS) -1 $(READ1) -2 $(READ2) -o $(SPADESDIR)/$(STRAIN)
	mkdir -p $(CONTIGSDIR)/$(STRAIN)
	cat $(SPADESDIR)/$(STRAIN)/contigs.fasta | \
	$(SRCDIR)/filter_contigs --length 1000 - | \
	$(SRCDIR)/rename_contigs --prefix contigs_ - > $(CONTIGS)
spades: $(CONTIGS)

CONTIGSMASURCA = $(CONTIGSDIR)/$(STRAIN)/contigs.masurca.fna

$(CONTIGSMASURCA): $(MASURCADIR) $(CONTIGSDIR) $(CONTIGSSTATSDIR) $(READ1) $(READ2)
	mkdir -p $(MASURCADIR)/$(STRAIN) 
	echo -e "DATA\nPE= pe $(INSERTSIZEMEAN) $(INSERTSIZESTD) $(READ1) $(READ2)\nEND" > $(MASURCADIR)/$(STRAIN)/config.txt
	echo -e "PARAMETERS\nGRAPH_KMER_SIZE = auto\nUSE_LINKING_MATES = 1\nCA_PARAMETERS = cgwErrorRate=0.25 ovlMemory=4GB\nKMER_COUNT_THRESHOLD = 2" >> $(MASURCADIR)/$(STRAIN)/config.txt
	echo -e "NUM_THREADS = $(MASURCATHREADS)\nJF_SIZE = 2000000000\nEND" >> $(MASURCADIR)/$(STRAIN)/config.txt
	cd $(MASURCADIR)/$(STRAIN); \
	$(MASURCA) config.txt; \
	bash assemble.sh; \
	cd $(CURDIR)
	mkdir -p $(CONTIGSDIR)/$(STRAIN)
	cat $(MASURCADIR)/$(STRAIN)/CA/10-gapclose/genome.ctg.fasta | \
	$(SRCDIR)/filter_contigs --length 1000 - | \
	$(SRCDIR)/rename_contigs --prefix contigs_ - > $(CONTIGSMASURCA)
masurca: $(CONTIGSMASURCA)
 
# Annotate
GBK = $(CONTIGSANNOTATIONDIR)/$(STRAIN)/$(STRAIN).gbk

$(GBK): $(CONTIGSANNOTATIONDIR) $(CONTIGS) $(READ1) $(READ2)
	$(PROKKA) --cpus $(PROKKATHREADS) --outdir $(CONTIGSANNOTATIONDIR)/$(STRAIN) --force --genus $(GENUS) --species $(SPECIES) --strain $(STRAIN) --prefix $(STRAIN) --compliant --rfam --locustag $(STRAIN) $(CONTIGS)
	$(SRCDIR)/annotation_stats $(GBK) $(STRAIN) --sequencing $$(interleave_pairs $(READ1) $(READ2) | count_seqs | awk '{print $$2}') > $(CONTIGSSTATSDIR)/$(STRAIN).tsv
annotate: $(GBK)

GBKMASURCA = $(CONTIGSANNOTATIONDIR)/$(STRAIN).masurca/$(STRAIN).gbk

$(GBKMASURCA): $(CONTIGSANNOTATIONDIR) $(CONTIGSMASURCA) $(READ1) $(READ2)
	$(PROKKA) --cpus $(PROKKATHREADS) --outdir $(CONTIGSANNOTATIONDIR)/$(STRAIN).masurca --force --genus $(GENUS) --species $(SPECIES) --strain $(STRAIN) --prefix $(STRAIN) --compliant --rfam --locustag $(STRAIN) $(CONTIGSMASURCA)
	$(SRCDIR)/annotation_stats $(GBKMASURCA) $(STRAIN) --sequencing $$(interleave_pairs $(READ1) $(READ2) | count_seqs | awk '{print $$2}') > $(CONTIGSSTATSDIR)/$(STRAIN).masurca.tsv
annotatemasurca: $(GBKMASURCA)

all: fastqc trim spades annotate
allmasurca: fastqc trim masurca annotatemasurca

.PHONY: all allmasurca fastqc trim spades masurca annotate annotatemasurca
