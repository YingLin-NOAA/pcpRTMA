      program changepds
!
!$$$  MAIN PROGRAM DOCUMENTATION BLOCK
!                .      .    .                                       .
! MAIN PROGRAM: CHANGEPDS changes a GRIB file's Product Definition Section
!  
!   Programmer: Ying lin           ORG: NP22        Date: 2005-12-02
!
! ABSTRACT: Read in a Stage II analysis, change PDS(2) from 152 (for Stage II)
! to 109 (the generating process number for RTMA products)
! 
! Input: Unit 11: Stage II file
!        Unit 51: Stage II file with PDS(2) changed to 109
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
!
      parameter(lmax=1500000)
!
      dimension f(lmax)
      integer ipopt(20), jpds(25), jgds(22), kpds(25), kgds(22)
      logical*1 bit(lmax) 
!
      CALL W3TAGB('CHANGEPDS ',2001,0151,0060,'NP22   ')
!
      jpds = -1
      call baopenr(11,"fort.11",ibaret)
      call getgb(11,0,lmax,-1,jpds,jgds,kf,k,kpds,kgds,bit,f,iret)
      write(6,*) 'finished getgb, ibaret, iret=', ibaret, iret
!
      kpds(2)=109
!
      call baopenw(51,"fort.51",ibaret)
      call putgb(51,kf,kpds,kgds,bit,f,iret)      
      write(6,*) 'finished putgb, ibaret, iret=', ibaret, iret
!
      call baclose(51,ibaret)
      CALL W3TAGE('CHANGEPDS ')
!
      stop
      end
