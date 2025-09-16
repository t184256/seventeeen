ERGOGEN_FOOTPRINTS ?= ergogen-select-footprints
ERGOGEN ?= ergogen
KICAD_CLI ?= kicad-cli
DIFF ?= diff
SED ?= sed
P7ZIP ?= 7z
STRIP_NONDETERMINISM ?= strip-nondeterminism
TMPDIR ?= $(XDG_RUNTIME_DIR)/tmp-seventeeen
DESTDIR ?= out

install: all

ergogen/footprints/ceoloide:
	@mkdir -p ergogen/footprints
	cp --no-preserve=mode -rv \
	   $(ERGOGEN_FOOTPRINTS) ergogen/footprints/ceoloide

TARGETS = $(DESTDIR)/pcbs/seventeeen.kicad_pcb
$(DESTDIR)/pcbs/seventeeen.kicad_pcb: ergogen/footprints/ceoloide
$(DESTDIR)/pcbs/seventeeen.kicad_pcb: ergogen/config.yaml
	@mkdir -p $(DESTDIR)
	$(ERGOGEN) ergogen/ -o $(DESTDIR)
	$(SED) -E \
	  -e 's|date \"2[0-9]{3}-[0-9]{2}-[0-9]{2}\"|date "2025-01-01"|g' \
	  -i $@

DRC = $(DESTDIR)/drc.rpt
TARGETS += $(DRC)
$(DRC): $(DESTDIR)/pcbs/seventeeen.kicad_pcb expected.drc.rpt
	@rm -rf $(DESTDIR)/drc-tmp
	@mkdir -p $(DESTDIR) $(DESTDIR)/drc-tmp
	HOME=$$(realpath $(TMPDIR)) $(KICAD_CLI) pcb drc \
	  --severity-error --output $(DESTDIR)/drc-tmp/initial.drc.rpt $<
	$(SED) -E -e '/^\*\*/d' -e '/^$$/d' \
	  < $(DESTDIR)/drc-tmp/initial.drc.rpt \
	  > $(DESTDIR)/drc-tmp/cleaned.drc.rpt
	csplit -n5 -f $(DESTDIR)/drc-tmp/split \
	  $(DESTDIR)/drc-tmp/cleaned.drc.rpt '/^\[.*\]:/' '{*}' > /dev/null
	for f in $(DESTDIR)/drc-tmp/split*; do \
	  head -n1 $$f > $$f.sorted; \
	  tail -n-2 $$f | sort >> $$f.sorted; \
	done
	cat $(DESTDIR)/drc-tmp/split*.sorted | \
	  $(SED) -z 's/\n    / | /g' | \
	  sort > $@.differs
	$(DIFF) -U0 $@.differs expected.drc.rpt
	@mv $@.differs $@
	@rm -r $(DESTDIR)/drc-tmp

ONE_DRILL = $(DESTDIR)/fab/kicad-PTH.drl
OTHER_DRILLS = $(DESTDIR)/fab/kicad-NPTH.drl
OTHER_DRILLS += $(DESTDIR)/fab/kicad-PTH-drl_map.gbr
OTHER_DRILLS += $(DESTDIR)/fab/kicad-NPTH-drl_map.gbr
DRILLS = $(ONE_DRILL) $(OTHER_DRILLS)
TARGETS += $(DRILLS)
SOME_GUID = 73657665-6e74-4656-9565-6e2e6b696361
SOME_ID = %TF.ProjectId,seventeeen,$(SOME_GUID),v1.0.0*%
$(OTHER_DRILLS): $(ONE_DRILL)
	@:
