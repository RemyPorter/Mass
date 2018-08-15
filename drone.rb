with_fx :panslicer, phase: 3, mix: 0.5 do
  with_fx :gverb, room: 3 do
    with_fx :ixi_techno, phase: 5, cutoff_min: 50, cutoff_max: 67, res: 0.9 do
      with_fx :bitcrusher, bits: 8, sample_rate: 4000, sample_rate_slide: 5 do |bc|
        live_loop :hum do
          n = play hz_to_midi(60), attack: 0, release: 0, sustain: 60, note_slide: 2.3
          10.times do
            control n, note: hz_to_midi(rrand(55,65))
            sleep 6
          end
        end
        live_loop :crank do
          use_synth :fm
          use_synth_defaults divisor: 6, attack: 2, sustain: 4, release: 2, depth: 0.6, cutoff: 60
          play hz_to_midi(603) if one_in(6)
          sleep rrand(5,8)
        end
      end
    end
  end
end