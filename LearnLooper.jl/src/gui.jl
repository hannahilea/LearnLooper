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

#####
##### Behavior
#####

const PLAYBACK_THREAD = Ref{Union{Nothing,Int64}}(nothing)

function on_play_pause_clicked(_, data)
    @debug "play/pause clicked"

    # # g_timeout_add can be used to periodically call a function from the main loop
    # Gtk4.GLib.g_timeout_add(50) do  # create a function that will be called every 50 milliseconds
    #     label.label = "counter: $(COUNTER[])"
    #     return time() < stop_time   # return true to keep calling the function, false to stop
    # end

    if !isnothing(PLAYBACK_THREAD[])
        @info "Is playing! Can't cancel yet :("
        data.loop_state_label.label = "NO CAN DO (can't cancel playback yet)"
        #TODO-future: support canceling
    else
        @info "Started playing (allegedly)"
        data.button.label = "Currently playing!"
        data.loop_state_label.label = "button pushed"
        Threads.@spawn begin
            tid = Threads.threadid()
            Gtk4.GLib.g_idle_add() do
                print("Setting playback thread to $tid")
                PLAYBACK_THREAD[] = tid
                return false # #TODO: does this signal that the callback is done? or something? 
            end
            
            @info tid typeof(tid)
           
            # Interacting with GTK from a thread other than the main thread is
            # generally not allowed, so we register an idle callback instead.
            function state_callback(state)
                @debug "Callback" state
                Gtk4.GLib.g_idle_add() do
                    @debug("Callback on main: ", state)
                    data.loop_state_label.label = state.state
                    return false
                end
                return nothing
            end

            learn_loop(collect('a':'z'), [1:2, 3:4]; state_callback, config=deepcopy(UI_CONFIG))
            
            Gtk4.GLib.g_idle_add() do
                print("Done playing back on thread $tid ")
                PLAYBACK_THREAD[] = nothing
                data.button.label = "Learn loop! (i.e. Play)"
                data.loop_state_label.label = "nothing"
                return false
            end
        end
    end
    return nothing
end

function on_dry_run_clicked(_, data)
    dryrun_mode = UI_CONFIG.dryrun
    println("Dry run mode ", dryrun_mode ? "disabled" : "enabled", "!")
    UI_CONFIG.dryrun = !dryrun_mode
    data.button.label = dryrun_mode ? "Enable dry run mode" : "Disable dry run mode"
    return nothing
end

#####
##### GUI
#####

function set_up_gui()
    box = GtkBox(:v; name="content_box")

    # Add buttons to UI
    dry_run_button = GtkButton(UI_CONFIG.dryrun ? "Disable dry run mode" : "Enable dry run mode")
    push!(box, dry_run_button)
    Gtk4.on_clicked(on_dry_run_clicked, dry_run_button, (button=dry_run_button,))

    loop_state_label = Gtk4.GtkLabel("Loop state: nothing")
    push!(box, loop_state_label)

    play_pause_button = GtkButton("Learn loop! \n ⏯️")
    push!(box, play_pause_button)
    Gtk4.on_clicked(on_play_pause_clicked, play_pause_button, (button=play_pause_button, loop_state_label))

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
