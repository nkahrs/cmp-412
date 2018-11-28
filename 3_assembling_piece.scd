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
	arg freqs1, durs1, outbus;

	var len = min(freqs1.size, durs1.size);

	Routine({
		len.do{
			arg i;
			Synth(\saw, [\freq, freqs1[i], \dur, 1.5*durs1[i], \amp, 0.5, \ramp, 0.5, \out, outbus]);
			durs1[i].wait;
		};
		"end".postln;
	}).play;

	"start".postln;
}
)

// full first section: pentachords and last dyad, 5 seconds long + 1 second rest
(
Routine({
	"first pentachord".postln;
	~playdurationscheme.value(
		~z[(0..4)],
		(1/~z[(0..4)]).normalizeSum*5,
		0);
	~playdurationscheme.value(
		~rqz[(0..4)],
		(~rqz[(0..4)].cpsmidi-33).normalizeSum*5,
		1);
	6.wait;
	"second pentachord".postln;
	~playdurationscheme.value(
		~z[(5..9)],
		(1/~z[(5..9)]).normalizeSum*5,
		0);
	~playdurationscheme.value(

		~rqz[(5..9)],
		(~rqz[(5..9)].cpsmidi-36).normalizeSum*5,
		1);
	6.wait;
	"last two notes".postln;
	~playdurationscheme.value(
		~z[(10..11)],
		(1/~z[(10..11)]).normalizeSum*5,
		0);
	~playdurationscheme.value(
		~rqz[(10..11)],
		(~rqz[(10..11)].cpsmidi-19).normalizeSum*5,
		1);
	6.wait;
	"end".postln;
}).play;
)

// second full section: 11 pairs of dyads, each 1 second per dyad
(
Routine({
	11.do{
		arg i;
		i.postln;
		~playdurationscheme.value(
			~z[(i..i+1)],
			(1/~z[(i..i+1)]).normalizeSum,
			0);
		// need to octave-shift both series to near the critical band, and standardize pitch-class baseline for second scheme
		1.wait;
		~playdurationscheme.value(
			~rqz[(i..i+1)],
			[1,1]/2,
			1);
		1.wait;
}}).play;
)