******************************
* Programmed By: Chris Grace
* Programmed On: 12/2/24
* Programmed For: FP02
******************************

* Set up librefs;
x 'cd L:\st445\';
libname InputDS 'Data';
libname Results 'Results\FinalProjectPhase1';

x 'cd S:\Documents\ST445\Final';
libname Final '.';

* Define macro variables;
%let IdStamp = "Output created by &SysUserID on &SysDate9 using &SysVLong";
%let TitleOpts = height=14pt bold;
%let SubTitleOpts = height=10pt bold;
%let FootOpts = j=l height=8pt italic;

* Set options;
ods _all_ close;
ods pdf file="Final Grace EPA TRI Preliminary Analysis.pdf" style=sapphire columns=2
             uniform dpi=300;
ods noproctitle;
options nodate fmtsearch=(Final);

* Produce first column of output 1;
title &SubtitleOpts 'Output 1';
title2 &TitleOpts 'Listing of Incidents Reported via Form R';
title3 &SubtitleOpts 'Partial Output - Max of 25 Records for Federal Flag = Yes/No';
footnote &FootOpts &IdStamp;
PROC PRINT data=Results.fp01dugginstri(where=(FormType eq 'R' and FederalFL eq 'YES') obs=25) label noobs;
  var Class HazAirFL CarcFL PFASFL;
Run;

* Produce second column of output 1;
PROC PRINT data=Results.fp01dugginstri(where=(FormType eq 'R' and FederalFL eq 'NO') obs=25) label noobs;
  var Class HazAirFL CarcFL PFASFL;
Run;
title;

* Produce output 2;
title &SubtitleOpts 'Output 2';
title2 &TitleOpts 'Selected Summary Statistics of Total Air Pollution and Total Stream Discharge';
footnote &FootOpts &IdStamp;
ods select AirTotal.Moments AirTotal.BasicMeasures DischargeTotal.Moments
           DischargeTotal.BasicMeasures DischargeTotal.MissingValues;
PROC UNIVARIATE data=Results.FP01dugginsTRI;
  var AirTotal DischargeTotal;
Run;
title;

* Use one column instead of two;
ods pdf columns=1;

* Produce output 3;
* I used the documentation on PROC FREQ to find the 'order' option.
* https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/procstat/procstat_freq_syntax01.htm;
title &SubtitleOpts 'Output 3';
title2 &TitleOpts 'Frequency-Ordered Summary of Facility Locations (State)';
title3 &SubtitleOpts 'Only Unique Locations Included';
PROC FREQ data=Results.FP01dugginsFacilities order=freq;
  table FacState;
Run;
title;

* Produce output 4;
title &SubtitleOpts 'Output 4';
title2 &TitleOpts 'Frequency-Ordered Summary of Facility Locations (State)';
PROC FREQ data=Results.FP01dugginstri order=freq;
  table FacState;
Run;
title;

* Keep graphs on one page;
ods pdf startpage=never;

* Produce output 5;
* I used the VBAR documentation to refresh my memory
* of the SGPLOT options (specifically for keylegend and vbar)
* https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/grstatproc/n0yjdd910dh59zn1toodgupaj4v9.htm;
title &SubtitleOpts 'Output 5';
title2 &TitleOpts 'Frequency of Air Hazard Status for Each Chemical Classification';
PROC SGPLOT data=Results.FP01dugginsclassbyhazair;
  vbar Class / response=rowPercent group=HazAirFL barwidth=0.5 nooutline;
  styleattrs datacolors=('cx2b8cbe' 'cx74a9cf');
  xaxis label = 'Chemical Compound Classification';
  yaxis grid label='% of Compound Classification' values=(0 to 100 by 10);
  keylegend / title='Air Hazard' location=inside position=ne opaque down=3;
Run;
title;

* Produce output 6;
title &SubtitleOpts 'Output 6';
title2 &TitleOpts 'Frequency of Chemical Classification within Air Hazard Status';
PROC SGPLOT data=Results.FP01dugginsclassbyhazair;
  hbar HazAirFL / response=colPercent group=Class nooutline
                  datalabel datalabelattrs=(size=10pt Color=Gray)
                  groupdisplay=cluster;
  styleattrs datacolors=('cx2b8cbe' 'cx74a9cf' 'cxbdc9e1');
  xaxis grid label = '% of Air Hazard Status' values=(0 to 100 by 10);
  yaxis label='Air Hazard Status';
  keylegend / title='Classification' location=inside position=se opaque down=3;
