# LearnLooper

Learn via call and response by looping over the material to be learned (musical audio or speech or video or text...) and repeating it back during the pauses. 

**VERY MUCH WIP! Use at your own risk :)**

## Repository structure

### [Demos](./demos)

For the most up-to-date behavior of LeanLooper, see the most recent demo in the demos folder. Each demo should contain some form of manifest that is pinned to the version of LearnLooper.jl used at demo time. These demos are likely not forward-compatible, if e.g. the most recent version of LearnLooper.jl is checked out instead.

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
- Move printouts to debug mode
- Safety ~first~ last!

### Dev log 

#### 28 Feb
- Update docstrings

#### 27 Feb
- Restructure repo and move Julia library into a subdir
- Add GHA: docs, codecov, CI, linting, badges
- Fix tests to remove hardcoded example song

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
