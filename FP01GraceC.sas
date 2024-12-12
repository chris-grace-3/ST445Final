*****************************************
* Programmed By: Chris Grace
* Programmed On: 11/17/24
* Programmed For: Final Project Phase 1
*
* My planning document:
* https://docs.google.com/document/d/1XCgcP5Q_ujTTHq6ceDMKiR2s2_E1OOsCppUPT7l5F64/edit?usp=sharing
* ^ Includes edit access to check timestamps
*****************************************;

* Set up librefs;
x 'cd L:\st445\Data\EPA TRI';
filename rawData 'RawData';
libname InputDS 'StructuredData';
libname Formats 'FormatCatalogs';

x 'cd S:\Documents\ST445\Final';
libname Final '.';

* Set global options;
ods listing close;
options fmtsearch=(Formats);

* Bring in EventReport;
DATA EventReport(drop=_:);
  attrib DateSigned format = YYMMDD10.;
  infile rawData('EventReports2023.txt');
  input _DateSigned $ 1-10 NAICS $ 11-16 CasNum $ 17-31 FormType $ 32
        TRIFID $ 33-47 EntireFL $ 48-50 FederalFL $ 51-53 ControlNum $ 54-68
        ElementalFL $ 69-71 Class $ 72-77 Units $ 78-83 HazAirFL $ 84-86
        CarcFL $ 87-89 PfasFL $ 90-92 MetalFL $ 93-95 FugAirTotal 96-125
        StackAirTotal 126-155;
  DateSigned  = input(_DateSigned, YYMMDD10.);
Run;

* Sort EventReport by TRIFID;
PROC SORT data=EventReport;
  by TRIFID;
Run;

* Bring in Facility Demographics;
DATA FacilityDems;
  infile rawData('FacilityDemographics2023.txt') dlm='09'x truncover;
  input    TRIFID $15.
        #2 FacName $75.
        #3 FacStreet $100.
        #4 FacCity : $25. FacState $2. FacZip $9.
        #5 FacCounty $50.
        #6 BIAID $3. TribeName $100.;
Run;

* Merge Event Reports and Facility Demographics by TRIFID;
DATA EventFacilities;
  set EventReport FacilityDems;
  by TRIFID;
Run;

* Sort EventFacilities by ControlNum;
PROC SORT data=EventFacilities;
  by ControlNum;
Run;

* Bring in Streams;
DATA Streams(drop=i _:);
  infile rawData('StreamsData2023.txt') missover dlm='09'x;
  attrib ControlNum length = $15
         StreamA StreamB StreamC StreamD StreamE StreamF StreamG
         StreamH StreamI length = $75
         DischargeA DischargeB DischargeC DischargeD DischargeE
         DischargeF DischargeG DischargeH DischargeI length = 8; 
  input _val1 : $75. _val2;
  ControlNum = _val1;
  _Discard = _val2;
  array streams[*] Stream:;
  array discharge[*] Discharge:;
  do i = 1 to 9;
    input streams[i] $ discharge[i];
  end;
  output;
Run;

* Sort Streams by ControlNum;
PROC SORT data=Streams;
  by ControlNum;
Run;

* Create 2023 data;
DATA tri2023;
  merge EventFacilities Streams;
  by ControlNum;
Run;

