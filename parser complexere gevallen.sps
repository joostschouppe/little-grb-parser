* Encoding: UTF-8.

* ZORG DAT JE OP UTF-8 STAAT!.

SET OLang=English Unicode=Yes Locale=nl_BE.
PRESERVE.
 SET DECIMAL COMMA.

GET DATA  /TYPE=TXT
  /FILE='C:\Users\plu3532\Documents\niet-werkgerelateerd\OSM\grb import\export.osm'
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
if $casenum>1 & (CHAR.INDEX(V1,'<way id="')=0 | CHAR.INDEX(V1,'<relation id="')=0)  object=lag(object).
if (CHAR.INDEX(V1,'<way id="')>0 | CHAR.INDEX(V1,'<relation id="')>0) object=lag(object)+1.

* maak een teller binnen het object.
if $casenum=1 rij_object=2.
if lag(object)=object rij_object=lag(rij_object)+1.
if lag(object)~=object rij_object=1.
EXECUTE.

string entity (a50).
if CHAR.INDEX(V1,'source:geometry:entity')>0 entity=char.substr(v1,CHAR.INDEX(V1,'v="')+3).
compute entity=char.substr(entity,1,CHAR.INDEX(entity,'"')-1).
string oidn (a50).
if CHAR.INDEX(V1,'source:geometry:oidn')>0 oidn=char.substr(v1,CHAR.INDEX(V1,'v="')+3).
compute oidn=char.substr(oidn,1,CHAR.INDEX(oidn,'"')-1).
EXECUTE.

DATASET ACTIVATE grb.
DATASET DECLARE tussenstap.
AGGREGATE
  /OUTFILE="tussenstap"
  /BREAK=object entity oidn
  /N_BREAK=N.
dataset activate tussenstap.

* verzamel de relevante info.
if object=lag(object) & entity='' entity=lag(entity).
if object=lag(object) & oidn='' oidn=lag(oidn).
EXECUTE.

DATASET ACTIVATE tussenstap.
* Identify Duplicate Cases.
SORT CASES BY object(A).
MATCH FILES
  /FILE=*
  /BY object
  /LAST=PrimaryLast.
VARIABLE LABELS  PrimaryLast "Indicator of each last matching case as Primary".
VALUE LABELS  PrimaryLast 0 "Duplicate Case" 1 "Primary Case".
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
SELECT IF (entity ~= '').
EXECUTE.

* zoek de speciallekes.
compute specialleke=max(CHAR.INDEX(entity,';'),CHAR.INDEX(oidn,';')).
EXECUTE.

frequencies specialleke.

* hou enkel de speciallekes over.
FILTER OFF.
USE ALL.
SELECT IF (specialleke > 0).
EXECUTE.

* typologie maken.

compute entity_type= CHAR.INDEX(entity,';').
string entity_second (a50).
if entity_type>0 entity_second=CHAR.SUBSTR(entity,entity_type+1).
compute entity_type2=CHAR.INDEX(entity_second,';').

string entity_first (a3).
compute entity_first=entity.

EXECUTE.

* doe niets indien meer dan twee gebouwtypes of incorrecte entity tag.
FILTER OFF.
USE ALL.
SELECT IF (entity_type2 = 0 & (intity_type=0 | entity_type=4)).
EXECUTE.

recode entity_type (0=1) (4=2).
EXECUTE.

delete variables n_break specialleke entity_type2.

string oidntemp (a50).
string oidn1 (a50).
string oidn2 (a50).
string oidn3 (a50).
string oidn4 (a50).
string oidn5 (a50).

compute oidn1=char.substr(oidn,1,char.index(oidn,";")-1).
compute oidntemp=char.substr(oidn,char.index(oidn,";")+1).
compute oidn2=char.substr(oidntemp,1,char.index(oidntemp,";")-1).
if char.index(oidntemp,";")=0 oidn2=oidntemp.
if char.index(oidntemp,";")=0 oidntemp="".
compute oidntemp=char.substr(oidntemp,char.index(oidntemp,";")+1).

compute oidn3=char.substr(oidntemp,1,char.index(oidntemp,";")-1).
if char.index(oidntemp,";")=0 oidn3=oidntemp.
if char.index(oidntemp,";")=0 oidntemp="".
compute oidntemp=char.substr(oidntemp,char.index(oidntemp,";")+1).

