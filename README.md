# LearnLooper

Learn via call and response by looping over the material to be learned (musical audio or speech or video or text...) and repeating it back during the pauses. 

**VERY MUCH WIP! Use at your own risk :)**

## Repository structure

### [Demos](./demos)

For the most up-to-date behavior of LeanLooper, see the most recent demo in the demos folder.

### [LearnLooper.jl](./LearnLooper.jl)

Julia library that implements that looping logic.

## Developer notes

### Incomplete list of next steps
...to be moved into issues when development is far enough. 

As a treat:
- Set up params to control global playback speed, etc?
- Set up notebook to play with controls while learning/run demo?
- Find/use package to better vocode/adjust speed
- Support backing track(s)/drone
- Support loading annotation files (as created in an external app)

Housekeeping:
- Make testing nicer (don't actually play audio, output what *was* played)
- Add codecov (+ badge)
- Add docstrings to main entrypoints
- Move printouts to debug mode
- Safety ~first~ last!

### Dev log 

#### 27 Feb
- Restructure repo and move Julia library into a subdir

#### 22 Feb
- Set up first demo
- Fix bug in 'cumulative' mode

#### 21 Feb
- Fully support `say` behavior (mac only)
- Support strings, vector of strings, numbers
- Add test for above plus reading in text file
- Added .wav support!! 
- Added (lousy) speed support!

#### 20 Feb
- Make devlog, update README
- Add tests
- Update "cumulative" logic to support non-contiguous segments
- Start adding `say` behavior (mac only)

#### 19 Feb
- initial implementation!
- create `learn_demo` for generic input vector with indexable segments
- "play" by printing to screen
