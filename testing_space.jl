
using DataFrames
#using TidierData
using OrderedCollections: OrderedDict
using HTTP, JSON
include("go2df.jl")

patients = search_resource("https://hapi.fhir.org/baseR4", "Patient", max_entries = 5)
medreq = search_resource("https://hapi.fhir.org/baseR4", "MedicationRequest",max_entries = 5)

print_paths(medreq)

# Example usage with an OrderedDict
column_design = OrderedDict(
    "PID" => "id",
    "use_name" => "name.use",
    "given_name" => "name.given",
    "family_name" => "name.family",
    "gender" => "gender",
    "birthday" => "birthDate"
)

column_design2 = OrderedDict(
    "RequestID" => "id",
    "Status" => "status",
    "Intent" => "intent",
    "MedicationReference" => "medicationReference.reference",
    "DosageRouteDisplay" => "dosageInstruction.route.coding.display",
    "DosageRouteCode" => "dosageInstruction.route.coding.code",
    "DosageRouteSystem" => "dosageInstruction.route.coding.system",
    "DosageDoseQuantityUnit" => "dosageInstruction.doseAndRate.doseQuantity.unit",
    "DosageDoseQuantityValue" => "dosageInstruction.doseAndRate.doseQuantity.value",
    "PatientReference" => "subject.reference"
)

fireframe(patients, column_design)
fireframe(medreq, column_design2)

get_table_design(patients)
generate_fhir_design(medreq)
using TidierData
@glimpse fireframe(patients, get_table_design(patients))

function get_table_design(json_data, current_path = "", design = OrderedDict{String, String}(), depth_limit = 1)
  if isa(json_data, Dict)
      for (key, value) in json_data
          new_key = key
          new_path = current_path == "" ? new_key : current_path * "." * new_key
          # Remove "entry.resource." from the path
          new_path = replace(new_path, "entry.resource." => "")
          get_table_design(value, new_path, design, depth_limit)
      end
  elseif isa(json_data, Array)
      for (index, item) in enumerate(json_data)
          if index > depth_limit
              break
          end
          get_table_design(item, current_path, design, depth_limit)
      end
  else
      design[current_path] = current_path
  end
  return design
end
