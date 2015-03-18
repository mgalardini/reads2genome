reads2genome
============

From second generation sequencing reads to annotated bacterial genome

Usage
-----

There are two assemblers available: Spades or MasurCA

* `make all` (spades)
* `make allmasurca` (masurca)

Notes
-----

* You may want to run `make fastqc` first and use its results to tweak the trimming parameters
* More than one genome can be assembled in this directory, by changing the strain and reads name at the top of the Makefile