compute oidn4=char.substr(oidntemp,1,char.index(oidntemp,";")-1).
if char.index(oidntemp,";")=0 oidn4=oidntemp.
if char.index(oidntemp,";")=0 oidntemp="".
compute oidntemp=char.substr(oidntemp,char.index(oidntemp,";")+1).
compute oidn5=char.substr(oidntemp,1,char.index(oidntemp,";")-1).
if char.index(oidntemp,";")=0 oidn5=oidntemp.
if char.index(oidntemp,";")=0 oidntemp="".
compute oidntemp=char.substr(oidntemp,char.index(oidntemp,";")+1).
EXECUTE.

* verwijder complexe.
DATASET ACTIVATE tussenstap.
FILTER OFF.
USE ALL.
SELECT IF (oidntemp = "").
EXECUTE.

do if entity_type=1.
    if oidn1~="" oidn1=concat(ltrim(rtrim(entity)),"/",oidn1).
    if oidn2~="" oidn2=concat(ltrim(rtrim(entity)),"/",oidn2).
    if oidn3~="" oidn3=concat(ltrim(rtrim(entity)),"/",oidn3).
    if oidn4~="" oidn4=concat(ltrim(rtrim(entity)),"/",oidn4).
    if oidn5~="" oidn5=concat(ltrim(rtrim(entity)),"/",oidn5).
end if.

do if entity_type=2 & oidn3="".
    if oidn1~="" oidn1=concat(ltrim(rtrim(entity_first)),"/",oidn1).
    if oidn2~="" oidn2=concat(ltrim(rtrim(entity_second)),"/",oidn2).
end if.


* verwijder complexe gevallen.


FILTER OFF.
USE ALL.
SELECT IF ((entity_type=2 & oidn3="") | entity_type=1).
EXECUTE.

string oidn_value (a150).
compute oidn_value=ltrim(rtrim(oidn1)).
if oidn2~="" oidn_value=concat(oidn_value,";",ltrim(rtrim(oidn2))).
if oidn3~="" oidn_value=concat(oidn_value,";",ltrim(rtrim(oidn3))).
if oidn4~="" oidn_value=concat(oidn_value,";",ltrim(rtrim(oidn4))).
if oidn5~="" oidn_value=concat(oidn_value,";",ltrim(rtrim(oidn5))).
EXECUTE.

rename variables primarylast=aangepast.

match files
/file=*
/keep=object
entity
oidn
aangepast
oidn_value.





* alles terug samenzetten.
sort cases object (a).
DATASET ACTIVATE grb.
MATCH FILES /FILE=*
  /TABLE="tussenstap"
  /BY object.
EXECUTE.
dataset close tussenstap.

* TOT HIER OK.

* tag aanpassen.
do if aangepast=1 & entity~=''.
compute v1=replace(v1,'source:geometry:entity','source:geometry:ref').
compute v1=replace(v1,ltrim(rtrim(entity)),ltrim(rtrim(oidn_value))).
end if.
EXECUTE.

* verwijder rij met oidn en uidn.
compute te_verwijderen=0.
if aangepast=1 & (oidn~='' | CHAR.INDEX(V1,'source:geometry:uidn')>0) te_verwijderen=1.
if CHAR.INDEX(V1,'<tag k="source" v="GRB"/>')>0 te_verwijderen=1.
EXECUTE.

* zorg dat JOSM weet welke aan te passen.

DATASET ACTIVATE grb.
AGGREGATE
  /OUTFILE=* MODE=ADDVARIABLES
  /BREAK=object
  /te_verwijderen_max=MAX(te_verwijderen).

if te_verwijderen_max=1 & lag(object)<object v1=replace(v1,'timestamp','action="modify" timestamp ').
EXECUTE.

DATASET DECLARE test.
AGGREGATE
  /OUTFILE='test'
  /BREAK=object
  /aangepast_max=MAX(aangepast) 
  /te_verwijderen_max_max=MAX(te_verwijderen_max).
dataset activate test.
FREQUENCIES aangepast_max  te_verwijderen_max_max.
dataset activate grb.
dataset close test.

FILTER OFF.
USE ALL.
SELECT IF (te_verwijderen = 0).
EXECUTE.

* hou enkel de relevante data over.
match files
/file=*
/keep=v1.
EXECUTE.


* sla op als .osm file.
SAVE TRANSLATE OUTFILE='C:\Users\plu3532\Documents\niet-werkgerelateerd\OSM\grb import\output_export.osm'
  /TYPE=TAB
  /ENCODING='UTF8'
  /MAP
  /REPLACE
  /CELLS=VALUES.

* open in JOSM, valideer, upload.