Run;
title;

* Produce output 7;
title &SubtitleOpts 'Output 7';
title2 &TitleOpts 'Comparative Boxplots for Air Pollution';
title3 &SubtitleOpts 'For Mid-Atlantic* and Reference* States';
footnote2 &FootOpts 'Mid-Atlantic: MD, VA, NC, SC';
footnote3 &FootOpts 'Reference: CA, OH, NY, TX';
PROC SGPLOT data=Results.fp01dugginstri;
  vbox AirTotal / group=FacState grouporder=ascending;
  keylegend / title='State' location=inside position=nw down=9;
  xaxis display=(nolabel) type=discrete;
  yaxis label='Total Air Pollution';
  where FacState in ('CA', 'MD', 'NC', 'NY', 'OH', 'SC', 'TX', 'VA');
Run;
title;

* Keep reports on seperate pages;
ods pdf startpage=yes;

* Produce output 8;
title &SubtitleOpts 'Output 8';
title2 &TitleOpts 'Analysis of Air Pollution and Stream Discharge';
title3 &SubtitleOpts 'Limited to Chemicals Classified as PBT';
title4 &SubtitleOpts 'Excluding 2020';
PROC REPORT data=Results.fp01dugginstri;
  columns ReportYear HazAirFL CarcFL
          ('Air Pollution' (AirTotal=airmean AirTotal=airsd
                            AirTotal=airn))
           ('Stream Discharge' (DischargeTotal=discmean DischargeTotal=discsd
                                DischargeTotal=discn));
  define ReportYear / group descending 'Report Year';
  define HazAirFL / group 'HazAir';
  define CarcFL / group 'Carc';
  define airmean / analysis mean 'Mean' format=5.1;
  define airsd / analysis std 'Std. Dev.' format=7.2;
  define airn / analysis n 'Count' format=COMMA6.;
  define discmean / analysis mean 'Mean' format=5.1;
  define discsd / analysis std 'Std. Dev.' format=6.2;
  define discn / analysis n 'Count' format=COMMA5.;
  break after ReportYear / summarize;
  where Class eq 'PBT' and ReportYear not eq 2020;
Run;

* Produce output 9;
* This way seems really inefficient but it works;
title &SubtitleOpts 'Output 9';
title2 &TitleOpts 'Analysis of Air Pollution and Stream Discharge';
title3 &SubtitleOpts 'Limited to Chemicals Classified as PBT';
title4 &SubtitleOpts 'Excluding 2020';
footnote2 &FootOpts 'Alternative Display: Air Hazard displays on all non-summary rows';
PROC REPORT data=Results.fp01dugginstri;
  columns ReportYear HazAirFL HazCarried CarcFL
          ('Air Pollution' (AirTotal=airmean AirTotal=airsd
                            AirTotal=airn))
           ('Stream Discharge' (DischargeTotal=discmean DischargeTotal=discsd
                                DischargeTotal=discn));
  define ReportYear / group descending 'Report Year';
  define HazAirFL / group noprint;
  define HazCarried / computed 'HazAir';
  define CarcFL / group 'Carc';
  define airmean / analysis mean 'Mean' format=5.1;
  define airsd / analysis std 'Std. Dev.' format=7.2;
  define airn / analysis n 'Count' format=COMMA6.;
  define discmean / analysis mean 'Mean' format=5.1;
  define discsd / analysis std 'Std. Dev.' format=6.2;
  define discn / analysis n 'Count' format=COMMA5.;
  compute before HazAirFL;
    HazValue = HazAirFL;
  endcomp;
  compute HazCarried / character;
    if _BREAK_ eq '' then HazCarried = HazValue;
      else HazCarried = '';
  endcomp;
  break after ReportYear / summarize;
  where Class eq 'PBT' and ReportYear not eq 2020;
Run;

* Create color format for output 10;
PROC FORMAT library=Final;
  value sharedFMT 0          = 'cxff614f'
                  0 -< 25    = 'cxf1eef6'
                  25 -< 50   = 'cxbdc9e1'
                  50 -< 100  = 'cx74a9cf'
                  100 - high = 'cx2b8cbe';
  value CarcFMT   0          = 'cxf5712a'
                  0 -< 25    = 'cxf2f0f7'
                  25 -< 50   = 'cxcbc9e2'
                  50 -< 100  = 'cx9e9ac8'
                  100 - high = 'cx756bb1';
Run;

