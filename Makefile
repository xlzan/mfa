# 
# Parameters
#
MAKEFILE = Makefile
exe = mfa_prog 
#mpi fcomp = mpif90 -f90=ifort 
fcomp = ifort 

# -fpp: Calls first to the C Preprocessor
#  --- Information ---  
# INTEL to cpp : -fpp 
#flags =  -fpp -O2 -i-static   -vec-report0  

flags = -fpp # -vec-report0    # -fpe0: stops prog after first fp exception
# -xP : Goegrid (xeones)
#  sol02: -axT (core 2 duos)
#  sheldon: -axW
#  core 2 duo -axT
#flags+=  -O3 -i-static  -align all -ip  # optimization
#flags+=  -O3  -align all -ip -I/share/apps/fftw/fftw-3.3.4_intel10/include  # optimization
cflags= -lfftw3 -lm -L/share/apps/fftw/fftw-3.3.4_intel10/lib 
#flags+=  -warn unused
#
flags+= -check bounds  -g #-traceback
#flags+=     -pg # profiling
ref_dir = REF # reference directory for patching

# This forces execution of this rules, no matters the time in the files        
.PHONY: all change_dpd_weight 

# Objects 
#
OBJS = mfa_common.o \
      functions.o \
      util.o \
      ziggurat.o \
      md_main.o     \
      init_system.o \
	  chain_fftw.o \
	  fix_CM.o \
	  fix_force_CM.o\
	  ring_net_force.o\
      gen_droplet.o \
      gen_brush.o \
      gen_wall.o \
      gen_chain.o \
      gen_ring.o \
      make_binning_boxes.o \
      new_dpd_fd.o \
      init_force_switch_on.o \
      geom_constraint.o \
      verlet_positions.o \
      verlet_velocities.o \
      init_params.o  \
      init_config.o  \
      conf_default.o \
      init_obser.o  \
      fluid_fluid.o  \
      fluid_wall.o  \
      intra_molec.o  \
      observation.o  \
      obser_out.o   \
      store_config.o \
      binning.o  \
      check_skin.o  \
      INR250.o  \
      SUN.o  \
      R250.o \
      constant_force.o \
      messages.o \
      dpd_forces.o \
      ewald_real.o \
      ewald_k.o \
      dipolar_correction.o \
	  lgv_forces.o \
      my_binning.o \
      wall_time.o \
      bond_distance.o \
      bending.o \
      orientation.o \
	  external_force.o

#obsoleted       fluid_fluid_test.o  
#obsoleted       corrector.o   
#obsoleted       predict.o     
#obsoleted      dpd_forces_ll.o 
#obsoleted      thermostat.o
#obsoleted      layer_velocities.o \

.SUFFIXES:            # this deletes the default suffixes 
.SUFFIXES: .f90 .o    # this defines the extensions I want 

# Actions

.f90.o:  
	$(fcomp)  $(flags) -c $< 
        

$(exe):  $(OBJS) Makefile control_simulation.h wall_time.o
	$(fcomp) $(flags) -o $(exe) $(OBJS)  $(cflags)

