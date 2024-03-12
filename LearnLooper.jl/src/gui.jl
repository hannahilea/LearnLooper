#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui
export set_up_gui # TODO-remove export

using LearnLooper
using Gtk4, Gtk4.GLib

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
const LEARNLOOP_CONFIG = LearnLooper.Config()

#####
##### Behavior
#####

# const PLAYBACK_THREAD = Ref{Union{Nothing,Int64}}(nothing)
const PLAYBACK_CONTROLLER = Ref{Union{Nothing,LearnLooper.PlaybackController}}(nothing)

function on_play_pause_clicked(_, data)
    @debug "play/pause clicked"

    if !isnothing(PLAYBACK_CONTROLLER[])
        @debug "Attempting to cancel" PLAYBACK_CONTROLLER[]
        data.loop_state_label.label = "Cancelling playback"
        PLAYBACK_CONTROLLER[].stop_asap = true # Will stop playback at end of next loop
    else
        @debug "Started playing (allegedly)"
        data.button.label = "Currently playing!"
        data.loop_state_label.label = "button pushed"
        PLAYBACK_CONTROLLER[] = LearnLooper.PlaybackController()
        Threads.@spawn begin
            @debug "Thread id $(Threads.threadid())"

            # Interacting with GTK from a thread other than the main thread is
            # generally not allowed, so we register an idle callback instead.
            function state_callback(state)
                @debug "Callback" state
                Gtk4.GLib.g_idle_add() do
                    @debug("Callback on main: ", state)
                    data.loop_state_label.label = "$(state.state) span $(state.i_span)"
                    return false
                end
                return nothing
            end

            learn_loop(collect('a':'z'), [1:2, 3:4]; state_callback,
                       controller=PLAYBACK_CONTROLLER[],
                       config=LEARNLOOP_CONFIG)

            Gtk4.GLib.g_idle_add() do
                @debug "Done playing back"
                PLAYBACK_CONTROLLER[] = nothing
                data.button.label = "Learn loop! (i.e. Play)"
                data.loop_state_label.label = "nothing"
                return false
            end
        end
    end
    return nothing
end

function on_dry_run_clicked(_, data)
    dryrun_mode = LEARNLOOP_CONFIG.dryrun
    println("Dry run mode ", dryrun_mode ? "disabled" : "enabled", "!")
    LEARNLOOP_CONFIG.dryrun = !dryrun_mode
    data.button.label = dryrun_mode ? "Enable dry run mode" : "Disable dry run mode"
    return nothing
end

#####
##### GUI
#####

function set_up_gui()
    box = GtkBox(:v; name="content_box")

    # Base.@kwdef mutable struct Config
    #     num_repetitions::Union{Missing,Int} = 2
    #     iteration_mode = :sequential
    #     interrepeat_pause = 0
    #     pause_for_response::Bool = true
    #     speed = 1
    #     dryrun::Bool = false
    # end

    # b1 = GtkButton("num_repetitions")
    # b2 = GtkButton("iteration_mode")
    # b3 = GtkButton("3")
    # b_plus = GtkButton("interrepeat_pause")
    # b4 = GtkButton("pause_for_response")
    # b5 = GtkButton("speed")

    # Add iteration mode radio buttons
    #TODO-future: make helper function that does this
    let
        hbox = GtkBox(:h; name="iteration_mode_box")
        push!(hbox, GtkLabel("Iteration mode: "))
        push!(hbox,
              GtkToggleButton("Cumulative"; action_name="iteration_mode.option",
                              action_target=GVariant("cumulative"), group=hbox))
        push!(hbox,
              GtkToggleButton("Sequential"; action_name="iteration_mode.option",
                              action_target=GVariant("sequential"), group=hbox))
        push!(box, hbox)

        function iteration_mode_option_callback(a, v)
            Gtk4.GLib.set_state(a, v)
            LEARNLOOP_CONFIG.iteration_mode = Symbol(v[String])
            return nothing
        end

        action_group = GSimpleActionGroup()
        add_stateful_action(GActionMap(action_group), "iteration_mode_option", String,
                            string(LEARNLOOP_CONFIG.iteration_mode), iteration_mode_option_callback)
        push!(box, Gtk4.GLib.GActionGroup(action_group), "iteration_mode")
    end

    # Add buttons to UI
    dry_run_button = GtkButton(LEARNLOOP_CONFIG.dryrun ? "Disable dry run mode" :
                               "Enable dry run mode")
    push!(box, dry_run_button)
    # Gtk4.on_clicked(on_dry_run_clicked, dry_run_button, (button=dry_run_button,))

    loop_state_label = Gtk4.GtkLabel("Loop state: nothing")
    push!(box, loop_state_label)

    play_pause_button = GtkButton("Learn loop!😄 ✔️")
    push!(box, play_pause_button)
    # Gtk4.on_clicked(on_play_pause_clicked, play_pause_button,
    #                 (button=play_pause_button, loop_state_label))

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
