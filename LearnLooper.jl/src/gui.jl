#TODO-future: move to own package that depends on LearnLooper.jl
module LearnLooperGUI

export launch_gui

using LearnLooper
using Gtk4

function launch_gui()
    @info "Woo"
end

end # module LearnLooperGUI
