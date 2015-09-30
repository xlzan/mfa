subroutine verlet_positions()
#include "control_simulation.h"
!  This is the first step velocity verlet 
!  
! * Updates coordinates 
! * Velocity to t + 0.5*dt 
use commons
!use util, only: write_conf
!use util ! only for generating the histogram, remove when not debugging
!use ziggurat !gaussian random generator used
!use util
      implicit none
      real (kind=8), pointer :: r_head(:,:) !(from predict.f90)
      real (kind=8) :: rr_dummy(3)
      logical, parameter :: debug=.false.

!! NOTE: now the head velocities are correctly set up in the velocity upgrade, so that
!       the positions will be updated here in the usual VV procedure
! If not explicit wall atoms, the brushes heads are fixed in r0 init 
!
! Remember the head positions before updating  r0
! if(.not.f_explicit_wall.and.n_chain>0) then
!claudio 
! -- Remember initial coordinates for brushes heads

! r_head_old(:,:) = r0(:,1:n_mon*n_chain:n_mon)
! -- Take the heads coor which are not integrated
!     r_head => r0(:,1:n_chain*n_mon:n_mon)
! end if      


#       ifdef SHEARED

    if(i_time.eq.1) then
        do i_dim = 1, n_dim
            appl_vel(i_dim)=va_spring_twall(i_dim)

            if(f_twall(i_dim).eq.0.or.f_twall(i_dim).eq.9) then
                appl_vel(i_dim)=0.
                appl_vel_tw(i_dim)=0.
                appl_vel_bw(i_dim)=0.
            end if
    
        end do 
    end if
    
    do i_dim = 1, n_dim
        if(f_twall(i_dim).eq.0.and.i_time.eq.turn_time(i_dim)) then
            appl_vel(i_dim)=va_spring_twall(i_dim)
            write(*,*) "applying velocity at time step",i_time
        end if
        if(f_twall(i_dim).eq.2) then
            if(i_time.eq.turn_time(i_dim)) then
                appl_vel(i_dim)=- va_spring_twall(i_dim)
                write(*,*) "shear direction inverted at time step",i_time
            end if
        end if
        if(f_twall(i_dim).eq.3) then

            if(i_time.eq.turn_time(i_dim)/2) then
                appl_vel(i_dim)=- va_spring_twall(i_dim)
                write(*,*) "shear direction inverted at time step",i_time
            end if
            if(mod(i_time+turn_time(i_dim)/2,turn_time(i_dim)).eq.0.and.i_time.gt.turn_time(i_dim)/2) then
                appl_vel(i_dim)=-appl_vel(i_dim)
                write(*,*) "shear direction inverted at time step",i_time
            end if
        end if


        if(i_time.eq.turn_time(i_dim)) then
            if(f_twall(i_dim).eq.4) then
                appl_vel(i_dim)=0.
                write(*,*) "motion stopped at time step",turn_time(i_dim)
            end if
        end if

        if(f_twall(i_dim).eq.5) then
            appl_vel(i_dim)=va_spring_twall(i_dim)*cos(2*pi*i_time/turn_time(i_dim))

            if(mod(i_time,turn_time(i_dim)).eq.0) then
                write(*,*) "new period at time step",i_time
            end if
        end if


        if(f_twall(i_dim).eq.6) then
            if(i_time.lt.p_time+turn_time(i_dim)) then
                appl_vel(i_dim)=va_spring_twall(i_dim)*(1-cos(pi*(i_time-p_time)/turn_time(i_dim)))/2
            end if
            if(i_time.ge.(p_time+turn_time(i_dim))) then
                appl_vel(i_dim)=va_spring_twall(i_dim)
            end if
            if(i_time.lt.p_time) then
                appl_vel(i_dim)=0.0
            end if
            if(i_time.eq.p_time) write(*,*) "starting motion at timestep",i_time
            if(i_time.eq.(p_time+turn_time(i_dim)))  write(*,*) "final velocity reached at timestep",i_time
        end if

        if(f_twall(i_dim).eq.7) then
            if(i_time.lt.(p_time+turn_time(i_dim))) then
                appl_vel(i_dim)=va_spring_twall(i_dim)*cos(pi*(i_time-p_time)/turn_time(i_dim))
            end if
            if(i_time.ge.(p_time+turn_time(i_dim))) then
                appl_vel(i_dim)=-va_spring_twall(i_dim)
            end if
            if(i_time.lt.p_time) then
                appl_vel(i_dim)=va_spring_twall(i_dim)
            end if
            if(i_time.eq.p_time) write(*,*) "starting inversion at timestep",i_time
            if(i_time.eq.(p_time+turn_time(i_dim)))  write(*,*) "inversion performed at timestep",i_time
        end if


        if(f_twall(i_dim).eq.8) then
            if(i_time.lt.(p_time+turn_time(i_dim))) then
                appl_vel(i_dim)=va_spring_twall(i_dim)*(cos(pi*(i_time-p_time)/turn_time(i_dim))+1)/2
            end if
            if(i_time.ge.(p_time+turn_time(i_dim))) then
                appl_vel(i_dim)=0.0
            end if
            if(i_time.lt.p_time) then
                appl_vel(i_dim)=va_spring_twall(i_dim)
            end if
            if(i_time.eq.p_time) write(*,*) "stopping motion at timestep",i_time
            if(i_time.eq.(p_time+turn_time(i_dim)))  write(*,*) "stop performed at timestep",i_time
        end if

        if(f_twall(i_dim).eq.9) then
            appl_vel_bw(i_dim)=0.5*dt_2*(fbw(i_dim)/(0.5*n_wall)+va_spring_twall(i_dim))/mass(n_part)
            appl_vel_tw(i_dim)=0.5*dt_2*(ftw(i_dim)/(0.5*n_wall)-va_spring_twall(i_dim))/mass(n_part)

            !shiftfactor for external force

            shifttw(i_dim)=appl_vel_tw(i_dim) + appl_acc_tw(i_dim)
            shiftbw(i_dim)=appl_vel_bw(i_dim) + appl_acc_bw(i_dim)

        end if

    end do 
