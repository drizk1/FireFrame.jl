module FireFrame

using DataFrames
using OrderedCollections: OrderedDict
using HTTP, JSON

include("docstrings.jl")

export fireframe, search_resource, print_paths, get_table_design

## `extract_value` would not be exported 
function extract_value(data, keys_path, hierarchy = "")
    for (index, key) in enumerate(keys_path)
            ## Leaving hierarchy as a place holder in case 
            ## I can one day figure out how to get it in there. 
            ##It might be better to use cardinality from FHIR?

        if isa(data, Dict)
            data = get(data, key, "na")
        elseif isa(data, Array)
            data = [extract_value(element, keys_path[index:end], hierarchy) for element in data]
            break
        else
            return "na"
        end


    end

    if isa(data, Array)
        return join([d for d in data if d !== "na"], " ~ ")
    else
        return data === "na" ? "na" : hierarchy * string(data)
    end
end

#"""
#$docstring_fireframe
#"""
function fireframe(object, column_design)
   # global depth_counter
   # depth_counter = 1 holder over from hierarchy
    ordered_column_design = OrderedDict(column_design)
    patient_df = DataFrame([Symbol(col_name) => String[] for col_name in keys(ordered_column_design)])

    for entry in object["entry"]
        resource = entry["resource"]
        row_values = []

        for (col_name, path) in ordered_column_design
            keys_path = split(path, '.')
            value = extract_value(resource, keys_path)
            final_value = value === missing ? missing : value
            push!(row_values, final_value)
        end
        if length(row_values) != length(keys(ordered_column_design))
            # Fill missing values with "NA"
            row_values = resize!(row_values, length(keys(ordered_column_design)), missing)
        end

        push!(patient_df, Tuple(row_values))
    end

    patient_df = patient_df[:, Symbol.(keys(ordered_column_design))]
    return patient_df
end

#"""
#$docstring_search_resource
#"""
function search_resource(base_url::String, resource::String; max_entries::Union{Int, Nothing} = nothing, extra_params::Dict{String, String} = Dict{String, String}(), readtimeout::Int = 60)
    # Construct the search URL
    search_url = "$(base_url)/$(resource)"

    # Set the base parameters
    params = isnothing(max_entries) ? Dict() : Dict("_count" => string(max_entries))

    # Merge extra parameters with the base parameters
    for (key, value) in extra_params
        params[key] = value
    end

    # Check if params is empty and make the GET request accordingly
    response = isempty(params) ? HTTP.get(search_url, readtimeout=readtimeout) : HTTP.get(search_url, query=params, readtimeout=readtimeout)

    # Check if the request was successful
    if response.status == 200
        # Parse the JSON response
        patient_bundles = JSON.parse(String(response.body))
        return patient_bundles  # Return the parsed data
    else
        error("Request failed with status code: $(response.status)")
    end
end


#"""
#$docstring_print_paths
#"""
function print_paths(json_data, current_path = ""; depth_limit = 1, is_top_level = true)
    if isa(json_data, Dict)
        for (key, value) in json_data
            new_path = current_path == "" ? key : current_path * "." * key
            print_paths(value, new_path; depth_limit = depth_limit, is_top_level = false)
        end
    elseif isa(json_data, Array)
        for (index, item) in enumerate(json_data)
            if index > depth_limit
                break  # Skip processing if the index is beyond the depth limit
            end
            new_path = current_path * "[" * string(index) * "]" 
            print_paths(item, new_path; depth_limit = depth_limit, is_top_level = false)
        end
    else
        println("$current_path: $json_data")  # Print the path and the scalar value
    end

    if is_top_level  # Print summary message only in the top-level call
        println("Printed $depth_limit elements from $(current_path == "" ? "root" : current_path).")
    end
end


#"""
#$docstring_get_table_design
#"""
function get_table_design(json_data, current_path = "", design = OrderedDict{String, String}(); depth_limit = nothing)
    if isa(json_data, Dict)
        for (key, value) in json_data
            new_path = current_path == "" ? key : current_path * "." * key
            # Remove "entry.resource." from the path
            new_path = replace(new_path, "entry.resource." => "")
            get_table_design(value, new_path, design; depth_limit = depth_limit)
        end
    elseif isa(json_data, Array)
        for (index, item) in enumerate(json_data)
            if !isnothing(depth_limit) && index > depth_limit
                break
            end
            get_table_design(item, current_path, design; depth_limit = depth_limit)
        end
    else
        design[current_path] = current_path
    end
    return design
end


end