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

Copyright
---------

Copyright (C) <2015> EMBL-European Bioinformatics Institute

This program is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the   
GNU General Public License for more details.

Neither the institution name nor the name reads2genome
can be used to endorse or promote products derived from
this software without prior written permission.
For written permission, please contact <marco@ebi.ac.uk>.

Products derived from this software may not be called reads2genome
nor may reads2genome appear in their names without prior written
permission of the developers. You should have received a copy
of the GNU General Public License along with this program.
If not, see <http://www.gnu.org/licenses/>.