#   endif 
!endif sheared

! ----- Update positions with Velocity Verlet 
    do i_part = 1 , n_mon_tot

#       if PINNED==1 
        if (i_part.eq.part_init_d+1) cycle   !excluding particle 3 and particle 4 from
        !thermostatisation, in case without spring
        if (i_part.eq.part_init_e+1) cycle
#       endif

        r0(:,i_part) = r0(:,i_part) + dt*v(:,i_part) + 0.5*dt_2*a(:,i_part) 
!       r0(1,i_part) = r0(1,i_part) + dt*v(1,i_part) + 0.5*dt_2*a(1,i_part)

#       if STORE == 0 & SYSTEM == 4
! the declaration of r0_unfold is necessary for chain_fftw.f90
        r0_unfold(:,i_part) = r0_unfold(:,i_part) + dt*v(:,i_part) + 0.5*a(:,i_part)*dt_2
#endif

#       if STORE == 1 
! ----- Update unfolded coordinates
        r0_unfold(:,i_part) = r0_unfold(:,i_part) + dt*v(:,i_part) + 0.5*a(:,i_part)*dt_2
#       endif 

! ----- Update velocities  to the half of the interval 

        v(:,i_part) =  v(:,i_part) + 0.5*dt*a(:,i_part)

    end do

!     Correct if  fixed-ends boundary conditions 
#if     CHAIN_BC == 2    
! First bead
        r0(1,1)=0.2*sigma(1,1) 
        r0(2,1)=boundary(2)/2.0 
        r0(3,1)=boundary(3)/2.0 
        v(:,1) = 0.0
!   Last bead: fixed in the right wall of the box        
        r0(1,n_mon*n_chain)=boundary(1)-0.2*sigma(1,1)
        r0(2,n_mon*n_chain)=boundary(2)/2.0 
        r0(3,n_mon*n_chain)=boundary(3)/2.0 
        v(:,n_mon*n_chain)= 0.0

! Unfolded coordinates 

        r0_unfold(1,1)= 0.2*sigma(1,1)
        r0_unfold(2,1)=boundary(2)/2.0 
        r0_unfold(3,1)=boundary(3)/2.0 
        r0_unfold(1,n_mon*n_chain)=boundary(1)-0.2*sigma(1,1)
        r0_unfold(2,n_mon*n_chain)=boundary(2)/2.0 
        r0_unfold(3,n_mon*n_chain)=boundary(3)/2.0 

