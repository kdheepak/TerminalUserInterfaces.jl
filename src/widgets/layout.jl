abstract type SizingConstraint end

struct Min <: SizingConstraint
    value::Int
end

struct Max <: SizingConstraint
    value::Int
end

struct Percentage <: SizingConstraint
    value::Int
end

@kwdef struct Horizontal
    widgets::Vector{T} where {T}
    constraints::Vector{SizingConstraint}
end

@kwdef struct Vertical
    widgets::Vector{T} where {T}
    constraints::Vector{SizingConstraint}
end

function render(layout::Union{Horizontal, Vertical}, area::Rect, buf::Buffer)
    if length(layout.widgets) != length(layout.constraints)
        throw(ArgumentError("Number of widgets must match the number of constraints"))
    end

    orientation = layout isa Horizontal ? :horizontal : :vertical

    start_pos = orientation == :horizontal ? left(area) : top(area)
    total_space = orientation == :horizontal ? width(area) : height(area)

    min_and_max_lengths = Int[]
    percentage_constraints = Int[]
    for constraint in layout.constraints
        if constraint isa Min
            push!(percentage_constraints, 0)
            push!(min_and_max_lengths, constraint.value)
        elseif constraint isa Max
            push!(percentage_constraints, 0)
            push!(min_and_max_lengths, constraint.value)
        elseif constraint isa Percentage
            push!(percentage_constraints, constraint.value)
            push!(min_and_max_lengths, 0) # Placeholder for percentage
        else
            throw(ArgumentError("Invalid constraint"))
        end
    end

    # Calculate the remaining length for percentage constraints
    remaining_length = total_space - sum(min_and_max_lengths)
    for (i, constraint) in enumerate(layout.constraints)
        if constraint isa Percentage
            min_and_max_lengths[i] = (percentage_constraints[i] * remaining_length) ÷ 100
        end
    end

    # If there's any Min constraint, distribute the remaining width equally to all Min constraints
    remaining_length = total_space - sum(min_and_max_lengths)
    num_min_constraints = count(c -> c isa Min, layout.constraints)
    if num_min_constraints > 0 && remaining_length > 0
        extra_length_per_min = div(remaining_length, num_min_constraints)
        for (i, constraint) in enumerate(layout.constraints)
            if constraint isa Min
                min_and_max_lengths[i] += extra_length_per_min
            end
        end
    end

    # Render the widgets with appropriate orientation
    for (widget, length) in zip(layout.widgets, min_and_max_lengths)
        rect = orientation == :horizontal ? Rect(start_pos, top(area), length - 1, height(area)) : Rect(left(area), start_pos, width(area), length - 1)

        render(widget, rect, buf)
        start_pos += length
    end
end
