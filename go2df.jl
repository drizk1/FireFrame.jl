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

## this function takes the results of a search_resource query and a column design as an ordered dict and makes a wide dataframe. 
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

## allows the user to easily get from a resource.
function search_resource(base_url::String, resource::String; max_entries::Union{Int, Nothing} = nothing)
    # Construct the search URL
    search_url = "$(base_url)/$(resource)"

    # Set the parameters for the search
    params = isnothing(max_entries) ? Dict() : Dict("_count" => max_entries)

    # Make the GET request
    response = HTTP.get(search_url, query=params)

    # Check if the request was successful
    if response.status == 200
        # Parse the JSON response
        patient_bundles = JSON.parse(String(response.body))
        return patient_bundles  # Return the parsed data
    else
        error("Request failed with status code: $(response.status)")
    end
end


## A function to check all available paths and the contents.
function print_paths(json_data, current_path = "", depth_limit = 1, is_top_level = true)
    if isa(json_data, Dict)
        for (key, value) in json_data
            new_path = current_path == "" ? key : current_path * "." * key
            print_paths(value, new_path, depth_limit, false)
        end
    elseif isa(json_data, Array)
        for (index, item) in enumerate(json_data)
            if index > depth_limit
                break  # Skip processing if the index is beyond the depth limit
            end
            new_path = current_path * "[" * string(index) * "]" 
            print_paths(item, new_path, depth_limit, false)
        end
    else
        println("$current_path: $json_data")  # Print the path and the scalar value
    end

    if is_top_level  # Print summary message only in the top-level call
        println("Printed $depth_limit of $(length(json_data)) elements.")
    end
end

## Builds an OrderedDict draft that the user can easily and rapidly edit for later use to build the DataFrame.
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












### Early XML Draft before I switched to method used above. +/- if i move further into xmls. If that is where the need and use are (not with jsons), i would be encouraged to continue xmls stuff.
struct FHIRColumn
    resource_type::String
    column_name::String
    path::String
end

function extract_data(node::EzXML.Node, design::Vector{FHIRColumn})
    data = Dict{String, Vector{String}}()

    for col in design
        data[col.column_name] = String[]
    end

    function process_node(node, path=String[])
        tag = nodename(node)
        extended_path = [path..., tag]

        # Debugging: Print current node and path
        println("Current node: ", tag)
        println("Extended path: ", join(extended_path, "_"))

        for col in design
            if join(extended_path, "_") == col.path
                println("Extracting data for column: ", col.column_name)  # Debugging
                value = haskey(node, "value") ? node["value"] : nodecontent(node)
                if isa(value, String)
                    push!(data[col.column_name], strip(value))
                else
                    push!(data[col.column_name], "")
                end
            end
        end
        

        for child in eachelement(node)
            process_node(child, extended_path)
        end
    end

    process_node(node)
    return data
end

function extract_complex_value(node::EzXML.Node)
    complex_value = ""

    function concatenate_children(node, level = 0)
        for child in eachelement(node)
            tag = nodename(child)
            value = haskey(child, "value") ? child["value"] : nodecontent(child)

            # Indent based on the level in the XML structure to add structure to the output
            indent = " " ^ (level * 2)
            complex_value *= indent * tag * ": " * strip(value) * "\n"

            concatenate_children(child, level + 1)
        end
    end

    concatenate_children(node)
    return strip(complex_value)
end
function xml_to_dataframe_flattened(xml_node::EzXML.Node, design::Vector{FHIRColumn})
    data = extract_data(xml_node, design)

    # Normalize column lengths by padding with empty strings
    max_length = maximum(length.(values(data)))
    for (colname, values) in data
        if length(values) < max_length
            data[colname] = append!(values, fill("", max_length - length(values)))
        end
    end

    # Convert the collected data into a DataFrame
    df = DataFrame(data)

    # Handle empty columns
    for col in names(df)
        if all(isempty, df[!, col])
            select!(df, Not(col))
        end
    end

    return df
end

function xml_to_dataframe41(xml_node::EzXML.Node)
    # Initialize an empty DataFrame
    df = DataFrame(main_tag=String[], main_value=String[], child_tag=String[], child_value=String[])

    # Function to check if a node is a text formatting element
    function is_text_formatting_element(tag)
        tag in ["div", "p", "b", "span", "a", "h3", "table", "tr", "td", "th"]
    end

    # Function to process each node and its children
    function process_node(node, main_tag="", main_value="")
        tag = nodename(node)
        value = haskey(node, "value") ? node["value"] : ""

        # Skip text formatting elements
        if is_text_formatting_element(tag)
            return
        end

        if isempty(eachelement(node))  # Check if it's a leaf node
            if main_tag != ""
                # It's a child node, add to DataFrame with its parent
                push!(df, (main_tag, main_value, tag, value))
            else
                # It's a main node without children, add to DataFrame
                push!(df, (tag, value, "", ""))
            end
        else
            # Process child nodes
            for child in eachelement(node)
                process_node(child, tag, value)
            end
        end
    end

    # Start processing from the root node
    process_node(xml_node)

    return df
end