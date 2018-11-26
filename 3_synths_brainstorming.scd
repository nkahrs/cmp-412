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
	[0, 7, 4, 10, 6, 8, 1, 3, 11, 5, 2, 9].do{
		arg i;
		var freq, dur;
		freq = i.midicps / 3;
		dur = 10/freq;
		[i, freq, 10/freq].postln;
		Synth(\lowmix, [\freq, i.midicps/3, \dur, dur, \amp, 0.1, \ramp, 0.1]);
		dur.wait
	}
}).play;
)