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
	arg freqs1, durs1, outbus, amp;

	var len = min(freqs1.size, durs1.size);

	if((amp == nil), {amp = 0.5});

	Routine({
		len.do{
			arg i;
			Synth(\lowmix, [\freq, freqs1[i], \dur, 1.5*durs1[i], \amp, amp, \ramp, 0.5, \out, outbus]);
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
		0);
	6.wait;
	"second pentachord".postln;
	~playdurationscheme.value(
		~z[(5..9)],
		(1/~z[(5..9)]).normalizeSum*5,
		0);
	~playdurationscheme.value(

		~rqz[(5..9)],
		(~rqz[(5..9)].cpsmidi-36).normalizeSum*5,
		0);
	6.wait;
	"last two notes".postln;
	~playdurationscheme.value(
		~z[(10..11)],
		(1/~z[(10..11)]).normalizeSum*5,
		0);
	~playdurationscheme.value(
		~rqz[(10..11)],
		(~rqz[(10..11)].cpsmidi-19).normalizeSum*5,
		0);
	6.wait;
	"end".postln;
}).play;
)

// normalizing pitches in second section

( // pitchtolow: octave-shift a set so that the second element xs[1] is in [0,12) midi range
~pitchtolow = {
	arg xs;
	xs = xs.cpsmidi;
	xs = xs-(12*((xs[1]/12).floor));
	xs.midicps
}
)

(var asdf = (5..6); ~pitchtolow.value(~z[asdf])/~z[asdf])


(
11.do{
	arg i;
	i.postln;

	~pitchtolow.value(~z[(i..i+1)]).postln; // transpose so that the second one is in the [0,12) midi range
	~pitchtolow.value(~rqz[(i..i+1)]).postln;
}
)

40-(12*(40/12).floor)



// second full section: 11 pairs of dyads, each 1 second per dyad
(
Routine({
	11.do{
		arg i;
		var first, second;

		i.postln;

		first = ~pitchtolow.value(~z[(i..i+1)]); // transpose so that the second one is in the [0,12) midi range
		second = ~pitchtolow.value(~rqz[(i..i+1)]);

		~playdurationscheme.value(
			2*first,
			(1/first).normalizeSum,
			0, 1/4);
		// two of the same an octave apart. I should use different registral forms of the row (one by pentachords as in previous section, then one by hexachords as for next section).
		~playdurationscheme.value(
			first,
			(1/first).normalizeSum,
			0, 1/8);
		// need to octave-shift both series to near the critical band, and standardize pitch-class baseline for second scheme
		1.wait;
		~playdurationscheme.value(
			2*second,
			[1,1]/2,
			0, 1/4);
		~playdurationscheme.value(
			4*second,
			[1,1]/2,
			0, 1/16);
		1.wait;
}}).play;
)