#endif /* fixed-end boundary conditions */
    

# if SYSTEM == 4 & RINGS != 0

! Here should be Vcm==0 and Acm == 0 then the dynamic 
! of the CM is ok. (No needs fix_VCM or fix_CM)
# endif

# if WALL == 1 /*explicit wall*/
 ! Update Wall positions 
 ! Claudio 2009: wall position works only en X coordinate. I use only f_t_wall(1)

        do i_wall=1,n_wall/2
             r_wall_equi(:,i_wall) = r_wall_equi(:,i_wall) + va_spring_twall(:)*dt
        end do
        do i_wall=n_wall/2+1,n_wall
             r_wall_equi(:,i_wall) = r_wall_equi(:,i_wall) - va_spring_twall(:)*dt
        end do
#endif 
#ifdef SHEARED
        do i_wall=n_wall/2+1,n_wall
            do i_dim =1,3
                if(f_twall(i_dim).lt.9) r_wall_equi(i_dim,i_wall) = r_wall_equi(i_dim,i_wall) - appl_vel(i_dim)*dt
                if(f_twall(i_dim).eq.9) r_wall_equi(i_dim,i_wall) = r_wall_equi(i_dim,i_wall) + shiftbw(i_dim)
            end do
            if(f_twall(i_dim).lt.9) then
                r0_twall(i_dim)= r0_twall(i_dim) + appl_vel(i_dim)*dt
                r0_bwall(i_dim)= r0_bwall(i_dim) - appl_vel(i_dim)*dt
            end if
            if(f_twall(i_dim).eq.9) then
                r0_twall(i_dim)= r0_twall(i_dim) + shifttw(i_dim)
                r0_bwall(i_dim)= r0_bwall(i_dim) + shiftbw(i_dim)
            end if
        end do
#endif


!  ----  PBC conditions for r0 

            do i_part = 1,n_mon_tot
#if SYMMETRY == 0
                do i_dim = 1,n_dim-1
# elif SYMMETRY == 1
                    do i_dim = 1,n_dim
#endif
                        if(r0(i_dim,i_part).gt.boundary(i_dim)) then
                            r0(i_dim,i_part) = r0(i_dim,i_part) - boundary(i_dim)
                            mic_count(i_dim,i_part) = mic_count(i_dim,i_part) + 1
                        else if(r0(i_dim,i_part).lt.(0.)) then
                            r0(i_dim,i_part) = r0(i_dim,i_part) + boundary(i_dim)
                            mic_count(i_dim,i_part) = mic_count(i_dim,i_part) - 1
                        end if
                    end do
            end do
#   if WALL == 1 
!  ----  PBC conditions for wall atoms 
        do i_wall = 1,n_wall
            do i_dim = 1,n_dim-1
                if(r_wall_equi(i_dim,i_wall).gt.(boundary(i_dim))) then
                    r_wall_equi(i_dim,i_wall)=r_wall_equi(i_dim,i_wall) - boundary(i_dim)
                    mic_count(i_dim,i_wall) = mic_count(i_dim,i_wall) + 1
                else if(r_wall_equi(i_dim,i_wall).lt.(0.)) then
                    r_wall_equi(i_dim,i_wall)=r_wall_equi(i_dim,i_wall) + boundary(i_dim)
                    mic_count(i_dim,i_wall) = mic_count(i_dim,i_wall) - 1
                end if
            end do
        end do
    
#endif
        !test
# if WALL == 1 /* explicit wall */        
! Claudio 2009: Positions are fixed to equilibrium sites if we have explicit
! walls
           do i_wall = 1,n_wall
               i_part=n_mon_tot+i_wall
               r0(:,i_part)=r_wall_equi(:,i_wall)
           end do
#   endif    
! --- Calling the geometric routine for reshaping the droplet
!
!DROP, WARN: reshape in each time step if thermalizing

#   if SYSTEM==1 /* droplet */
        if (i_time <= n_relax ) then
          call geom_constraint()
        end if
#   endif

!
!   *** DEBUGGING STUFF *** 
!
    if(debug) then
        print*, "random force= " ,sum ( sum (force_r(:,:) , dim=1) ,dim=1)
        print*, "dissip force= " ,sum ( sum (force_d(:,:) , dim=1) ,dim=1)
    end if
end subroutine verlet_positions