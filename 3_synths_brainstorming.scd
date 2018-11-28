// just testing basic oscillators with a subwoofer

{SinOsc.ar(100,0,0.01)}.play

(
{
	var freq, balance, sound;

	balance = MouseX.kr(0, 1);
	freq = balance*50;
	balance = balance.sqrt;

	sound = (balance*SinOsc.ar(freq, 0, 0.1))+((1-balance)*LFSaw.ar(freq, 0, 0.1))
}.play
)

max(1, 2)

(
SynthDef(\lowmix,
	{
		arg freq, dur, amp, ramp;

		var balance, sound, env, rampdur;

		balance = min(freq/50, 1);
		sound = (balance*SinOsc.ar(freq, 0, amp))+((1-balance)*LFSaw.ar(freq, 0, amp));
		rampdur = dur*ramp/2;
		env = EnvGen.kr(Env([0, 1, 1, 0], [rampdur, (dur - (2 * rampdur)), rampdur]), doneAction:2);
		sound = sound * env;

		Out.ar(0, sound)
}).load(s)
)

Synth(\lowmix, [\freq, 15, \dur, 4, \amp, 0.1, \ramp, 0.01])

// now, some midi tests...
(
Routine({
	[0, 7, 4, 10, 6, 1, 8, 3, 11, 5, 2, 9].do{
		arg i;
		var freq, dur;
		freq = i.midicps *8;
		dur = 200/freq;
		dur = 1;
		[i, freq, 5/freq].postln;
		Synth(\lowmix, [\freq, freq, \dur, dur, \amp, 0.1, \ramp, 0.1]);
		dur.wait
	}
}).play;
)

// test with specific notes, 11/27
Synth(\lowmix, [\freq, 12.midicps, \dur, 4, \amp, 10, \ramp, 0.01])

{SinOsc.ar}.play

1/[1,2].reverse

