// rows themselves implemented in previous.
// Here, at least for first section, I'm implementing the duration scheme
// row of freqs, then row of corresponding normalized durations
~z[(0..4)]
(1/~z[(0..4)]).normalizeSum*5
~rqz[(0..4)]
(~rqz[(0..4)].cpsmidi-33).normalizeSum*5

~z[(5..9)]
(1/~z[(5..9)]).normalizeSum*5
~rqz[(5..9)]
(~rqz[(5..9)].cpsmidi-36).normalizeSum*5

~z[(10..11)]
(1/~z[(10..11)]).normalizeSum*5
~rqz[(10..11)]
(~rqz[(10..11)].cpsmidi-19).normalizeSum*5


(
~playdurationscheme = {
	arg freqs1, durs1, freqs2, durs2;

	var len = min(freqs1.size, durs1.size, freqs2.size, durs2.size);

	Routine({
		len.do{
			arg i;
			Synth(\lowmix, [\freq, freqs1[i], \dur, 2*durs1[i], \amp, 1, \ramp, 1, \out, 0]);
			durs1[i].wait;
		};
		"end1".postln;
	}).play;

	Routine({
		len.do{
			arg i;
			Synth(\lowmix, [\freq, freqs2[i], \dur, durs2[i], \amp, 1, \ramp, 1, \out, 1]);
			durs2[i].wait;
		};
		"end2".postln;
	}).play;

	"start".postln;
}
)

// full first section
(
Routine({
	"first pentachord".postln;
	~playdurationscheme.value(
		~z[(0..4)],
		(1/~z[(0..4)]).normalizeSum*5,
		~rqz[(0..4)],
		(~rqz[(0..4)].cpsmidi-33).normalizeSum*5
	);
	6.wait;
	"second pentachord".postln;
	~playdurationscheme.value(
		~z[(5..9)],
		(1/~z[(5..9)]).normalizeSum*5,
		~rqz[(5..9)],
		(~rqz[(5..9)].cpsmidi-36).normalizeSum*5
	);
	6.wait;
	"last two notes".postln;
	~playdurationscheme.value(
		~z[(10..11)],
		(1/~z[(10..11)]).normalizeSum*5,
		~rqz[(10..11)],
		(~rqz[(10..11)].cpsmidi-19).normalizeSum*5
	);
	6.wait;
	"end".postln;
}).play;
)

[1,2,3].size
min(1,2,3,4)
min(6,3,6)