* Create final data set;
* I used the documentation found at:
* https://documentation.sas.com/doc/en/vdmmlcdc/8.1/ds2ref/p1h8l8v2o11xhnn1oue05oue1hvx.htm
* to understand the functionality of the z format so I could create TRIChemID;
DATA Final.FP01GraceCTRI(drop=_:);
  set InputDS.tri2018(in=triyear2018)
      InputDS.tri2019(in=triyear2019)
      InputDS.tri2020(in=triyear2020)
      InputDS.tri2021(in=triyear2021)
      InputDS.tri2022(in=triyear2022)
      tri2023(in=triyear2023);
  attrib ReportYear label = 'Report Year'
         TRIFID label = 'TRI Federal ID'
         FacName label = 'Facility Name'
         FacStreet label = 'Facility Street'
         FacCity label = 'Facility City'
         FacCounty label = 'Facility County'
         FacState label = 'Facility State'
         FacZip label = 'Facility ZIP Code'
         BIAID label = 'Bureau of Indian Affairs (BIA) code indicating the tribal land on which the facility is located'
         TribeName label = 'Name of the tribe on whose land the reporting facility is located'
         NAICS label = '6-Digit NAICS Description'
         NAICSDescription label = 'Six-Digit NAICS Description' length = $150
         NAICS2 label = '2-Digit NAICS Code' length = $2
         NAICS3 label = '3-Digit NAICS Code' length = $3
         NAICS4 label = '4-Digit NAICS Code' length = $4
         NAICS5 label = '5-Digit NAICS Code' length = $5
         ControlNum label = 'Case Control #'
         FormType label = 'Reporting Form'
         DateSigned label = 'Form Signature Date'
         EntireFL label = 'Entire Facility Flag'
         FederalFL label = 'Federal Facility Flag'
         CASNum label = 'Chemical Abstract Service #'
         TRIChemID label = 'TRI Chemical ID'
         ElementalFL label = 'Combined Metal Report Flag'
         Class label = 'Chemical Classification'
         Units label = 'Units of Measure'
         HazAirFL label = 'Hazardous Air Pollutant Flag'
         CarcFL label = 'Carcinogen Flag'
         PFASFL label = 'PFAS Flag'
         MetalFL label = 'TRI Metal Flag'
         FugAirTotal label = 'Total Fugitive Air Emissions'
         StackAirTotal label = 'Total Stack (Point Source) Air Emissions'
         AirTotal label = 'Total Air Emissions'
         StreamA label = 'Stream A Name'
         DischargeA label = 'Stream A Discharge'
         StreamB label = 'Stream B Name'
         DischargeB label = 'Stream B Discharge'
         StreamC label = 'Stream C Name'
         DischargeC label = 'Stream C Discharge'
         StreamD label = 'Stream D Name'
         DischargeD label = 'Stream D Discharge'
         StreamE label = 'Stream E Name'
         DischargeE label = 'Stream E Discharge'
         StreamF label = 'Stream F Name'
         DischargeF label = 'Stream F Discharge'
         StreamG label = 'Stream G Name'
         DischargeG label = 'Stream G Discharge'
         StreamH label = 'Stream H Name'
         DischargeH label = 'Stream H Discharge'
         StreamI label = 'Stream I Name'
         DischargeI label = 'Stream I Discharge'
         StreamCount length = 8 label = '# of Affected Streams'
         DischargeTotal length = 8 label = 'Total Discharge';
  array years[*] triyear:;
  do _i = 1 to dim(years);
    if years[_i] then ReportYear = 2017 + _i;
  end;
  NAICSDescription = put(NAICS, Naics.);
  array NAICSxdigits[4] $ NAICS2-NAICS5;
  do _j = 1 to dim(NAICSxdigits);
    NAICSxdigits[_j] = substr(NAICS, 1, _j+1);
  end;
  array Streams[9] StreamA StreamB StreamC StreamD StreamE StreamF StreamG StreamH StreamI;
  array Discharge[9] DischargeA DischargeB DischargeC DischargeD DischargeE DischargeF DischargeG DischargeH DischargeI;
  StreamCount = 0;
  DischargeTotal = 0;
  do _k = 1 to 9 while(not missing(Streams[_k]));
    StreamCount = _k;
    DischargeTotal = DischargeTotal + Discharge[_k];
  end; 
  if missing(FugAirTotal) or missing(StackAirTotal) then call missing(AirTotal);
    else AirTotal = FugAirTotal + StackAirTotal;
  if lowcase(CASNum) in ('mixture', 'trd secrt') or substr(lowcase(CASNum), 1, 1) eq 'n' then
    TRIChemID = CASNum;
  else TRIChemID = put(input(compress(CASNum, '-'), 10.), z10.);
Run;

* Create data set of unique facilities;
PROC SORT data=Final.FP01GraceCTRI(keep = TRIFID FacState) out=Final.FP01GraceCFacilities nodupkey;
  by TRIFID;
Run;

* Generate frequency statistics;
ods output CrossTabFreqs=Final.FP01GraceCClassByHazAir(keep=Class HazAirFL _TYPE_ RowPercent ColPercent);
PROC FREQ data=Final.FP01GraceCTRI;
  table Class*HazAirFL / nocum outpct;
Run;

Quit;
