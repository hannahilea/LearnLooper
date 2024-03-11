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
const INPUT_SPANS = [[(2.3, 6.498), (6.498, 10.6)], 
                     [(2.3, 6.498), (6.498, 10.6)]]

const INPUT_PATH = Ref{String}(INPUT_PATHS[1])
const SPANS = Ref{Any}(INPUT_SPANS[1])
const UI_CONFIG = LearnLooper.Config()

struct PlaybackState

#####
##### Behavior
#####

const PLAYBACK_THREAD = Ref{Union{Nothing,String}}(nothing)

function on_play_pause_clicked(widgetptr, user_data)
    @debug "play/pause clicked"

    # # g_timeout_add can be used to periodically call a function from the main loop
    # Gtk4.GLib.g_timeout_add(50) do  # create a function that will be called every 50 milliseconds
    #     label.label = "counter: $(COUNTER[])"
    #     return time() < stop_time   # return true to keep calling the function, false to stop
    # end

    if !isnothing(PLAYBACK_THREAD)
        @info "Is playing! Can't cancel yet :("
        #TODO-future: support canceling
    else
        Threads.@spawn begin
            tid = Threads.threadid()
            PLAYBACK_THREAD[] = tid
            @info tid typeof(tid)
            tp = Threads.threadpool()

            # Interacting with GTK from a thread other than the main thread is
            # generally not allowed, so we register an idle callback instead.
            function state_callback(state)
                Gtk4.GLib.g_idle_add() do
                    print("Playback state: state", out)
                    return false # #TODO: does this signal that the callback is done? or something? 
                end
                return nothing
            end

            learn_loop(collect('a':'z'), [1:2, 3:4]; state_callback, config=copy(UI_CONFIG))
            
            Gtk4.GLib.g_idle_add() do
                print("Done playing back on thread $tid in the $tp threadpool: ", out)
                PLAYBACK_THREAD[] = nothing
                return false # pretty sure this signals that our thread is done?? todo: check
            end
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
    # run(`say "launch"`)

    return set_up_gui()
end

end # module LearnLooperGUI
