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

function on_iteration_mode_changed_callback(a, v)
    Gtk4.GLib.set_state(a, v)
    LEARNLOOP_CONFIG.iteration_mode = Symbol(v[String])
    @debug LEARNLOOP_CONFIG
    return nothing
end

function on_pause_for_response_changed_callback(a, v)
    Gtk4.GLib.set_state(a, v)
    LEARNLOOP_CONFIG.pause_for_response = v[String] == "enabled"
    @debug LEARNLOOP_CONFIG
    return nothing
end

function on_dryrun_mode_changed_callback(a, v)
    Gtk4.GLib.set_state(a, v)
    LEARNLOOP_CONFIG.dryrun = v[String] == "enabled"
    @debug LEARNLOOP_CONFIG
    return nothing
end

function on_speed_value_changed(widgetptr, _)
    widget = convert(Gtk4.GtkScale, widgetptr)
    LEARNLOOP_CONFIG.speed = Gtk4.value(widget)
    @debug LEARNLOOP_CONFIG
    return nothing
end

function on_interrepeat_pause_changed(widgetptr, _)
    widget = convert(Gtk4.GtkScale, widgetptr)
    LEARNLOOP_CONFIG.interrepeat_pause = Gtk4.value(widget)
    @debug LEARNLOOP_CONFIG
    return nothing
end

function on_num_repetitions_changed(widgetptr, _)
    widget = convert(Gtk4.GtkScale, widgetptr)
    LEARNLOOP_CONFIG.num_repetitions = Gtk4.value(widget)
    @debug LEARNLOOP_CONFIG
    return nothing
end

#####
##### GUI
#####

function set_up_gui()
    box = GtkBox(:v; name="content_box")

    # Add buttons to UI
    loop_state_label = Gtk4.GtkLabel("Loop state: nothing")
    play_pause_button = GtkButton("Learn loop!😄 ✔️")
    push!(box, play_pause_button)
    Gtk4.on_clicked(on_play_pause_clicked, play_pause_button,
                    (button=play_pause_button, loop_state_label))

    let
        #TODO-future: support inf repetitions (missing)
        hbox = GtkBox(:v; name="num_repetitions_box")
        push!(hbox, GtkLabel("Num repetitions: "))
        num_repetitions_scale = GtkScale(:h, 1, 10, 1; draw_value=true, digits=0)
        Gtk4.on_value_changed(on_num_repetitions_changed, num_repetitions_scale, nothing)
        Gtk4.value(num_repetitions_scale, LEARNLOOP_CONFIG.num_repetitions)
        push!(hbox, num_repetitions_scale)
        push!(box, hbox)
    end

    # TODO-future: map non-linear
    let
        hbox = GtkBox(:v; name="speed_box")
        push!(hbox, GtkLabel("Playback speed: "))
        speed_scale = GtkScale(:h, 0.25, 1.75, 0.1; draw_value=true, digits=2)
        Gtk4.on_value_changed(on_speed_value_changed, speed_scale, nothing)
        Gtk4.value(speed_scale, LEARNLOOP_CONFIG.speed)
        push!(hbox, speed_scale)
        push!(box, hbox)
    end

    let
        hbox = GtkBox(:v; name="interrepeat_pause_box")
        push!(hbox, GtkLabel("Extra pause after repeat [sec]: "))
        interrepeat_pause_scale = GtkScale(:h, 0.0, 3, 0.1; draw_value=true, digits=1)
        Gtk4.on_value_changed(on_interrepeat_pause_changed, interrepeat_pause_scale,
                              nothing)
        Gtk4.value(interrepeat_pause_scale, LEARNLOOP_CONFIG.interrepeat_pause)
        push!(hbox, interrepeat_pause_scale)
        push!(box, hbox)
    end

    # Add iteration mode radio buttons
    #TODO-future: make helper function that does this
    let
        hbox = GtkBox(:h; name="iteration_box")
        push!(hbox, GtkLabel("Iteration mode: "))
        push!(hbox,
              GtkToggleButton("Cumulative"; action_name="iteration_mode.option",
                              action_target=GVariant("cumulative"), group=hbox))
        push!(hbox,
              GtkToggleButton("Sequential"; action_name="iteration_mode.option",
                              action_target=GVariant("sequential"), group=hbox))
        push!(box, hbox)

        action_group = GSimpleActionGroup()
        add_stateful_action(GActionMap(action_group), "option", String,
                            string(LEARNLOOP_CONFIG.iteration_mode),
                            on_iteration_mode_changed_callback)
        push!(box, Gtk4.GLib.GActionGroup(action_group), "iteration_mode")
    end

    # Pause for response radio buttons
    let
        hbox = GtkBox(:h; name="pause_response_box")
        push!(hbox, GtkLabel("Pause for response: "))
        push!(hbox,
              GtkToggleButton("Enabled"; action_name="pause_response_mode.option",
                              action_target=GVariant("enabled"), group=hbox))
        push!(hbox,
              GtkToggleButton("Disabled"; action_name="pause_response_mode.option",
                              action_target=GVariant("disabled"), group=hbox))
        push!(box, hbox)

        action_group = GSimpleActionGroup()
        add_stateful_action(GActionMap(action_group), "option", String,
                            LEARNLOOP_CONFIG.pause_for_response ? "enabled" : "disabled",
                            on_pause_for_response_changed_callback)
        push!(box, Gtk4.GLib.GActionGroup(action_group), "pause_response_mode")
    end

    # Dry run radio buttons
    let
        hbox = GtkBox(:h; name="dryrun_box")
        push!(hbox, GtkLabel("Dryrun mode: "))
        push!(hbox,
              GtkToggleButton("Enabled"; action_name="dryrun_mode.option",
                              action_target=GVariant("enabled"), group=hbox))
        push!(hbox,
              GtkToggleButton("Disabled"; action_name="dryrun_mode.option",
                              action_target=GVariant("disabled"), group=hbox))
        push!(box, hbox)

        action_group = GSimpleActionGroup()
        add_stateful_action(GActionMap(action_group), "option", String,
                            LEARNLOOP_CONFIG.dryrun ? "enabled" : "disabled",
                            on_dryrun_mode_changed_callback)
        push!(box, Gtk4.GLib.GActionGroup(action_group), "dryrun_mode")
    end

    push!(box, loop_state_label)

    # Finally, set up the main app window itself!
    win = GtkWindow("LearnLooper!", 420, 420, false) # Last arg is "resizable"
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
