// this is a compilation of all the stuff from all the previous files, made so that you can just press go and run it.

// nb run this first if playing back in mono
{In.ar(1)}.play

(

// basic definitions

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
};

SynthDef(\lowmix,
	{
		arg freq, dur, amp, ramp, out;

		var balance, sound, env, rampdur;

		amp = amp / 2; // to make things work in mono

		balance = min(freq/64, 1);
		sound = (balance.sqrt*SinOsc.ar(freq, 0, amp))+((((1-balance)*3/2)**2)*LFSaw.ar(freq, 0, amp));
		rampdur = dur*ramp/2;
		env = EnvGen.kr(Env([0, 1, 1, 0], [rampdur, (dur - (2 * rampdur)), rampdur]), doneAction:2);
		sound = sound * env;

		Out.ar(out, sound)
}).load(s);

// two hexachords
~x = [1, 3/2, 5/2, 7/2, 11/2,	33/32];
~y = [1, 3/2, 5/2, 7/2, 11/2,	11/2*3/2];

~x = ~x * (24.midicps);
~y = (1/~y.reverse) * (69.midicps);

// the row
~z = ~x ++ ~y;

// midi quantized version
~qz = (24+[0, 7, 16, 22, 30,	1, 8, 15, 23, 29,	38, 45]).midicps;
// to compare...
// )

// (~zquant/~z).ratiomidi

// (
// retrogrades are a bit different registrally
~rz = ~z.reverse;
~rz[5] = ~rz[5] * 8;
~rz[6] = ~rz[6] * 8;

~rqz = ~qz.reverse;
~rqz[5] = ~rqz[5] * 8;
~rqz[6] = ~rqz[6] * 8;


// tools for sections 2 and 3

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
};


Routine({
// full first section: pentachords and last dyad, 5 seconds long + 1 second rest

	var thispenta;
	var thishexa, t2z3;// for section 3


	s.prepareForRecord;
	s.sync;
	s.record;
	s.sync;

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

// also add the two row forms that the last two notes kinda sandwich. (after D-A, we have F#-C-G#-D#-A#, then F-Db-G-E-A. And vice versa. This'd add another 12 seconds.)

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



// second full section: 11 pairs of dyads, each 1 second per dyad
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
			0.25*first,
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
			1, 1/8);
		2.wait;
	};

// 3rd part: use the two-hexachord format, one row form after another, two different intonation schemes simultaneously.

	~z3 = ~z;
~z3[5] = ~z3[5] * 8;
~z3 = ~z3 / 2;


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
		(thishexa.cpsmidi-1).normalizeSum*6,
	1);
	7.wait;

	thishexa = ~z3[(6..9)]; // 10 and 11 separately
	["second hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*5,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-9).normalizeSum*5,
		1);
	6.wait;

	thishexa = ~z3[(10..11)]; // D-A
	"DA".postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*6,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-9).normalizeSum*2,
		1);
	thishexa = t2z3[(0..1)]; // more D-A
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*6,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-9).normalizeSum*6,
		1);
	7.wait;

	thishexa = t2z3[(2..5)]; // rest of first hexachord, T2P
	["first hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*5,
		0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-9).normalizeSum*5,
		1);
	6.wait;

	thishexa = t2z3[(6..11)]; // all of second hexachord
	["second hexachord", thishexa].postln;
	~playdurationscheme.value(
		thishexa,
		(1/thishexa).normalizeSum*6,
	0);
	thishexa = thishexa.cpsmidi.round.midicps;
	~playdurationscheme.value(
		thishexa,
		(thishexa.cpsmidi-1).normalizeSum*6,
	1);
	7.wait;

	s.sync;
	s.stopRecording;

}).play
)

// this has been mixed to sound good on a subwoofer. Who knows how it'll sound on real speakers.