$(ONE_DRILL): $(DESTDIR)/pcbs/seventeeen.kicad_pcb $(DRC)
	@rm -rf $(DESTDIR)/tmp-drill
	@mkdir -p $(DESTDIR)/tmp-drill $(DESTDIR)/fab
	HOME=$$(realpath $(TMPDIR)) $(KICAD_CLI) pcb export drill \
	  --format=excellon --drill-origin=absolute --excellon-units=mm \
	  --excellon-zeros-format=decimal --excellon-oval-format=alternate \
	  --excellon-separate-th --generate-map --map-format=gerberx2 \
	  --output=$(DESTDIR)/tmp-drill \
	  $<
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-drill/seventeeen-PTH-drl_map.gbr
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-drill/seventeeen-NPTH-drl_map.gbr
	$(SED) -E \
	  -e 's|2[0-9]{3}-[0-9]{2}-[0-9]{2}([T ])[0-9]{2}:[0-9]{2}:[0-9]{2}|2025-01-01\100:00:00|g' \
	  -e 's|2025-01-01([T ])00:00:00\+02(:?)00|2025-01-01\100:00:00+00\200|g' \
	  -i $(DESTDIR)/tmp-drill/*-drl_map.gbr $(DESTDIR)/tmp-drill/*.drl
	## stop renaming
	cat $(DESTDIR)/tmp-drill/seventeeen-NPTH.drl > $(DESTDIR)/fab/kicad-NPTH.drl
	cat $(DESTDIR)/tmp-drill/seventeeen-PTH-drl_map.gbr > $(DESTDIR)/fab/kicad-PTH-drl_map.gbr
	cat $(DESTDIR)/tmp-drill/seventeeen-NPTH-drl_map.gbr > $(DESTDIR)/fab/kicad-NPTH-drl_map.gbr
	cat $(DESTDIR)/tmp-drill/seventeeen-PTH.drl > $@  # last
	@rm -rf $(DESTDIR)/tmp-drill

ONE_GERBER = $(DESTDIR)/fab/kicad-F_Cu.gtl
OTHER_GERBERS = $(DESTDIR)/fab/kicad-B_Cu.gbl
OTHER_GERBERS += $(DESTDIR)/fab/kicad-F_Mask.gts
OTHER_GERBERS += $(DESTDIR)/fab/kicad-B_Mask.gbs
OTHER_GERBERS += $(DESTDIR)/fab/kicad-F_Paste.gtp
OTHER_GERBERS += $(DESTDIR)/fab/kicad-B_Paste.gbp
OTHER_GERBERS += $(DESTDIR)/fab/kicad-F_Silkscreen.gto
OTHER_GERBERS += $(DESTDIR)/fab/kicad-B_Silkscreen.gbo
OTHER_GERBERS += $(DESTDIR)/fab/kicad-Edge_Cuts.gm1
OTHER_GERBERS += $(DESTDIR)/fab/kicad-job.gbrjob
GERBERS = $(ONE_GERBER) $(OTHER_GERBERS)
TARGETS += $(GERBERS)
$(OTHER_GERBERS): $(ONE_GERBER)
	@:
$(ONE_GERBER): $(DESTDIR)/pcbs/seventeeen.kicad_pcb $(DRC)
	@rm -rf $(DESTDIR)/tmp-grb
	@mkdir -p $(DESTDIR)/tmp-grb $(DESTDIR)/fab
	HOME=$$(realpath $(TMPDIR)) $(KICAD_CLI) pcb export gerbers \
	  --layers B.Cu,B.Paste,B.SilkS,B.Mask,F.Mask,F.SilkS,F.Paste,F.Cu,Edge.Cuts \
	  --output=$(DESTDIR)/tmp-grb \
	  $<
	ls $(DESTDIR)/tmp-grb
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-F_Cu.gtl
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-B_Cu.gbl
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-F_Mask.gts
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-B_Mask.gbs
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-F_Paste.gtp
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-B_Paste.gbp
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-F_Silkscreen.gto
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-B_Silkscreen.gbo
	grep -Fx $(SOME_ID) $(DESTDIR)/tmp-grb/seventeeen-Edge_Cuts.gm1
	grep -F $(SOME_GUID) $(DESTDIR)/tmp-grb/seventeeen-job.gbrjob
	$(SED) -E \
	  -e 's|2[0-9]{3}-[0-9]{2}-[0-9]{2}([T ])[0-9]{2}:[0-9]{2}:[0-9]{2}|2025-01-01\100:00:00|g' \
	  -e 's|2025-01-01([T ])00:00:00\+02(:?)00|2025-01-01\100:00:00+00\200|g' \
	  -i $(DESTDIR)/tmp-grb/*
	## stop renaming
	cat $(DESTDIR)/tmp-grb/seventeeen-B_Cu.gbl > $(DESTDIR)/fab/kicad-B_Cu.gbl
	cat $(DESTDIR)/tmp-grb/seventeeen-F_Mask.gts > $(DESTDIR)/fab/kicad-F_Mask.gts
	cat $(DESTDIR)/tmp-grb/seventeeen-B_Mask.gbs > $(DESTDIR)/fab/kicad-B_Mask.gbs
	cat $(DESTDIR)/tmp-grb/seventeeen-F_Paste.gtp > $(DESTDIR)/fab/kicad-F_Paste.gtp
	cat $(DESTDIR)/tmp-grb/seventeeen-B_Paste.gbp > $(DESTDIR)/fab/kicad-B_Paste.gbp
	cat $(DESTDIR)/tmp-grb/seventeeen-F_Silkscreen.gto > $(DESTDIR)/fab/kicad-F_Silkscreen.gto
	cat $(DESTDIR)/tmp-grb/seventeeen-B_Silkscreen.gbo > $(DESTDIR)/fab/kicad-B_Silkscreen.gbo
	cat $(DESTDIR)/tmp-grb/seventeeen-Edge_Cuts.gm1 > $(DESTDIR)/fab/kicad-Edge_Cuts.gm1
	cat $(DESTDIR)/tmp-grb/seventeeen-job.gbrjob > $(DESTDIR)/fab/kicad-job.gbrjob
	cat $(DESTDIR)/tmp-grb/seventeeen-F_Cu.gtl > $@  # last
	@rm -rf $(DESTDIR)/tmp-grb

TARGETS += $(DESTDIR)/fab.zip
$(DESTDIR)/fab.zip: $(GERBERS) $(DRILLS) $(DRC)
	@rm -f $@
	@mkdir -p $(DESTDIR)/tmp-fab
	cp $(GERBERS) $(DRILLS) $(DESTDIR)/tmp-fab/
	TZ=UTC touch --no-dereference --date=2025-01-01 $(DESTDIR)/tmp-fab/*
	pushd $(DESTDIR)/tmp-fab && $(P7ZIP) a ../fab.zip * && popd
	$(STRIP_NONDETERMINISM) $@
	@rm -rf $(DESTDIR)/tmp-fab

TARGETS += $(DESTDIR)/previews/front.svg $(DESTDIR)/previews/back.svg
SVG_OPTS ?= --exclude-drawing-sheet --fit-page-to-board
$(DESTDIR)/previews/front.svg: $(DESTDIR)/pcbs/seventeeen.kicad_pcb
	@mkdir -p $(DESTDIR)/previews $(TMPDIR)
	HOME=$$(realpath $(TMPDIR)) $(KICAD_CLI) pcb export svg \
	  --output $@.tmp $< \
	  $(SVG_OPTS) \
	  -l User.Drawings,B.Cu,B.Paste,B.SilkS,B.Mask,F.Mask,F.SilkS,F.Paste,F.Cu,Edge.Cuts
	$(SED) -E \
	  -e 's|2[0-9]{3}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}|2025/01/01 100:00:00|g' \
	  -i $@.tmp
	$(SED) 's/<svg/<svg style="background-color: #070809"/' < $@.tmp > $@
	rm $@.tmp
$(DESTDIR)/previews/back.svg: $(DESTDIR)/pcbs/seventeeen.kicad_pcb
	mkdir -p $(DESTDIR)/previews $(TMPDIR)
	HOME=$$(realpath $(TMPDIR)) $(KICAD_CLI) pcb export svg \
	  --output $@.tmp $< \
	  $(SVG_OPTS) --mirror \
	  -l User.Drawings,F.Cu,F.Paste,F.SilkS,F.Mask,B.Mask,B.SilkS,B.Paste,B.Cu,Edge.Cuts
	$(SED) -E \
	  -e 's|2[0-9]{3}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}|2025/01/01 00:00:00|g' \
	  -i $@.tmp
	$(SED) 's/<svg/<svg style="background-color: #000000"/' < $@.tmp > $@
	rm $@.tmp

all: $(TARGETS)
.PHONY: clean
clean:
	rm -rf ergogen/footprints $(DESTDIR) result $(TMPDIR)
