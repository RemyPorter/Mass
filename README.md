# Mass: An Invisible Conversation - Technical Notes

I recently had the great privilege to contribute to [Uncumber Theatric's](http://uncumbertheatrics.com) recent underground show, *Mass: An Invisible Conversation*. Underground in both the metaphorical sense- a self-produced interactive show for no more than 5 patrons at a time- and the literal- it largely happened in a basement.

Writer/director/producer Ayne Terceira contacted me, initially about doing sound design, and the scope kinda spread out from there. One of the centerpieces of the experience was going to be a "numbers station"- a mysterious radio station which recited an endless list of numbers which constituted a secret code only certain people could understand. The patrons would be free to explore the basement where the "radio" lived, and interact with actors who would be in the space, or accessible via radio or Skype.

So that laid out our first goal: we needed audio of numbers being recited, mangled to sound like it might be coming from a low-quality radio signal. To complicate matters, each sub-sequence of numbers needed to be rudely interrupted by the synth riff from Toto's "Africa", *and* there were literally thousands of numbers in the sequence.

<video src="mass.mp4">

## Building the Numbers

Due to budget (not much) and time (also not much), we made the choice to automate this. We went (arguably) low-tech, and use the MacOS `say` command line command. First thing I did was a quick `xargs` command to generate sample text in *every* voice available. Nobody wanted it to sound like Siri.

Ayne chose Sin-Ji as the best voice. So the next step was to take the spreadsheet and feed it in. Enter Python.

I whipped up a quick Python script which simply slammed the numbers in the CSV file into the `say` command via `subprocess.call`- essentially just calling out to the shell. It's an ugly hack, certainly, but it's also a really quick way to generate huge amounts of audio.

There was one problem: since Sin-Ji was a Hong Kong localization, the voice would recite numbers in Chinese. This wasn't a good choice for our English-speaking audience, so I slapped in a dependency on `num2words`.

The resulting script, [convert.py](convert.py) doesn't offer much- I didn't bother to parameterize it or anything like that. It has a hardcoded reference to a CSV file, and pumps the data out via `say`. Note the use of `[[slnc 500]]`, which allows me to include silence within the audio. That's a little trick I learned about the `say` command which isn't particularly documented.

The result ends up sounding [like this](sample.mp3). It's boring, dry, and certainly not theatrical. That's where Sonic-Pi comes into play.

## Designing the Radio Station

[Sonic-Pi](http://sonic-pi.net/) is *incredibly* powerful, and it's become one of my go-to tools for doing anything relating to building sounds. The core thing I needed to do was sequence the pre-generated voices. That part was itself quite easy- Sonic-Pi provides handy `range` commands, `convert.py` output the audio following a numbered file convention. The core of playing back the audio in order was simple:

```ruby
path = "/path/to/sounds"
sequence = (range 0, 278)
sequence.each do |x|
  sample path, x.to_s.rjust(3, '0')
end
```

This block will iterate across every file in my path directory, playing them in sequence. Now, fun fact: I didn't actually need to reference them by filename, so the `rjust` wasn't strictly necessary, but I wasn't about to trust the default sort order. Now, since this needs to be interrupted by a clip from Toto's Africa between samples, I added a `sample path, "toto.wav"` after each main sample play.

But this is boring. The audio is dry, uninteresting, and it sounds like a robot. I needed to grit it up. Some of that was obvious. `krush` is a low-pass filter, and combined with `bitcrusher` it gives a nice low-fi sound. A little reverb helps, and the most important filter, the key that makes the whole thing *hum* is a ring modulation.

```ruby
with_fx :krush, mix: 0.1 do
  with_fx :gverb, spread: 0.0, mix: 0.2, room: 2, damp: 0.6, release: 1 do
    with_fx :ring_mod, mix: 0, mix_slide: 2, freq_slide: 1.75, freq: 60 do |rm|
      with_fx :bitcrusher, sample_rate: 16000, bits: 16 do
        sequence.each do |x|
          sample path, x.to_s.rjust(3, '0')
          sample path, "toto.wav"
        end
      end
    end
  end
end
```

But it's *still* boring at that point, because each of the individual sequences is going to *sound exactly the same*. So what we need is a little randomness. Adding a `beat_stretch` to the number sequence allows me to have each sequence of numbers take a slightly different amount of time, and I can change the pitch and speed of `toto.wav` because nothing sounds creepier than the strains of "Africa" running at about 80% and shifted down a semitone.

Adding that randomness, though, that's *also* not quite enough, because even within a number sequence, things should be changing. So I added code that changes the speed of the playback *while the playback is running*, while altering the pitch of the ring modulator.

```ruby
with_fx :krush, mix: 0.1 do
  with_fx :gverb, spread: 0.0, mix: 0.2, room: 2, damp: 0.6, release: 1 do
    with_fx :ring_mod, mix: 0, mix_slide: 2, freq_slide: 1.75, freq: 60 do |rm|
      with_fx :bitcrusher, sample_rate: 16000, bits: 16 do
        sequence.each do |x|
          pbk = sample path, x.to_s.rjust(3, '0'), amp: 3, beat_stretch: rrand(10,12), beat_stretch_slide: 1, amp_slide: rrand(0.2, 3)
          5.times do
            control pbk, beat_stretch: rrand(8, 14), amp: rrand(0.8, 2.0)
            control rm, mix: rrand(0,0.4), freq: rrand(40,80)
            sleep 1.9
          end
          toto_rate = rrand(0.8, 1.2)
          pbk = sample path, "toto.wav", amp: 0.8, rate: toto_rate, amp_slide: 2.0, pitch_slide: 1
          6.times do
            control pbk, pitch: rrand(-1, 1), amp: rrand(0.8, 2.0)
            control rm, mix: rrand(0,0.4), freq: rrand(40,80)
            sleep 1
          end
          control pbk, amp: 0.0
        end
      end
    end
  end
end
```

With some live loops to generate noise, pops and hiss, [the full script](station.rb) sounds something like [this](station.mp3). All in all, this generates an 108 minutes of audio as it recites the sequence.

## Actual Playback
Now, on set, the goal was to have this running in an endless loop. When the audience triggered a certain "switch", the audio needed to change to something else. Some of that audio was generated using [more Sonic-Pi](bwoop.rb), but that was mostly created using more traditional audio editing methods.

The key: I needed to play audio, and when the audience did something, I needed to switch audio tracks. I *could* have controlled the audio entirely in Sonic-Pi, and use something like OSC to send a message to Sonic-Pi to change what was playing. For simplicity, however, I opted instead to render *all* the audio to Ogg files, and then use PyGame to play them back. Why?

Well, the hardware I chose to use was a Raspberry Pi, because a) I had one handy, and b) I could use the GPIO pins to detect the switch. I wrote a *really stupid* script, [playback.py](playback.py) which is basically a series of infinite loops. Again, the GPIO API actually has methods I could have used to "wait for change", but instead of properly learning the API, I just got something done which worked well enough.

