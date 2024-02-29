#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui

using LearnLooper
using Gtk4

# const DEFAULT_DARK_LIGHT_THEME = THEME_DEFAULT_LIGHT

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
##### Signals
#####

# function on_mode_switched(self::Switch, app::Application)
#     state = get_is_active(self)
#     @debug "`mode_switch` is now: $state"
#     # set_current_theme!(app, state ? THEME_DEFAULT_LIGHT : THEME_DEFAULT_DARK)
#     return nothing
# end

# function on_dryrun_switched(self::Switch)
#     state = get_is_active(self)
#     @debug "`dryrun_switch` is now: $state"
#     DRY_RUN[] = state
#     return nothing
# end

# function on_play_toggled(self::ToggleButton)
#     state = get_is_active(self)
#     @debug "`play_button` is now: $state"
#     set_child!(self, Label(state ? "Pause learning" : "Learn loop!"))

#     function mid_learn_callback(state)
#         if state == "Play"
#             # TODO: implement early exit by this, if pause button hit....?
#             # println("State ", state)
#         end
#         @debug string("State ", state)
#         return nothing
#     end

#     if state
#         out = learn_loop(INPUT_PATH[], SPANS[]; num_repetitions=NUM_REPETITIONS[],
#                          iteration_mode=ITERATION_MODE[], dryrun=DRY_RUN[]) #,
#         #  state_callback=mid_learn_callback)
#         println(out)
#         set_is_active!(self, false)
#     end
#     return nothing
# end

#####
##### GUI
#####

# function construct_gui!(app::Application, window)
#     header_bar = get_header_bar(window)

#     # Update window title
#     set_title!(window, "Learn Looper")

#     # Add play/pause button 
#     play_button = let
#         button = ToggleButton()
#         set_child!(button, Label("Learn loop!")) #TODO: add emoji! (and in function)
#         connect_signal_toggled!(on_play_toggled, button)
#         button
#     end

#     # Add dark/light mode toggle
#     dark_mode_button = let
#         switch = Switch()
#         set_is_active!(switch, DEFAULT_DARK_LIGHT_THEME == THEME_DEFAULT_LIGHT)
#         switch_box = vbox(switch, Label("Dark/light"))
#         set_horizontal_alignment!(switch, ALIGNMENT_CENTER)
#         set_margin!(switch, 10)
#         connect_signal_switched!(on_mode_switched, switch, app)
#         switch_box
#     end

#     # Add dryrun switch
#     dry_run_button = let
#         switch = Switch()
#         set_is_active!(switch, false)
#         switch_box = vbox(switch, Label("Dry run enabled (debug)"))
#         set_horizontal_alignment!(switch, ALIGNMENT_CENTER)
#         set_margin!(switch, 10)
#         connect_signal_switched!(on_dryrun_switched, switch)
#         switch_box
#     end

#     # Place them!
#     box = hbox(dry_run_button, dark_mode_button, play_button)
#     for widget in [dry_run_button, dark_mode_button, play_button]
#         set_horizontal_alignment!(widget, ALIGNMENT_CENTER)
#         set_margin!(widget, 10)
#         # push_back!(box, widget)
#     end
#     set_margin!(box, 75)

#     # # Position the widgets
#     # set_start_child!(box, play_button)
#     # set_end_child!(box, dark_mode_button)
#     # set_margin!(box, 75)

#     set_child!(window, box)

#     return nothing
# end

# TODO-future: refactor for cleaner UI
# function create_app(app::Application)
#     window = Window(app)
#     construct_gui!(app, window)
#     set_current_theme!(app, DEFAULT_DARK_LIGHT_THEME)
#     present!(window)
#     return nothing
# end

COUNTER = Ref(0)

function launch_gui()
    if Threads.nthreads() == 1 && Threads.nthreads(:interactive) < 1
        @warn("This example is intended to be run with multiple threads enabled, e.g. `julia --threads=2`")
    end

    btn = GtkButton("Start")
    sp = GtkSpinner()
    ent = GtkEntry(; hexpand=true)
    label = GtkLabel("")

    grid = GtkGrid()
    lab = GtkLabel("")
    grid[1:2, 1] = lab
    @idle_add lab.label = "The GTK loop is running in thread $(Threads.threadid()) ($(Threads.threadpool()) threadpool)"
    grid[1, 2] = btn
    grid[2, 2] = sp
    grid[1:2, 3] = ent
    grid[1:2, 4] = label

    signal_connect(btn, "clicked") do widget
        start(sp)
        stop_time = time() + 3

        # g_timeout_add can be used to periodically call a function from the main loop
        Gtk4.GLib.g_timeout_add(50) do  # create a function that will be called every 50 milliseconds
            label.label = "counter: $(COUNTER[])"
            return time() < stop_time   # return true to keep calling the function, false to stop
        end

        Threads.@spawn begin
            # Do work

            global COUNTER[] = 0
            while time() < stop_time
                global COUNTER[] += 1
            end

            tid = Threads.threadid()
            tp = Threads.threadpool()

            # Interacting with GTK from a thread other than the main thread is
            # generally not allowed, so we register an idle callback instead.
            Gtk4.GLib.g_idle_add() do
                stop(sp)
                ent.text = "I counted to $(COUNTER[]) in thread $tid in the $tp threadpool!"
                return false
            end
        end
    end

    win = GtkWindow(grid, "Threads with updating counter", 420, 200)
    return nothing
end

end # module LearnLooperGUI