* Produce output 10;
* I used the documentation on style options to figure out how to justify
* the footer of the table;
* https://documentation.sas.com/doc/en/pgmsascdc/v_057/proc/p14xegao6xt0xnn1865r422tpytw.htm;
title &SubtitleOpts 'Output 10';
title2 &TitleOpts 'Color-Coded Analysis of Air Pollution and Stream Discharge';
title3 &SubtitleOpts 'Limited to Chemicals Classified as PBT';
title4 &SubtitleOpts 'Excluding 2020';
PROC REPORT data=Results.fp01dugginstri style(lines) = [color=white];
  columns ReportYear HazAirFL HazCarried CarcFL
          ('Air Pollution' (AirTotal=airmean AirTotal=airsd
                            AirTotal=airn))
           ('Stream Discharge' (DischargeTotal=discmean DischargeTotal=discsd
                                DischargeTotal=discn));
  define ReportYear / group descending 'Report Year';
  define HazAirFL / group noprint;
  define HazCarried / computed 'HazAir';
  define CarcFL / group 'Carc';
  define airmean / analysis mean 'Mean' format=5.1
                   style(column) = [backgroundcolor = sharedFmt.];
  define airsd / analysis std 'Std. Dev.' format=7.2;
  define airn / analysis n 'Count' format=COMMA6.;
  define discmean / analysis mean 'Mean' format=5.1;
  define discsd / analysis std 'Std. Dev.' format=6.2;
  define discn / analysis n 'Count' format=COMMA5.;
  compute before HazAirFL;
    HazValue = HazAirFL;
  endcomp;
  compute HazCarried / character;
    if _BREAK_ eq '' then HazCarried = HazValue;
      else HazCarried = '';
  endcomp;
  break after ReportYear / summarize style=[backgroundcolor = cxcccccc];
  compute after _page_ / style=[backgroundcolor = black textalign = right];
    line 'Air Pollutant Color-Coding:0, <25, 25-50, 50-100, >100';
  endcomp;
  where Class eq 'PBT' and ReportYear not eq 2020;
Run;

* Produce output 11;
title &SubtitleOpts 'Output 11';
title2 &TitleOpts 'Color-Coded* Analysis of Air Pollution and Stream Discharge';
title3 &SubtitleOpts 'Limited to Chemicals Classified as PBT';
title4 &SubtitleOpts 'Excluding 2020';
footnote3 &FootOpts '*Rows with CarcFL=Y and CarcFL=N use their respective cutoffs. Summary rows use CarcFL=N cutoffs.';
PROC REPORT data=Results.fp01dugginstri style(lines) = [color=white];
  columns ReportYear HazAirFL HazCarried CarcFL
          ('Air Pollution' (AirTotal=airmean airmeanfmtd
                            AirTotal=airsd AirTotal=airn))
           ('Stream Discharge' (DischargeTotal=discmean DischargeTotal=discsd
                                DischargeTotal=discn));
  define ReportYear / group descending 'Report Year';
  define HazAirFL / group noprint;
  define HazCarried / computed 'HazAir';
  define CarcFL / group 'Carc';
  define airmean / analysis mean noprint;
  define airmeanfmtd / computed 'Mean' format=5.1;
  define airsd / analysis std 'Std. Dev.' format=7.2;
  define airn / analysis n 'Count' format=COMMA6.;
  define discmean / analysis mean 'Mean' format=5.1;
  define discsd / analysis std 'Std. Dev.' format=6.2;
  define discn / analysis n 'Count' format=COMMA5.;
  compute before HazAirFL;
    HazValue = HazAirFL;
  endcomp;
  compute HazCarried / character;
    if _BREAK_ eq '' then HazCarried = HazValue;
      else HazCarried = '';
  endcomp;
  break after ReportYear / summarize style=[backgroundcolor = cxcccccc];
  compute after _page_ / style=[backgroundcolor = black textalign = right];
    line 'CarcFL=N coloring:0, <25, 25-50, 50-100, >100';
    line 'CarcFL=Y coloring:0, <40, 40-80, 80-100, >100';
  endcomp;
  compute airmeanfmtd;
    airmeanfmtd = airmean;
    if CarcFL eq 'YES' then call define(_col_, 'style', 'style=[backgroundColor=Carcfmt.]');
    else call define(_col_, 'style', 'style=[backgroundcolor = sharedfmt.]');
  endcomp;
  where Class eq 'PBT' and ReportYear not eq 2020;
Run;
title;
footnote;

* Close output;
ods pdf close;
quit;