Since this was a headless environment, I registered `playback.py` as a service which launched at bootup. So that the cast (who were responsible for resetting the tech without me on site) could have at least *some* feedback, I had it play a clean version of "Africa" at boot. To ensure that the audience didn't accidentally reset the prop after the "switch", I also added a long sleep at the end.

The code is simple and linear and an infinite loop, because I didn't want to ever have to *think* about what it's doing. There are many smarter ways I could have written it, but this was the absolute *simplest* I could come up with on short notice.

### The Switch
You can see the actual prop in action [here](https://www.facebook.com/UncumberTheatrics/videos/299859820777068/). Essentially, I hid a Raspberry Pi inside of a junction box, with a plug epoxied into it.

You may notice that in `playback.py`, I write to *one* GPIO pin, and read from another. These pins run to the male end of a power plug. During the show, a female power plug is connected- but it's not a real power plug. I shorted two of the pins. As long as they're connected, the circuit is closed, but once the plug gets pulled, the circuit opens, and I detect that via the GPIO pins.

"If it's stupid and it works, at least it worked."

## Other Audio
To help build the world, there was some other audio in the space, provided by [drone.rb](drone.rb). This is another Sonic-Pi script, which outputs a rather unpleasant drone. One patron mentioned that being anywhere near it was physically unpleasant, which honestly, was the design goal. It's a nice Lynchian hum, like a menacing power substation. You could hear it in the entire space, and it suffused everything that was happening. I was pretty proud of it.

## After Action
The show has wrapped, which is partially why I'm doing this writeup. But it may also get a revival- which is why I'm not including too many details about the props used, or anything beyond the broadest summary of the show.

In terms of the code and the props running the code: it worked great. I'm always a little terrified to release a piece of software, especially one which drives a show like this. The only failure event was when a patron misunderstood an instruction from the cast and ended up turning off the power to the prop. The cast, primed to improvise for these kinds of situations, carried the show to its conclusion anyway. All in all, there were 15 shows and the numbers station worked flawlessly every other time.

Which really just means I did my job at the most basic level of competence. Ayne, and the cast she assembled- Bevin Baker, Kate Hagerty, Julianne Theresa, Brennan Bobish, Amy Portenlanger and Anna Gilchrist are what truly made the show work. Sarah Wojdylak handled the majority of the set design, which did so much to bring the world to life.

If I were to build this prop again, I'd add more cabling to it, just for decoration, and most important- I'd hide a weight in there- just like 5lbs, just to give it some heft.