#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui

using LearnLooper
using Gtk4

# I don't _love_ setting global vars, but that's where we're at right now.
# Also, as long as we can only have one app at a time, it really shouldn't matter...

#TODO-future: update different demo path
# TODO: combine these into some input struct type
const INPUT_PATHS = [joinpath(pkgdir(LearnLooper), "..", "demos", "2024-02-29_RC2",
                              "KillavilJigSlowFlute.wav"),
                     joinpath(pkgdir(LearnLooper), "..", "demos", "2024-02-29_RC2",
                              "KillavilJigVariations.wav")]
const INPUT_SPANS = [[(2.3, 6.498), (6.498, 10.6)], [(2.3, 6.498), (6.498, 10.6)]]

const INPUT_PATH = Ref{String}(INPUT_PATHS[1])
const NUM_REPETITIONS = Ref{Int}(3)
const DRY_RUN = Ref{Bool}(false)
const ITERATION_MODE = Ref{Symbol}(:sequential)
const SPANS = Ref{Any}(INPUT_SPANS[1])

#####
##### Behavior
#####

const PLAYBACK_STATE = Ref{Union{Nothing,String}}(nothing)

function on_play_pause_clicked(widgetptr, user_data)
    @debug "play/pause clicked"
    if isnothing(PLAYBACK_STATE)
       # Start playing!! 
       play_looper()
    else 
        pause_looper()
    end

    # # g_timeout_add can be used to periodically call a function from the main loop
    # Gtk4.GLib.g_timeout_add(50) do  # create a function that will be called every 50 milliseconds
    #     label.label = "counter: $(COUNTER[])"
    #     return time() < stop_time   # return true to keep calling the function, false to stop
    # end

    Threads.@spawn begin
        tid = Threads.threadid()
        tp = Threads.threadpool()

        @debug "Playing" tid tp
        out = learn_loop(collect('a':'z'), [1:2, 3:4]; num_repetitions=1,
                         iteration_mode=:sequential, dryrun=DRY_RUN_MODE[])

        # Interacting with GTK from a thread other than the main thread is
        # generally not allowed, so we register an idle callback instead.
        Gtk4.GLib.g_idle_add() do
            print("Thread $tid in the $tp threadpool: ", out)
            return false
        end
    end
    return nothing
end

function on_dry_run_clicked(_, data)
    dryrun_mode = DRY_RUN_MODE[]
    println("Dry run mode ", dryrun_mode ? "disabled" : "enabled", "!")
    DRY_RUN_MODE[] = !dryrun_mode
    data.button.label = dryrun_mode ? "Enable dry run mode" : "Disable dry run mode"
    return nothing
end

#####
##### GUI
#####

const COUNTER = Ref(0)

DRY_RUN_MODE = Ref(false)

function set_up_gui()
    box = GtkBox(:v; name="content_box")

    # Add buttons to UI
    dry_run_button = GtkButton("Dry run \n 🚧")
    push!(box, dry_run_button)
    Gtk4.on_clicked(on_dry_run_clicked, dry_run_button, (button=dry_run_button,))

    play_pause_button = GtkButton("Learn loop! \n ⏯️")
    push!(box, play_pause_button)
    Gtk4.on_clicked(on_play_pause_clicked, play_pause_button, ("foo", "bar"))

    # Finally, set up the main app window itself!
    win = GtkWindow("LearnLooper!", 420, 200, false) # Last arg is "resizable" TODO-future: add Gtk function for setting via kwargs
    push!(win, box)
    return win
end

function launch_gui()
    if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
        @warn("This application is intended to be run with multiple threads enabled, e.g. `julia --threads=2`")
    end
    run(`say "launch gui"`)

    return set_up_gui()
end

end # module LearnLooperGUI
