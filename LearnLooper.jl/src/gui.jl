#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui

using LearnLooper
using Mousetrap

const DEFAULT_DARK_LIGHT_THEME = THEME_DEFAULT_DARK

#####
##### Signals
#####

# TODO: info -> debug macro

function on_mode_switched(switch::Switch, app::Application)
    state = get_is_active(switch)
    @debug "dark_mode_switch is now: $state"
    set_current_theme!(app, state ? THEME_DEFAULT_LIGHT : THEME_DEFAULT_DARK)
    return nothing
end

#####
##### GUI
#####

function construct_gui!(app::Application, window)
    header_bar = get_header_bar(window)

    # Update window title
    set_title!(window, "Learn Looper")

    # Add dark/light mode toggle
    let
        switch = Switch()
        set_is_active!(switch, DEFAULT_DARK_LIGHT_THEME == THEME_DEFAULT_LIGHT)
        switch_dark_mode_box = vbox(switch, Label("Toggle dark mode"))
        set_horizontal_alignment!(switch, ALIGNMENT_CENTER)
        set_margin!(switch, 10)
        connect_signal_switched!(on_mode_switched, switch, app)

        # Position the switch
        box = CenterBox(ORIENTATION_HORIZONTAL)
        set_start_child!(box, switch_dark_mode_box)
        # set_end_child!(box, inactive_box)
        set_margin!(box, 75)

        set_child!(window, box)
    end
    return nothing
end

# TODO-future: refactor for cleaner UI
function create_app(app::Application)
    window = Window(app)
    construct_gui!(app, window)
    set_current_theme!(app, DEFAULT_DARK_LIGHT_THEME)
    present!(window)
    return nothing
end

launch_gui() = Mousetrap.main(create_app)

end # module LearnLooperGUI
