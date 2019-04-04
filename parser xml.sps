* Encoding: windows-1252.

* begin met voor West-Vlaanderen http://overpass-turbo.eu/s/HFU
* voor Oost-Vlaanderen: http://overpass-turbo.eu/s/HGG (opgelet, 200mb)
* dan exporteren als raw OSM data
* dan inlezen etc.

PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE="C:\Users\plu3532\Documents\niet-werkgerelateerd\OSM\grb import\export.osm"
  /FIXCASE=1
  /ARRANGEMENT=FIXED
  /FIRSTCASE=1
  /VARIABLES=
  /1 V1 0-300 A301.
RESTORE.

CACHE.
EXECUTE.
DATASET NAME grb WINDOW=FRONT.

* bereken tekstlengte van de rij.
compute lengte=length(ltrim(rtrtim(v1))).
EXECUTE.

* zorg dat we achteraf alles terug kunnen goed sorteren.
compute volgnummer=$casenum.
EXECUTE.

* maak een unieke sleutel per way/relatie.
if $casenum=1 object=0.
if $casenum>1 & CHAR.INDEX(V1,"<way id='")=0 object=lag(object).
if CHAR.INDEX(V1,"<way id='")>0 object=lag(object)+1.

* maak een teller binnen het object.
if $casenum=1 rij_object=2.
if lag(object)=object rij_object=lag(rij_object)+1.
if lag(object)~=object rij_object=1.
EXECUTE.

string entity (a50).
if CHAR.INDEX(V1,"source:geometry:entity")>0 entity=char.substr(v1,CHAR.INDEX(V1,"v='")+3).
compute entity=char.substr(entity,1,CHAR.INDEX(entity,"'")-1).
string oidn (a50).
if CHAR.INDEX(V1,"source:geometry:oidn")>0 oidn=char.substr(v1,CHAR.INDEX(V1,"v='")+3).
compute oidn=char.substr(oidn,1,CHAR.INDEX(oidn,"'")-1).
EXECUTE.

DATASET ACTIVATE grb.
DATASET DECLARE tussenstap.
AGGREGATE
  /OUTFILE='tussenstap'
  /BREAK=object entity oidn
  /N_BREAK=N.
dataset activate tussenstap.

* verzamel de relevante info.
if object=lag(object) & entity="" entity=lag(entity).
if object=lag(object) & oidn="" oidn=lag(oidn).
EXECUTE.

DATASET ACTIVATE tussenstap.
* Identify Duplicate Cases.
SORT CASES BY object(A).
MATCH FILES
  /FILE=*
  /BY object
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast 'Indicator of each last matching case as Primary'.
VALUE LABELS  PrimaryLast 0 'Duplicate Case' 1 'Primary Case'.
VARIABLE LEVEL  PrimaryLast (ORDINAL).
EXECUTE.

* hou enkel rij met relevante info over.
FILTER OFF.
USE ALL.
SELECT IF (PrimaryLast = 1).
EXECUTE.

* hou enkel rijen met effectief iets om mee te werken over.
FILTER OFF.
USE ALL.
SELECT IF (entity ~= "").
EXECUTE.

* zoek de speciallekes.
compute specialleke=max(CHAR.INDEX(entity,";"),CHAR.INDEX(oidn,";")).
EXECUTE.

* sop is de kolen niet waard.
FILTER OFF.
USE ALL.
SELECT IF (specialleke = 0).
EXECUTE.

delete variables n_break specialleke.
rename variables primarylast=aangepast.
rename variables entity=key.
rename variables oidn=value.

* alles terug samenzetten.
sort cases object (a).
DATASET ACTIVATE grb.
MATCH FILES /FILE=*
  /TABLE='tussenstap'
  /BY object.
EXECUTE.
dataset close tussenstap.

* tag aanpassen.
do if aangepast=1 & entity~="".
compute v1=replace(v1,"source:geometry:entity","source:geometry:ref").
compute v1=replace(v1,ltrim(rtrim(entity)),ltrim(rtrim(value))).
end if.
EXECUTE.

* verwijder rij met oidn en uidn.
compute te_verwijderen=0.
if aangepast=1 & (oidn~="" | CHAR.INDEX(V1,"source:geometry:uidn")>0) te_verwijderen=1.
EXECUTE.

* zorg dat JOSM weet welke aan te passen.
if aangepast=1 & lag(object)<object v1=replace(v1,"timestamp","action='modify' timestamp ").
EXECUTE.


FILTER OFF.
USE ALL.
SELECT IF (te_verwijderen = 0).
EXECUTE.

* hou enkel de relevante data over.
match files
/file=*
/keep=v1.
EXECUTE.


* wel nog de extentie aanpassen naar .osm.
SAVE TRANSLATE OUTFILE='C:\Users\plu3532\Documents\niet-werkgerelateerd\OSM\grb import\output_wv.csv'
  /TYPE=CSV
  /ENCODING='Locale'
  /MAP
  /REPLACE
  /CELLS=VALUES.
