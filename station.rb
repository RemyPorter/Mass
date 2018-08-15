path = "/path/to/sounds"
use_bpm 40
sequence = (range 0, 278)
live_loop :hiss do
  use_synth :noise
  play :c0, amp: rrand(0,0.0625), sustain: 2, attack: 0, decay: 0, release: 0
  sleep 0.25
end
live_loop :pops do
  use_bpm 90
  use_synth :bnoise
  with_fx :bitcrusher, sample_rate: 200, bits: 9 do
    play 10, amp: 10, attack: 0.01, decay: 0.0, release: 0.01, sustain: 0.0 if one_in(4)
  end
  sleep 1.0
end
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
