PROGRAM Merge_Stage2_Stage4
!
! PURPOSE: Merge Stage 2/4 analyses, to be used as precip RTMA
! 
! INPUT FILES:
!   Unit 11  Stage 2 analysis
!   Unit 12  Stage 4 analysis
!   Unit 13  River Forecast Center (RFC) domain mask
!
! OUTPUT FILE:
!   Unit 51  Merged Stage 2/4
! 
! SUMMARY:
!   Merge the Stage 2/4 analyses: use Stage 4 as first choice, fill in missing 
!   points with Stage 2 in areas that belong to any one of the RFCs.  Do not
!   fill in areas with mask value < 150.  
!
! RECORD OF REVISIONS
!    Date     Programmer  Description of Change
! ==========  ==========  ====================================================
! 2015-08-25  Ying Lin    Borrowed from NDAS source code of the same name
! 2009-04-15  Ying Lin    Separated "merge Stage II/IV" from the original
!                         "pcpprep.f"
! LANGUAGE: Fortran 90/95
! 
IMPLICIT NONE

! Dimension of Stage 2/4 analysis files (on the 4km HRAP grid):
INTEGER, PARAMETER :: nx=1121, ny=881

! Stage 2/4 precipitation files and their bit masks; merged file and bit 
! mask; RFC domains mask (real array) and its bitmask (bitr)
REAL,    DIMENSION(nx,ny) :: p2, p4, p24, rfcmask
LOGICAL(KIND=1), DIMENSION(nx,ny) :: bit2, bit4, bit24, bitr

! RFC mask file, converted to integer (just a scalar variable):
INTEGER :: imask

! GDS and PDS for 1) getgb ('j')
!                 2) Stage 2 ('2')
!                 3) Stage 4 ('4')
!                 4) Stage 2/4 merged ('24')
!                 5) RFC mask ('r')

INTEGER, DIMENSION(200) :: jgds, kgds2, kgds4, kgds24, kgdsr
INTEGER, DIMENSION(200) :: jpds, kpds2, kpds4, kpds24, kpdsr

! For do loop index:
INTEGER :: i, j

! Misc for baopenr and getgb:
INTEGER :: kf, k, iret, iret2, iret4

! For 'getgb' searches:
    jpds = -1
 
! Read in Stage II:
    call baopenr(11,'fort.11',iret) 
    write(*,*) 'baopenr on unit 11, iret=', iret
    call getgb(11,0,nx*ny,0,jpds,jgds,kf,k,kpds2,kgds2,bit2,p2,iret2)
    write(*,10) 'ST2', kpds2(21)-1,kpds2(8),kpds2(9),kpds2(10),kpds2(11),iret2
 10 format('GETGB for ',a3,x, 5i2.2, ' iret=', i2)

! Read in Stage IV:
    call baopenr(12,'fort.12',iret) 
    write(*,*) 'baopenr on unit 12, iret=', iret
    call getgb(12,0,nx*ny,0,jpds,jgds,kf,k,kpds4,kgds4,bit4,p4,iret4)
    write(*,10) 'st4', kpds4(21)-1,kpds4(8),kpds4(9),kpds4(10),kpds4(11),iret4

! Read in RFC mask (real array), borrow the bitmap, kpds, kgds from ST2:
    call baopenr(13,'fort.13',iret) 
    write(*,*) 'baopenr on unit 13 for RFC mask, iret=', iret
    call getgb(13,0,nx*ny,0,jpds,jgds,kf,k,kpdsr,kgdsr,bitr,rfcmask,iret)
    write(*,*) 'getgb for RFC mask, iret=', iret

! Now merge Stage II/Stage IV: 
    IF (iret2 == 0 .AND. iret4 == 0) THEN   ! both analyses exist
      kgds24=kgds4
      kpds24=kpds4

      DO j = 1, ny
      DO i = 1, nx
        imask = INT(rfcmask(i,j))

!       Use Stage IV if Stage IV mask indicate that it has valid data.  
!       This means the point is either in one of the RFC's domains, or in
!       the Gulf of Mexico or off the Atlantic.  
!

        IF (bit4(i,j)) THEN
          p24(i,j)=p4(i,j)
          bit24(i,j)=bit4(i,j)
        ELSEIF (imask > 0) THEN
          p24(i,j)=p2(i,j)
          bit24(i,j)=bit2(i,j)
        ENDIF
      END DO
      END DO

    ELSE IF (iret2 == 0 .AND. iret4 /= 0) THEN
!     Only Stage II analysis exists.  Use Stage II.

      kgds24 = kgds2
      kpds24 = kpds2

      p24 = p2
      bit24 = bit2

    ELSE IF (iret2 /=0 .AND. iret4 == 0) THEN
!     Only Stage IV analysis exists.  Use Stage IV directly.

      kgds24 = kgds4
      kpds24 = kpds4
      p24 = p4
      bit24 = bit4

    ELSE  
      write(*,*) 'Neither Stage 2/4 file exists.  Exit merge2n4.'
      STOP
    END IF 

! Output the merged Stage 2/4 file:
    call baopen(51,'fort.51',iret) 
    write(*,*) 'baopen for merged Stage 2/4, iret=', iret
    call putgb(51,nx*ny,kpds24,kgds24,bit24,p24,iret)
    write(*,*) 'PUTGB for merged Stage 2/4, iret=', iret
!
STOP
END PROGRAM Merge_Stage2_Stage4
