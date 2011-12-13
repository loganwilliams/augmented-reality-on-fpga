PROJECT = memory_interface
SRCS = dummy_zbt.v ../vga_write.v tb5.v 
SIMDIR = sim

# iverilog
IVC = iverilog
IVCFLAGS  = 
 
# vvp
VVP = vvp
VVPFLAGS = -n 
 
# vvp dump type
DUMPTYPE = vcd
 
# wave form viewer
WAVEFORM_VIEWER = gtkwave
WAVEFORM_VIEWER_OPTIONS = 

############################################################################### 
 
all: compile simulate view
 
compile:
	$(IVC) $(IVCFLAGS) -o $(SIMDIR)/$(PROJECT).vvp $(SRCS)

simulate:
	$(VVP) $(VVPFLAGS) $(SIMDIR)/$(PROJECT).vvp -$(DUMPTYPE)
	mv dump.$(DUMPTYPE) $(SIMDIR)/$(PROJECT).$(DUMPTYPE)

view: 
	$(WAVEFORM_VIEWER) $(WAVEFORM_VIEWER_OPTIONS) $(SIMDIR)/$(PROJECT).$(DUMPTYPE) 
 
clean:
	rm -f $(SIMDIR)/$(PROJECT).vvp $(SIMDIR)/$(PROJECT).$(DUMPTYPE)

