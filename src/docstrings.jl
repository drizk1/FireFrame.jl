const docstring_search_resource = 
"""
    search_resource(base_url::String, resource::String; max_entries::Union{Int, Nothing} = nothing, extra_params::Dict{String, String} = Dict{String, String}(), readtimeout::Int = 60)

Search for a specified resource on a base URL and return the results in JSON format.

This function constructs a URL using the `base_url` and `resource` provided, optionally limiting the number of entries returned based on `max_entries`. It then performs an HTTP GET request to the constructed URL. If the request is successful, it parses and returns the JSON response. If the request fails, it raises an error with the status code.

# Arguments
- `base_url::String`: The base URL of the API or resource server.
- `resource::String`: The specific resource or endpoint to be accessed.
- `max_entries::Union{Int, Nothing}`: Optional. Maximum number of entries to return. If `nothing`, server limit is applied.
- `extra_params::Dict{String, String}`: Optional. Allows user to query specific to additional params 
# Returns
- `Dict`: A dictionary containing the parsed JSON data from the response.

# Examples
```jldoctest
julia> search_resource("https://hapi.fhir.org/baseR4", "Patient");
```
"""

const docstring_get_table_design =
"""
    get_table_design(json_data, current_path = "", design = OrderedDict{String, String}(), depth_limit = 1) -> OrderedDict{String, String}

Returns an OrderedDict from nested JSON data. This function recursively traverses the JSON data structure, building a path for each element. The path represents the hierarchical location of the element within the JSON structure. The resulting design is an ordered dictionary where keys are paths and values are the corresponding elements' paths.

The traversal stops when it reaches the specified depth limit. For arrays, only the first `depth_limit` elements are considered. 

# Arguments
- `json_data`: The JSON data to be traversed. It can be a `Dict` or an `Array`.
- `current_path::String`: Internal use. The accumulated path during the traversal. Defaults to an empty string.
- `design::OrderedDict{String, String}`: Internal use. The accumulated design mapping during the traversal. Defaults to an empty `OrderedDict`.
- `depth_limit::Int`: The depth limit for traversal within arrays. Defaults to 1.

# Returns
- `OrderedDict{String, String}`: An ordered dictionary where each key is a unique path within the JSON structure, and its value is the same path.

# Examples
```jldoctest
julia> json_data = JSON.parse("{\"patient\": {\"name\": \"John\", \"age\": 30, \"conditions\": [{\"type\": \"diabetes\"}, {\"type\": \"hypertension\"}]}}")
julia> get_table_design(json_data)
OrderedDict("patient.name" => "patient.name", "patient.age" => "patient.age", "patient.conditions.type" => "patient.conditions.type")
OrderedDict{String, String} with 3 entries:
  "patient.name"            => "patient.name"
  "patient.conditions.type" => "patient.conditions.type"
  "patient.age"             => "patient.age" 
```
"""

const docstring_print_paths =
"""
    print_paths(json_data, current_path = "", depth_limit = 1, is_top_level = true)

This function is particularly useful for viewing and understanding the structure of complex JSON data and for debugging purposes.

For dictionary entries, the path is formed by concatenating the keys with a dot. For array elements, the path includes the index in square brackets. The function prints each path followed by the corresponding value. If a depth limit is set for arrays, only elements up to that index are printed.

# Arguments
- `json_data`: The JSON data to be traversed, which can be a `Dict` or an `Array`.
- `current_path::String`: Internal use. Accumulated path during traversal. Defaults to an empty string.
- `depth_limit::Int`: The depth limit for traversal within arrays. Defaults to 1.
- `is_top_level::Bool`: Internal use. Indicates if the current call is the top-level call. Defaults to true.

# Examples
```julia
julia> json_data = JSON.parse("{\"patient\": {\"name\": \"John\", \"age\": 30, \"conditions\": [{\"type\": \"diabetes\"}, {\"type\": \"hypertension\"}]}}")
julia> print_paths(json_data)
patient.name: John
patient.conditions[1].type: diabetes
patient.conditions[2].type: hypertension
patient.age: 30
Printed 2 elements from root.
```
"""


const docstring_fireframe =
"""
    fireframe(object::Dict, column_design::OrderedDict) -> DataFrame

Creates a wide DataFrame from a JSON object based on a specified column design. The function expects the JSON object to have a top-level "entry" key, each entry containing a "resource" key that holds the data to be transformed into the DataFrame.

The `column_design` should be an `OrderedDict` where each key is a column name in the resulting DataFrame, and its value is the corresponding path to extract the data from within each "resource" in the JSON object.

# Arguments
- `object::Dict`: The JSON object. Expected to have a top-level "entry" key.
- `column_design::OrderedDict`: An ordered dictionary defining the column names and their corresponding paths in the JSON object.

# Returns
- `DataFrame`: A DataFrame where each column corresponds to a specified path in the JSON data as defined in `column_design`. Missing values are filled with "NA".

# Example
```julia
julia> json_data = JSON.parse("{\"patient\": {\"name\": \"John\", \"age\": 30, \"conditions\": [{\"type\": \"diabetes\"}, {\"type\": \"hypertension\"}]}}")
julia> fireframe(json_data_with_entry, get_table_design(json_data))
1×3 DataFrame
 Row │ patient.name  patient.conditions.type  patient.age 
     │ String        String                   String      
─────┼────────────────────────────────────────────────────
   1 │ John          diabetes ~ hypertension  30
```
"""

