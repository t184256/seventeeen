ERGOGEN_FOOTPRINTS ?= ergogen-select-footprints
ERGOGEN ?= ergogen
KICAD_CLI ?= kicad-cli
SED ?= sed
TMPDIR ?= $(XDG_RUNTIME_DIR)/tmp-seventeeen
DESTDIR ?= out

TARGETS = $(DESTDIR)/pcbs/seventeeen.kicad_pcb
TARGETS += $(DESTDIR)/previews/front.svg $(DESTDIR)/previews/back.svg
all: $(TARGETS)
install: $(TARGETS)
.PHONY: clean
clean:
	rm -rf ergogen/footprints $(DESTDIR) result $(TMPDIR)

ergogen/footprints/ceoloide:
	mkdir -p ergogen/footprints
	cp --no-preserve=mode -rv \
	   $(ERGOGEN_FOOTPRINTS) ergogen/footprints/ceoloide

$(DESTDIR)/pcbs/seventeeen.kicad_pcb: ergogen/footprints/ceoloide
$(DESTDIR)/pcbs/seventeeen.kicad_pcb: ergogen/config.yaml
	mkdir -p $(DESTDIR)
	$(ERGOGEN) ergogen/ -o $(DESTDIR)
	$(SED) -E \
	  -e 's|date \"2[0-9]{3}-[0-9]{2}-[0-9]{2}\"|date "2025-01-01"|g' \
	  -i $@

SVG_OPTS ?= --exclude-drawing-sheet --fit-page-to-board
$(DESTDIR)/previews/front.svg: $(DESTDIR)/pcbs/seventeeen.kicad_pcb
	mkdir -p $(DESTDIR)/previews $(TMPDIR)
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
