# RC Demo 1: Learn to sing the beginning of Tom Lehrer's The Elements

# To set up, download the audio from the below, convert to WAV, 
# and save as tom_lehrer_elements.wav in the directory next to this demo script
# https://www.youtube.com/watch?v=U2cfju6GTNs 

using LearnLooper

# Run it to try it:
lehrer_song = "tom_lehrer_elements.wav"
two_word_spans = [(8.75, 9.775),
                  (9.775, 10.72),
                  (10.72, 11.71),
                  (11.72, 12.78)]
learn_loop(lehrer_song, two_word_spans;
           num_repetitions=4, iteration_mode=:sequential)

# ...can also learn in cumulative mode:
learn_loop(lehrer_song, two_word_spans;
           num_repetitions=1, iteration_mode=:cumulative)

# Other LL uses: memorize digits of pi...
learn_loop(pi + 0, [1:4, 5:8]; num_repetitions=2, iteration_mode=:cumulative,
           interrepeat_pause=0)

# Sidebar: why 0 + pi and not just pi? Try it!
learn_loop(pi, [1:1]; num_repetitions=2, iteration_mode=:cumulative,
           interrepeat_pause=0)

# LL can also handle other text-base learning:
learn_loop("A sentence, by cumulative phrase", [1:2, 3:5]; num_repetitions=2,
           iteration_mode=:cumulative)
