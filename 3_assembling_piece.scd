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
	var thispenta;

	thispenta = ~z[(0..4)];
	"first pentachord".postln;
	~playdurationscheme.value(
		thispenta,
		(1/thispenta).normalizeSum*5,
		0);
	thispenta = ~rqz[(0..4)];
	~playdurationscheme.value(
		thispenta,
		(thispenta.cpsmidi-33).normalizeSum*5,
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
//}).play;


// also add the two row forms that the last two notes kinda sandwich. (after D-A, we have F#-C-G#-D#-A#, then F-Db-G-E-A. And vice versa. This'd add another 12 seconds.)

//Routine({
	"first pentachord".postln;
	thispenta = ~z[(2..6)] * (2.midiratio);
	thispenta.postln;
	~playdurationscheme.value(
		thispenta,
		(1/thispenta).normalizeSum*5,
		0);

	thispenta = ~rqz[(2..6)]*(2.midiratio);
	thispenta.postln;
	~playdurationscheme.value(
		thispenta,
		(thispenta.cpsmidi-46).normalizeSum*5,
		1);

	6.wait;

	"second pentachord".postln;
	thispenta = ~z[(7..11)] * (2.midiratio);
	thispenta.postln;
	~playdurationscheme.value(
		thispenta,
		(1/thispenta).normalizeSum*5,
		0);

	thispenta = ~rqz[(7..11)] * (2.midiratio);
	thispenta.postln;
	~playdurationscheme.value(
		thispenta,
		(thispenta.cpsmidi-24).normalizeSum*5,
		1);

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
};

~miditorhythm = {
	arg midi;
	var toreturn;
	toreturn = (midi + 12 - midi[0]);
	toreturn = toreturn.normalizeSum*2;
}
)

(var asdf = (5..6); ~pitchtolow.value(~z[asdf])/~z[asdf])


// need a curve that sends, say, (1.2, .8) to (1,1), but (1.6, 0.4) to (1.9, 0.1)

// testing values
(
11.do{
	arg i;
	var blah;
	i.postln;

	// pitches for JI
	blah = ~pitchtolow.value(~z[(i..i+1)]);// transpose so that the second one is in the [0,12) midi range
	blah.postln;
	// rhythms for JI
	blah = ((1/blah).normalizeSum*2);
	blah.postln;

	// pitches for ET
	blah = ~pitchtolow.value(~rqz[(i..i+1)]);
	blah.postln;
	// rhythms for ET
	blah = blah.cpsmidi;
	// blah.postln;
	blah = blah + (12 - blah[0]);
	(blah.normalizeSum*2).postln;
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
			0.5*first,
			(1/first).normalizeSum*2,
			0, 1/4);
		// two of the same an octave apart. I should use different registral forms of the row (one by pentachords as in previous section, then one by hexachords as for next section).
		~playdurationscheme.value(
			first,
			(1/first).normalizeSum*2,
			0, 1/8);
		// need to octave-shift both series to near the critical band, and standardize pitch-class baseline for second scheme
		// 1.wait;
		~playdurationscheme.value(
			2*second,
			~miditorhythm.value(second),
			1, 1/4);
		~playdurationscheme.value(
			4*second,
			~miditorhythm.value(second),
			1, 1/16);
		2.wait;
}}).play;
)


// 3rd part: use the two-hexachord format, one row form after another, two different intonation schemes simultaneously.

~z3 = ~z
~z3[5] = ~z[5] * 8;
~z3[(0..5)] // first hexachord
~z3[(6..11)] // second hexachord
// to check...
~z3.cpsmidi.round

/* from here, do as follows when less tired:
first hexachord like the first pentachord in the first section, but with 9 seconds
both "equivalent" rows simultaneously.

then second hexachord...
when at last two notes, trigger same for same row form, but freqs *(9/8)
*/

~z.cpsmidi.round

(
Routine({
	var thishexa, t2z3;
	t2z3 = ~z3*9/8;

	thishexa = ~z3[(0..5)];
	["first hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*6,
	0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-13).normalizeSum*6,
	1);
	7.wait;

	thishexa = ~z3[(6..9)]; // 10 and 11 separately
	["second hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*4,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-21).normalizeSum*4,
		1);
	5.wait;

	thishexa = ~z3[(10..11)]; // D-A
	"DA".postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*2,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-21).normalizeSum*2,
		1);
	thishexa = t2z3[(0..1)]; // more D-A
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*2,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-21).normalizeSum*2,
		1);
	3.wait;

	thishexa = t2z3[(2..5)]; // rest of first hexachord, T2P
	["first hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*4,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-21).normalizeSum*4,
		1);
	5.wait;

	thishexa = t2z3[(6..11)]; // all of second hexachord
	["second hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*6,
	0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-13).normalizeSum*6,
	1);
	7.wait;

}).play
)

[ 53.333333333333, 80, 125.71428571429, 176, 293.33333333333, 440 ].cpsmidi.round
69-48


s.prepareForRecord
s.record
s.stopRecording
