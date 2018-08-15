# A downward falling "bwooooooop" sound
use_bpm 60
with_fx :ring_mod, freq: 60 do |rm|
  s = play hz_to_midi(120), note_slide: 10, attack_level: 4, attack: 1, release: 10, amp: 2
  control s, note: 10
  control rm, freq: 6, freq_slide: 10
end