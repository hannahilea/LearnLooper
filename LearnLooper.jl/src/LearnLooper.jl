module LearnLooper

using WAV

export learn_loop, launch_gui

struct WAVData
    sample_rate::Any
    samples::Any
end

function WAVData(file)
    y, fs = wavread(file)
    return WAVData(fs, y)
end

Base.@kwdef mutable struct Config
    num_repetitions::Union{Missing,Int} = 2
    iteration_mode = :sequential
    interrepeat_pause = 0
    pause_for_response::Bool = true
    speed = 1
    dryrun::Bool = false
end

Base.@kwdef mutable struct PlaybackController
    stop_asap::Bool = false # used to cancel mid-run
end

struct PlayStateRecord
    state::Symbol
    # i::Int #TODO: make this so 
    span::Any
end

#####
##### Base extensions
#####

for pred in (:(==), :(isequal)),
    T in [PlayStateRecord, Config]

    @eval function Base.$pred(x::$T, y::$T)
        return all(f -> $pred(getproperty(x, f), getproperty(y, f)), fieldnames($T))
    end
end

"""
    play(input; volume=1, speed) -> nothing
    play(input::WAVData; volume=1, speed) -> nothing

Play `input` scaled to `volume`, at playback `speed` (where e.g. a speed of 2 is
loop_record twice as fast as the original). 

!!! warn
  `input` that is not `WavData` is loop_record back via the OS's text to speech 
  program, and is currently only supported on Mac .
"""
function play(input; volume=1, speed)
    seg = string(input)
    rate = speed * 230
    @debug "$(volume == 0 ? "🎤Pausing" : "👂Playing"): $input"
    Sys.isapple() && run(`say \[\[volm $(volume)\]\] \[\[rate $rate\]\] $seg`)
    return nothing
end

function play(input::WAVData; volume=1, speed)
    @debug "$(volume == 0 ? "🎤Pausing" : "👂Playing WAVData segment")"
    samples = input.samples
    sample_rate = input.sample_rate

    if speed != 1
        @warn "Not yet implemented!"
    end

    #TODO-future: fix cross-platform playback!!
    try
        wavplay(volume .* samples, sample_rate)
    catch err
        # @warn "wavplay seems to be broken for your system...." ref = "https://github.com/dancasimiro/WAV.jl/issues/89#issuecomment-719960504" err
    end
    return nothing
end

"""
    pause(input; kwargs...) -> nothing

Pause for the duration it would take to `play(input; kwargs...)`, respecting kwargs
that affect the duration of input playback (e.g., `speed`). For list of `kwargs`,
see [`play`](@ref).
"""
pause(input; kwargs...) = play(input; volume=0, kwargs...)

function collect_span(i_span, spans; iteration_mode)
    if iteration_mode == :cumulative
        current_spans = spans[1:i_span]
        return length(current_spans) == 1 ? only(current_spans) :
               collect(Iterators.flatten(spans[1:i_span]))
    end
    if iteration_mode != :sequential
        @warn "`iteration_mode=$mode` is unsupported; falling back to `:sequential` (options: `sequential`, `cumulative`)"
    end
    return spans[i_span]
end

# If input is a single string, split it into words
preprocess_input(input) = input
preprocess_input(input::Number) = string(input)

#TODO-future: better way to identify file input (support other WAVData suffixes....)
function preprocess_input(input::String)
    return endswith(input, ".wav") ? WAVData(input) : string.(split(input, " "))
end

function index_for_sec_spans(spans, sample_rate)
    return map(spans) do s
        ind = Int(floor(first(s) * sample_rate)):Int(floor(last(s) * sample_rate))
        return first(ind) == 0 ? (1:last(ind)) : ind
    end
end

_slice(input, span) = input[span] # TODO-future: use view instead where valid

function _slice(input::WAVData, span)
    # TODO lol there has to be a better way :) 
    return WAVData(input.sample_rate, view(input.samples, span, :))
end

function validate_input(input, spans)
    #TODO-future: safety-check span v input length
    #TODO-future: if playing text, warn if not mac
    return nothing
end

function prepare_input(input, spans)
    input = preprocess_input(input)
    isa(input, WAVData) && (spans = index_for_sec_spans(spans, input.sample_rate))

    validate_input(input, spans)
    return input, spans
end

#####
##### Main entrypoint
#####

"""
    learn_loop(input, spans; config::Config, 
               state_callback::Function = _ -> nothing) -> nothing

Present the `spans` of `input` as a series of calls ([`play`](@ref)) and responses
[`pause`](@ref)). This is the end-user entrypoint into LearnLooper.jl.

Arguments:
* `input`: TODO-docstring
* `spans`: TODO-docstring
* `config::Config`: See [`Config`](@ref) for parameters.
* `state_callback`: Function that takes [`PlayStateRecord`](@ref) as input and 
    returns `nothing`; called whenever internal learning state (play/pause) changes.
    Final callback at conclusion of `learn_loop` will always have a state of either 
    `PlayStateRecord(:completed,missing)` or `PlayStateRecord(:stopped,missing)`.

Non-contiguous `spans` may result in a click in cumulative iteration mode.
"""
function learn_loop(input, spans; config::Config, controller = PlaybackController(), state_callback::Function=_ -> nothing)
    input, spans = prepare_input(input, spans)
    @info "Started learn loop..." config controller

    for i in eachindex(spans)
        controller.stop_asap && continue
        span = collect_span(i, spans; config.iteration_mode)
        slice = _slice(input, span)

        i_rep = 1
        while !(controller.stop_asap) && (ismissing(config.num_repetitions) || i_rep <= config.num_repetitions)
            state_callback(PlayStateRecord(:playing, span))
            config.dryrun || play(slice; config.speed)
            controller.stop_asap && break

            if config.pause_for_response
                state_callback(PlayStateRecord(:pausing, span))
                config.dryrun || pause(slice; config.speed)
                controller.stop_asap && break
            end

            if config.interrepeat_pause != 0
                state_callback(PlayStateRecord(:pausing, config.interrepeat_pause))
                config.dryrun || sleep(config.interrepeat_pause)
                controller.stop_asap && break
            end
            i_rep += 1
        end
    end
    state_callback(PlayStateRecord(controller.stop_asap ? :stopped : :completed, missing))
    return nothing
end

include("gui.jl")
using .LearnLooperGUI

end # module LearnLooper
