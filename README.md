# LearnLooper.jl

Call and response learning tool for learning by looping over a prerecorded song (or speech or video or...).

**VERY MUCH WIP! Use at your own risk :)**

## Demo

To use, [install Julia](https://julialang.org/downloads/#install_julia) and then launch the REPL with `julia --project=path/to/LearnLooper.jl `. 

In the REPL, run
```julia
using Pkg
Pkg.instantiate()

using LearnLooper

learnloop("Learn this big long sentence, one phrase at a time", [1:1, 2:5, 6:10]; num_repetitions=2, iteration_mode=:cumulative)
```
In the REPL, do 
```
?learnloop
```
for full list of parameters to play with. These include ways to indicate number of repetitions and playback modes (e.g., sequential segments vs cumulative segments), as long as the ability to pass in your own segments for the demo input.

See the docstring for `learnloop` for more options:
```
?learnloop
```

## Dev log 

### Next steps
As a treat:
- Set up params to control global playback speed, etc?
- Set up notebook to play with controls while learning/run demo?
- Find/use package to play audio files

Housekeeping:
- Make testing nicer (don't actually play audio, output what *was* played)
- Add codecov (+ badge)
- Add docstrings to main entrypoints
- Move printouts to debug mode
- Safety ~first~ last!

### 21 Feb
- Fully support `say` behavior (mac only)
- Support strings, vector of strings, numbers
- Add test for above plus reading in text file

### 20 Feb
- Make devlog, update README
- Add tests
- Update "cumulative" logic to support non-contiguous segments
- Start adding `say` behavior (mac only)

### 19 Feb
- initial implementation!
- create `learn_demo` for generic input vector with indexable segments
- "play" by printing to screen



