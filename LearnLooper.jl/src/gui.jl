#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui
export set_up_gui # TODO-remove export

using LearnLooper
using Gtk4, Gtk4.GLib

# I don't _love_ setting global vars, but that's where we're at right now.
# Also, as long as we can only have one app at a time, it really shouldn't matter...

const INPUT_PATH = Ref{String}("")
const INPUT_SPANS_PATH = Ref{String}("")

const LEARNLOOP_CONFIG = LearnLooper.Config()
const AUDIO = Ref{Union{Missing,LearnLooper.WAVData}}(missing)
const SPANS = Ref{Union{Missing,Vector}}(missing)

#####
##### Behavior
#####

const PLAYBACK_CONTROLLER = Ref{Union{Nothing,LearnLooper.PlaybackController}}(nothing)

function on_play_pause_clicked(_, data)
    @debug "play/pause clicked"

    if !isnothing(PLAYBACK_CONTROLLER[])
        @debug "Attempting to cancel" PLAYBACK_CONTROLLER[]
        data.loop_state_label.label = "Cancelling playback"
        PLAYBACK_CONTROLLER[].stop_asap = true # Will stop playback at end of next loop
    elseif ismissing(AUDIO[])
        @debug "no audio selected!"
        data.loop_state_label.label = "File must be selected before play"
    else
        # TODO: safety first! if no AUDIO[] refuse to play
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

            learn_loop(AUDIO[], SPANS[]; state_callback,
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

on_next_section_clicked!(args...) = jump_current_span!(1)
on_prev_section_clicked!(args...) = jump_current_span!(-1)

function jump_current_span!(jump_amount)
    if isnothing(PLAYBACK_CONTROLLER[])
        return nothing
    end
    push!(PLAYBACK_CONTROLLER[].jump_amounts, jump_amount)
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

function load_spans_for_audiofile(wavfile)
    # Hella hacky!! TODO-future: make this NICE 
    labelfile = replace(wavfile, ".wav" => ".txt")
    spans = [(1, 5), (5, 9)] #TODO-future: nicer default??
    if isfile(labelfile)
        # Approach 1
        spans = map(readlines(labelfile)) do line
            values = split(line, "\t")
            return Tuple(parse.(Float64, values[1:2]))
        end
    else
        @warn "No span labels found ($labelfile); using default spans"
    end
    @debug "Loaded spans: " spans
    return spans
end

#####
##### GUI
#####

function set_up_gui()
    box = GtkBox(:v; name="content_box")
    win = GtkWindow("LearnLooper!", 420, 420, false) # Last arg is "resizable"
    push!(win, box)

    let
        file_label = Gtk4.GtkLabel("Currently learning: $(basename(INPUT_PATH[]))")
        push!(box, file_label)

        file_open_dialog_button = GtkButton("Select file to learn!")
        push!(box, file_open_dialog_button)

        function open_file_open_dialog(_)
            open_dialog("Select a file to learn", win) do filename
                # @async println("selection was ", filename)
                if !isempty(filename)
                    INPUT_PATH[] = filename
                    @debug filename
                    file_label.label = "Currently learning: $(basename(filename))"
                    AUDIO[] = LearnLooper.WAVData(filename)
                    SPANS[] = load_spans_for_audiofile(filename)
                else
                    @warn "No file selected"
                end
            end
            return nothing
        end
        signal_connect(open_file_open_dialog, file_open_dialog_button, "clicked")
    end

    # Add transport buttons to UI
    transport_box = GtkBox(:v; name="transport_box")
    loop_state_label = Gtk4.GtkLabel("Loop state: nothing")
    play_pause_button = GtkButton("Learn loop!😄 ✔️")
    push!(transport_box, play_pause_button)
    Gtk4.on_clicked(on_play_pause_clicked, play_pause_button,
                    (button=play_pause_button, loop_state_label))
    push!(box, transport_box)

    let
        transport_next_button = GtkButton("Jump to next section")
        Gtk4.on_clicked(on_next_section_clicked!, transport_next_button, missing)
        push!(transport_box, transport_next_button)

        transport_prev_button = GtkButton("Jump to previous section")
        Gtk4.on_clicked(on_prev_section_clicked!, transport_prev_button, missing)
        push!(transport_box, transport_prev_button)
    end

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
    # TODO-un-hide when feature is implemented!
    # let
    #     hbox = GtkBox(:v; name="speed_box")
    #     push!(hbox, GtkLabel("Playback speed: "))
    #     speed_scale = GtkScale(:h, 0.25, 1.75, 0.1; draw_value=true, digits=2)
    #     Gtk4.on_value_changed(on_speed_value_changed, speed_scale, nothing)
    #     Gtk4.value(speed_scale, LEARNLOOP_CONFIG.speed)
    #     push!(hbox, speed_scale)
    #     push!(box, hbox)
    # end

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

    # Set up keyboard as controller
    event_controller = GtkEventControllerKey(win)
    signal_connect(event_controller, "key-pressed") do controller, keyval, keycode, state
        @debug string("You pressed key ", keyval, " which is '", Char(keyval), "'.")
        if keyval == 32 # space bar 
            println(Char(keyval), "` ` pressed")
            on_play_pause_clicked(missing, (button=play_pause_button, loop_state_label))
        elseif keyval == 65363 # right arrow 
            println(Char(keyval), "` ` pressed")
            on_next_section_clicked!()
        elseif keyval == 65361 # left arrow 
            println(Char(keyval), "` ` pressed")
            on_prev_section_clicked!()
        end
        # 65364 # up arrow 
        # 65362 # down arrow 
        # 65361 left arrow
        # 65363 right arrow 

        # "Control-W to close"
        mask = Gtk4.ModifierType_CONTROL_MASK
        if ((ModifierType(state & Gtk4.MODIFIER_MASK) & mask == mask) && keyval == UInt('w'))
            close(widget(event_controller))
        end
    end

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
