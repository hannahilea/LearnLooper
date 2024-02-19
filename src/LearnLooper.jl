module LearnLooper

export learn_demo

demo_song = collect('a':'z')  #TODO-future: make this a loaded audio file

#TODO-future: decide how to handle overlapping v non-overlapping
#TODO-future: make this a blob that has more info, e.g. label + timestamp + metadata
demo_segments = [1:5, 6:20, 21:26]  # assume non-overlapping 

"""
    play(input, segment; volume_scale=1) -> nothing

Computer plays `segment` of `input`.
"""
function play(input, segment; volume_scale=1)
    seg = input[segment]
    println(volume_scale == 0 ? "🎤Pausing" : "👂Playing", ": ", seg)
    return nothing
end

"""
    pause(input, segment) -> nothing

Computer pauses for duration `segment` of `input`.
"""
pause(input, segment) = play(input, segment; volume_scale=0)

function learn_demo()
    @info "Welcome to the LeArNlOoPer demo! Prepare to learn a song!"
    for segment in demo_segments
        play(demo_song, segment)
        pause(demo_song, segment)
    end
    return nothing
end

end # module LearnLooper