# ALL for the study of thermostats all: mfa_poiss mfa_poiss_prof mfa_cou mfa_cou_prof mfa_cou_dpd_gs mfa_cou_dpd_bs mfa_cou_lgv_gs \
# ALL for the study of thermostats mfa_cou_lgv_bs mfa_cou_lgv_bs_gx0 mfa_cou_lgv_gs_gx0
#
#
# Dependencies of the object files 
#
mfa_common.o: control_simulation.h Makefile
md_main.o : md_main.f90 mfa_common.o control_simulation.h 
init_params.o : init_params.f90 mfa_common.o control_simulation.h
init_config.o : init_config.f90 mfa_common.o control_simulation.h 
conf_default.o : conf_default.f90 mfa_common.o control_simulation.h
init_obser.o : init_obser.f90 mfa_common.o functions.o control_simulation.h
predict.o : predict.f90 mfa_common.o
fluid_fluid.o : fluid_fluid.f90 ewald_real.o dpd_forces.o mfa_common.o control_simulation.h
fluid_fluid_test.o : fluid_fluid_test.f90 mfa_common.o control_simulation.h
wall_wall.o : wall_wall.f90 mfa_common.o
init_force_switch_on.o: init_force_switch_on.f90 mfa_common.o
fluid_wall.o : fluid_wall.f90 mfa_common.o control_simulation.h
geom_constraint.o: geom_constraint.f90
intra_molec.o : intra_molec.f90 mfa_common.o control_simulation.h
intra_wall.o : intra_wall.f90 mfa_common.o
#thermostat.o : thermostat.f90 mfa_common.o
#layer_velocities.o : layer_velocities.f90 mfa_common.o
corrector.o : corrector.f90 mfa_common.o
observation.o : observation.f90 mfa_common.o control_simulation.h
obser_out.o : obser_out.f90 mfa_common.o util.o functions.o control_simulation.h
store_config.o : store_config.f90 mfa_common.o control_simulation.h
binning.o : binning.f90 mfa_common.o control_simulation.h
check_skin.o : check_skin.f90 mfa_common.o
INR250.o : INR250.f90
SUN.o : SUN.f90
R250.o : R250.f90
functions.o: mfa_common.o functions.f90  control_simulation.h
constant_force.o:  mfa_common.o control_simulation.h
util.o: mfa_common.o
dpd_forces_ll.o: dpd_forces_ll.f90 mfa_common.o ziggurat.o ziggurat.mod control_simulation.h
ziggurat.o: ziggurat.f90 
init_system.o : init_system.f90 mfa_common.o control_simulation.h
chain_fttw.o : chain_fftw.f90 mfa_common.o
fix_CM.o : fix_CM.f90 mfa_common.o
fix_VCM.o : fix_VCM.f90 mfa_common.o
fix_force_CM.o : fix_force_CM.f90 mfa_common.o
ring_net_force.o : ring_net_force.f90 mfa_common.o
gen_droplet.o: mfa_common.o control_simulation.h
gen_brush.o: mfa_common.o util.o 
gen_wall.o: mfa_common.o util.o
gen_chain.o: gen_chain.f90 mfa_common.o ziggurat.o
gen_ring.o: gen_ring.f90 mfa_common.o ziggurat.o
make_binning_boxes.o : make_binning_boxes.f90 mfa_common.o
dpd_forces.o: dpd_forces.f90 mfa_common.o ziggurat.o control_simulation.h
new_dpd_fd.o: mfa_common.o 
verlet_positions.o: mfa_common.o 
verlet_velocities.o: mfa_common.o control_simulation.h
predict.o: mfa_common.o  
messages.o: messages.f90 mfa_common.o control_simulation.h
ewald_real.o: ewald_real.f90 mfa_common.o control_simulation.h 
ewald_k.o   : ewald_k.f90 mfa_common.o control_simulation.h   
dipolar_correction.o: dipolar_correction.f90  mfa_common.o control_simulation.h
lgv_forces.o: lgv_forces.f90 mfa_common.o control_simulation.h
my_binning.o: my_binning.f90 mfa_common.o control_simulation.h
bond_distance.o: mfa_common.o

wall_time.o : wall_time.c
	gcc -c wall_time.c

clean:
	rm -f *.o *.mod	


package: 
	tar -cvf mfa_prog.tar Makefile *.f90 control_simulation.h  system_input mfa_input wall_time.c
	@gzip -f mfa_prog.tar
	@echo "***** Program packaged in mfa_prog.tar.gz  *****"
           
patch: 
	$(MAKE) package
	if [ -d ./current ] ; then  rm -rf ./current ;  fi ; \
mkdir ./current ; \
cd ./current ; tar -zxvf ../mfa_prog.tar.gz ; cd ../
	diff -Naur ./$(ref_dir) ./current > mfa_prog.patch

