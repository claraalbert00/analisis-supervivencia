******Examen*******;

*****Exercici 1;
* Importació de les dades;

PROC IMPORT OUT= WORK.DADES 
            DATAFILE= "C:\Users\clara\OneDrive\Documentos\GEA\3er\Analisi Superviviencia\Pràctiques\SURVIVAL 1.xlsx" 
            DBMS=EXCEL REPLACE;
     RANGE="BD1$"; 
     GETNAMES=YES;
     MIXED=NO;
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

PROC PRINT DATA = DADES (OBS=10);
RUN;


* Assignació formats;
PROC FORMAT;
VALUE G 0="Homes" 1="Dones";
VALUE S 1="Si" 0="No";
VALUE M 1="Recurrent" 0="Primer";
VALUE F 0="Censura" 1="Mort";
RUN;

* Assignació etiquetes;
DATA DADES;
SET DADES;
FORMAT GENDER G. SHO S. MIORD M. FSTAT F.;
LABEL ID="Identificador" AGE="Edat" GENDER="Sexe" HR="Freqüència cardíaca inicial" 
SHO="Complicacions de xoc cardiogènic" MIORD = "Número d'infart" YEAR="Any de cohort" LENFOL="Durada del seguiment" FSTAT="Indicador de censura";
RUN;

PROC CONTENTS DATA=DADES VARNUM;
RUN;

********* Exercici 2;
*Recodificar les variables;
DATA DADES;
SET DADES;
IF HR < 60 THEN HR_2 = 0;
ELSE IF HR >= 60 AND HR <= 100 THEN HR_2 = 1;
ELSE HR_2 = 2;
RUN;

PROC PRINT DATA=DADES (OBS=10);
RUN;

PROC FREQ DATA = DADES;
TABLE HR*HR_2 / NOPERCENT NOCOL;
RUN;

*Assignar les noves etiquetes;
PROC FORMAT;
VALUE H 0="<60" 1="60-100" 2=">100";
RUN;

DATA DADES;
SET DADES;
FORMAT HR_2 H.;
RUN;

PROC CONTENTS DATA=DADES VARNUM;
RUN;

*******Exercici 3;
*Realitzar anàlisi bivariada entre censura i var explicatives;

*Amb variables qualitatives;
PROC FREQ DATA = DADES;
TABLE (GENDER SHO MIORD HR_2)*FSTAT / CHISQ NOPERCENT NOCOL;
RUN;


* Amb variables quantitatives;
PROC MEANS DATA=DADES MAXDEC=2;
CLASS FSTAT;
VAR AGE HR YEAR LENFOL;
RUN;

PROC NPAR1WAY WILCOXON;
CLASS FSTAT;
VAR AGE HR YEAR LENFOL;
RUN;

*********Exercici 4;
* Analitzar supervivència segons cada una de les variables explicatives;

%MACRO SUPERVIVENCIA(BD,V1);
PROC LIFETEST DATA = &BD PLOTS=SURVIVAL(ATRISK) NOTABLE;
STRATA &V1;
TIME LENFOL*FSTAT(0);
ODS EXCLUDE ProductLimitEstimates;
RUN;
%MEND SUPERVIVENCIA;

%MACRO SURV2(VAR,TALL);
PROC LIFETEST DATA=DADES PLOTS=SURVIVAL(ATRISK) NOTABLE;
TIME LENFOL*FSTAT(0);
STRATA &VAR(&TALL);
ODS EXCLUDE ProductLimitEstimates;
RUN;
%MEND SURV2;

PROC MEANS DATA=DADES MEAN MEDIAN MAXDEC=2;
VAR AGE YEAR LENFOL;
RUN; 

%SUPERVIVENCIA(BD=DADES,V1=GENDER);
%SUPERVIVENCIA (BD=DADES,V1=SHO);
%SUPERVIVENCIA (BD=DADES,V1=MIORD);
%SUPERVIVENCIA (BD=DADES,V1=HR_2);
%SURV2 (VAR=AGE, TALL=70);
%SURV2 (VAR=YEAR, TALL=2);

PROC PRINT DATA=DADES (OBS=10);
RUN;

************Exercici 5;
*Ajustar model de riscos proporcionals de Cox;

PROC PHREG DATA = DADES;
CLASS GENDER SHO MIORD HR_2;
MODEL LENFOL*FSTAT(0) = GENDER SHO MIORD HR_2;
HAZARDRATIO GENDER; 
HAZARDRATIO SHO; 
HAZARDRATIO MIORD; 
HAZARDRATIO HR_2; 
RUN;

PROC PHREG DATA = DADES;
CLASS GENDER SHO MIORD HR_2;
MODEL LENFOL*FSTAT(0) = GENDER SHO MIORD HR_2 AGE YEAR;
RUN;

*GENDER MIORD no son significatives al model per tant les treiem;

PROC PHREG DATA = DADES;
CLASS SHO HR_2;
MODEL LENFOL*FSTAT(0) = SHO HR_2 AGE YEAR;
HAZARDRATIO SHO;
HAZARDRATIO HR_2;
HAZARDRATIO AGE;
HAZARDRATIO YEAR;
RUN;

*Ara totes les nostres variables són significatives al model de Cox;
*Podem interpretar els resultats d'aquest model;

***********Exercici 6;
*Avaluar interaccions amb el gènere;
PROC PHREG DATA = DADES;
CLASS SHO HR_2;
MODEL LENFOL*FSTAT(0) = SHO HR_2 AGE YEAR SHO*AGE HR_2*AGE HR_2*YEAR;
RUN;

PROC LIFETEST DATA=DADES PLOTS=SURVIVAL;
TIME LENFOL*FSTAT(0);
STRATA AGE(70) SHO;
ODS EXCLUDE ProductLimitEstimates;
RUN;


