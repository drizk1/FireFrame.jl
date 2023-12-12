# FireFrame?

#### This originally started when I came across the fhircrackr package in R. I have not found something similar in Julia yet, so I  decided to begin building parts of it. Although the examples below use FHIR resources as their examples, I suspect you could use this other non FHIR websites as well, but I have not tried.

#### The goal is to simplify and streamline going from a JSON file (maybe xml one day idk the pros v cons) to a dataframe for data tidying manipulation, statisitcal testing, etc. Some creative liberty has been taken to work on other features that one might find useful, such as `get_table_design()`. 

#### Currently included:
- `search_resource(base_url, resource; max_entries)` 
- `fireframe(object, column_design)` 
- `get_table_design(object)` # as an OrderedDict
- `print_paths(object)`

```
using DataFrames
using OrderedCollections: OrderedDict
using HTTP, JSON

patients = search_resource("https://hapi.fhir.org/baseR4", "Patient", max_entries = 5);
column_design = OrderedDict(
    "ID" => "id",
    "use_name" => "name.use",
    "given_name" => "name.given",
    "family_name" => "name.family",
    "gender" => "gender",
    "birthday" => "birthDate"
);

fireframe(patients, column_design)
# fireframe(patients, get_table_design(patients))
```
```
5×6 DataFrame
 Row │ ID      use_name  given_name  family_name  gender  birthday                 
     │ String  String    String      String       String  String                   
─────┼─────────────────────────────────────────────────────────────────────────────
   1 │ 592911  official  Khan        Moazzam      na      na
   2 │ 592912  official  Khan        Moazzam      na      na
   3 │ 592913  official  Khan        Moazzam      na      na
   4 │ 592917  na        na          na           na      na
   5 │ 592925  official  Test        Mustermann   female  2017-09-05T22:00:00.000Z
```
##### Alternatively, `fireframe(patients, get_table_design(patients))` would have worked to fill the wide dataframe with all values, leaving the paths as teh column names. 



### `print_paths()` and `get_table_design()`
##### `get_table_design()` is meant to make generating the OrderedDict less tedius for the user. A user would be able to easily copy the table's dict, make edits (add commmas, add/delete paths, and change column names), and then use subsequent design to convert the object to a dataframe, or to build the whole df immediately, albeit with messier names. (but with TidierData: @rename_with() and TidierStrings: str_remove_all(), cleaning the names would be pretty straightfoward)

```
medreq = search_resource("https://hapi.fhir.org/baseR4", "MedicationRequest",max_entries = 5);
print_paths(medreq)
```
```
entry[1].search.mode: match
entry[1].fullUrl: https://hapi.fhir.org/baseR4/MedicationRequest/39546
entry[1].resource.meta.source: #16603bb923676fa5
entry[1].resource.meta.versionId: 1
entry[1].resource.meta.lastUpdated: 2019-10-03T08:23:16.555+00:00
entry[1].resource.status: active
entry[1].resource.medicationReference.reference: Medication/39545
entry[1].resource.id: 39546
entry[1].resource.resourceType: MedicationRequest
entry[1].resource.intent: proposal
entry[1].resource.dosageInstruction[1].route.coding[1].display: Oral route (qualifier value)
entry[1].resource.dosageInstruction[1].route.coding[1].code: 26643006
entry[1].resource.dosageInstruction[1].route.coding[1].system: http://snomed.info/sct
entry[1].resource.dosageInstruction[1].doseAndRate[1].doseQuantity.unit: Puff
entry[1].resource.dosageInstruction[1].doseAndRate[1].doseQuantity.value: 2
entry[1].resource.dosageInstruction[1].doseAndRate[1].doseQuantity.code: 415215001
entry[1].resource.dosageInstruction[1].doseAndRate[1].doseQuantity.system: http://unitsofmeasure.org
entry[1].resource.identifier[1].value: cdbd33f0-6cde-11db-9fe1-0800200c9a66
entry[1].resource.identifier[1].type.coding[1].display: Medical record number
entry[1].resource.identifier[1].type.coding[1].code: MR
entry[1].resource.identifier[1].type.coding[1].system: http://hl7.org/fhir/v2/0203
entry[1].resource.subject.reference: Patient/39254
meta.lastUpdated: 2023-12-12T04:45:35.682+00:00
id: 9c86bfb5-5a1e-4694-ba73-4e0930a1314f
resourceType: Bundle
link[1].relation: self
link[1].url: https://hapi.fhir.org/baseR4/MedicationRequest?_count=5
type: searchset
```

#### I am open to any suggestions for future direction, priority additions, and to contributors. 
