// brainstorming FFT log pitch inversion
// this lets us flip arbitrary spectra in a weird FFT sense
// a list of three parameters: lower bin, upper bin, lerp lambda factor
(1..8).collect({arg i; i*i});
(
var thestuff = (1..9).collect({arg i; i*i});

(1..8).collect({
	arg i;
	var foo;
	foo = (8/i);
	foo = [foo.floor, foo.ceil, (foo - (foo.floor))].postln;
	foo[2].linlin(0,1,thestuff[foo[0]],thestuff[foo[1]]).postln
})
)

// and here it is, but now it works
// note that the premise is that the Nyquist maps to 0, so the Nyquist and its sub-octaves are the axes in "pc-space"
(
{
	var sound, chain, balance, fftsize;
	sound = SoundIn.ar(0);
	sound = SinOsc.ar(MouseX.kr(40,4000));
	chain = FFT(LocalBuf(1024), sound); // hardcoded FFT size :/
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		var newmags, newphases;
		newmags = mags;
		newphases = phases;
		mags.size.do{
			arg i;
			var foo, ff, fc, fmf;
			foo = (512/(i+1));
			ff = foo.floor;
			fc = foo.ceil;
			fmf = foo-ff;
			newmags[i] = fmf.linlin(0,1,mags[ff],mags[fc]);
			phases[i] = fmf.linlin(0,1,phases[ff],phases[fc]);
		};
		[newmags, phases]
	});
	balance = MouseY.kr(0,1);
	// (sound * (1 - balance)) + (IFFT(chain) * balance)
	IFFT(chain).dup
}.play;
)

// likewise, here's an attempt at forcing everything into the same octave with filters. It likewise productively only kinda works.
/* we have a bank of filters for following ranges:
9: 21-43
8: 43-86
7: 86-172
6: 172-344
5: 344-689
4: 689-1378
3: 1378-2756
2: 2756-5512
1: 5512-11025
0: 11025-22050

each of these gets pushed into the same octave with a pitchshift somehow

number: Nyquist_2^what? for upper value*/

344.cpsmidi // F4 26c flat, as expected

/* rq = 1/q = spread / center
for each of these, if f is lower freq, then spread = f, center = (3f)/2, so rq = 3/2
*/

{BPF.ar(WhiteNoise.ar, MouseX.kr(21,11000), 3/2)}.play

(
{
	var sound, filterbank, pitchshifts, target;
	sound = LFSaw.ar(MouseX.kr(20,1000), 0.001); // or whatever
	target = 5; // how many octaves below Nyquist to target
	filterbank = Array.fill(10);
	10.do{
		arg i;
		filterbank[i] = BPF.ar(sound, 3*22050/(2**(i+2)), 3/2);
	};
	filterbank[0] = SinOsc.ar(0); // highest one is noise-ridden
	pitchshifts = Array.fill(10);
	10.do{
		arg i;
		pitchshifts[i] = PitchShift.ar(
			filterbank[i],
			0.01,
			(0.5)**(target-i)
		);
	};
	Mix.ar(pitchshifts).dup
	//sound = filterbank[5];
}.play
)


// now, the other two.

// FFT-based compression into one octave

// first, pick 0 through 9 as how much down from Nyquist to find minimum bin
2**(9-(0..9))
// anyways, for, say, 128-256, we look at bin/2 (if an integer), etc, and bin*2, etc
(
{
	var sound, chain, balance, fftsize;
	sound = SinOsc.ar(MouseX.kr(20, 1000));
	// sound = SoundIn.ar;
	//sound = Pulse.ar(MouseX.kr(40,4000));
	chain = FFT(LocalBuf(1024), sound); // hardcoded FFT size :/
	chain = chain.pvcalc(1024, {
		arg mags, phases;
		var newmags, newphases;
		newmags = Array.fill(mags.size, 0);
		newphases = phases;
		(8..16).do{ // this will change along with 5 and 3 below depending on which octave
			arg i;
			newmags[i] = mags[i];
			4.do{
				arg j;
				newmags[i] = newmags[i] + mags[i*(2**(j+1))];
			};
			4.do{ // sub-octaves still aren't quite working...
				arg j;
				var foo = (i/(2**(j+1)));
				newmags[i] = newmags[i] + (mags[foo] * (2**j));
			};
		};
		[newmags, phases]
	});
	balance = MouseY.kr(0,1);
	//(sound * (1 - balance)) + (IFFT(chain) * balance)
	IFFT(chain).dup
}.play;
)

4.do{arg j; (19/(2**(j+1))).floor.postln}

// filterbanks for flipping pitch-classes (F->F, or whole spectrum?)
// is it possible to have, like, 12 bandpass filters simultaneously alternating in each of 10 octaves? No, 120 is more than it can handle. I'll have to break it into pc-pairs
// let F-slightly-flat = 0. We have 0, 1, 2, 3, 4, 5.
/* actually the more I think about this the more pointless it is--dividing into semitones with filters is completely ridiculous. And because the whole point of this is octaves and more general flipping it imposes boundaries that don't make sense.

So, I instead need to get the 3 things above working in sequence.

*/

// one more thing: spectral analysis/resynthesis. The analysis happened elsewhere (in SPEAR), he's the resynthesis.
(
var freqs, foo, f0, dur, amps, durs;

freqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239];
foo = freqs.size;
f0 = freqs[0];
dur = 2;

// calculate amps and durs now for potential reuse
amps = Array.fill(foo, {arg i; f0 / freqs[i] / foo});
durs = Array.fill(foo, {arg i; dur * ((f0 / freqs[i])**0.5)});

// if I want to mess around...
// amps = amps.reverse;
// durs = durs.reverse;

// freqs from below, to push all into an octave
// freqs= [ 231.5, 288.125, 312.375, 330.625, 202.4375, 240.9375, 263.75, 292.25, 297.3125, 185.28125, 187.34375, 189.96875, 192.28125, 194.5625, 226.21875 ]*2;

// freqs from further below to invert about 2000Hz
// freqs = [ 512.75067916442, 205.99007761659, 189.99885110294, 179.51120185491, 146.59065418532, 123.1665704037, 112.51353765551, 101.5413021613, 99.812303743168, 80.082160382231, 79.200521919308, 78.106124182637, 77.166768877986, 76.26198665375, 65.590154566411 ] * 8;

foo.do{
	arg i;
	{var sound, env;
		sound = SinOsc.ar(freqs[i]) * amps[i];
		env = EnvGen.ar(Env(times:[0.01, durs[i]]), doneAction:2);
		sound*env
	}.play
};
)

// some test runs of: compressing into an octave

(
var shiftoct, freqs, newfreqs, whichoct, max, min;

shiftoct = { // function to octave-shift a frequency until between maxs and mins
	arg freq, max, min;
	if((freq > max), // test
		{shiftoct.value(freq / 2, max, min)}, // then
		// else
		{if((freq > min),
			{freq},
			{shiftoct.value(freq * 2, max, min)}
	)}
	)
};
// nb this crashes if given freq=0

freqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239];
whichoct = 6; // 0 is just below Nyquist, higher is lower
max = 22050/(2**whichoct);
min = max/2;
newfreqs = Array.fill(freqs.size, {
	arg i; // new array: for each item in array, octave-shift until between min and max
	shiftoct.value(freqs[i], max, min);
}
);
)

// and pitch inversion around a given two-pitch axis

(
var axislo, axishi, axissquared, freqs, newfreqs;

axishi = 22050;
axislo = 22050/1024;
axissquared = axishi * axislo;
freqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239];
newfreqs = freqs.collect({arg i; axissquared/i});
)


// actually play the sample

~thebuf = Buffer.read(s, "/Volumes/snd/users/nkahrs/2 Fall 2018/cmp-412.git/trunk/10 06 brake drum single hit mono.wav")
~thebuf
(
{
	var pitch, time, pitchshift;
	pitch = 1/8; // pitch ratio
	time = 1/8; // time ratio
	// play rate = time shift
	// pitch shift = pitch / time. Only kinda works, but for this that's fine.
	pitchshift = pitch/time;
	LPF.ar(
		PitchShift.ar(PlayBuf.ar(1, ~thebuf,time, doneAction:2), 0.05, pitchshift),
		min(7500*pitch, 22050))
	.dup
}.play
)


/* to do: modularize each component.
Need synths for:
FFT inversion
File playback
FFT octave compression (just hardcode it, each octave). Maybe ignore this if it just sounds bad.

Need functional shorthands for:
filter octave compression
additive resynthesis for any combo of transposition, inversion, octave compression

see 2_sets_synthdefsfunctions for that
*/


/*
10/8 todo: outline piece
needs to be at least a minute

15 seconds: first just time-shifting and FFT inversion, then a bit of "octave"-shifting (about 5 sec of each)
10 seconds: introduce additive resynthesis via reverse envelope
10 seconds: use normal envelope, big inversion, and pitch-transposition

10 seconds: move to pitch classes: suddenly compress resynth into an octave
10 seconds: introduce the filterbank as a parallel! Do the same thing with filterbank/samples and pcs compressed into an octave

quasi-closing gesture: additive synth adding notes one at a time, and slowly crossfading to FFT inversion (switching panning meanwhile). Do by sending to two buses (left/right processing), which go to four buses (left/right plain, right/left fft'd), and crossfade stuff in those buses
15 seconds: inversion in combo with filters, versus both increasingly stretched original and a resynth

Durations: cycle through something proportional to the peak frequencies
Panning: just alternate hard left/right


Preliminary Title: Infared Mosquito
Preliminary Program Note:

The two fundamental operations of atonal theory are transposition preserving duration, and inversion preserving timbre. These both present fundamental problems in electronic music---when dealing with waveforms, transposition involves changing speed, and inversion is almost nonsensical due to the absence of an abstract axis. Likewise, octave equivalence is also critical, yet is unrecognized by waveforms.

This piece drags the atonal notions of octave equivalence (a special case of transposition) and inversion into the domain of spectra, and examines their resistance. I begin with a brake drum sound (a hint to Jasmine Thomasian), which is promply both transposed without time adjustment and stretched without transposition---both introducing artefacts--and then "inverted" in that its FFT is flipped upside-down with inherently imprecise logarithmic scaling. I then match these sounds with their more familiar atonal counterparts treating the brake drum only as a set of sinusoids. I then compress these sounds into individual octaves---a familiar atonal operation when one looks for a normal order---both via filters and via direct manipulation of frequencies, and conclude by using all of these operations in combination, trying to get the same result multiple ways but instead only hearing how it goes wrong.

The title refers to flipping frequencies from FFT bin 512 to 1: the mosquito (above the upper frequency limit of our hearing) becomes infared (below the lower limit).

*/


// making a duration scheme
2*926/[926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239]
~foo = Pseq(2*926/[926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239], inf).asStream;


// most drafting has occured separately and/or gone straight into the piece, but a few things to work out offline now that I'm finishing it...

// quasi-closing gesture: additive synth adding notes one at a time, and slowly crossfading to FFT inversion (switching panning meanwhile). Do by sending to two buses (left/right processing), which go to four buses (left/right plain, right/left fft'd), and crossfade stuff in those buses

(
var allfreqs, tmp;
allfreqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239];

Routine({
	tmp = Array.fill(3, {Bus.audio(s)});
	tmp.postln;
	s.sync;

	{Out.ar(0, In.ar(tmp[0]) * EnvGen.kr(Env([0,1,0], [0.01,8], \sqr), doneAction:2))}.play;
	{Out.ar(1, In.ar(tmp[0]) * EnvGen.kr(Env([0,1,0], [8, 0.01], \sqr), doneAction:2))}.play;
	{Out.ar(1, In.ar(tmp[1]) * EnvGen.kr(Env([0,1,0], [0.01,8], \sqr), doneAction:2))}.play;
	{Out.ar(0, In.ar(tmp[1]) * EnvGen.kr(Env([0,1,0], [8, 0.01], \sqr), doneAction:2))}.play;

	~additive.value(allfreqs, 8, true, nil, 8, tmp[0], 2, true);

	Synth(\fftInv, [\inBus, tmp[2], \outBus, tmp[1]]);
	Synth(\bdPTRev, [\pitch, 8, \time, 1.148/8, \mul, 20,
		\outBus, tmp[2]]);

	8.wait;
	tmp.do{arg i; i.free;};
	tmp.postln;
}).play;
)


// args for ~additive: freqs, dur, invert, octave, transpose, outBus, mul, reverse;


// using both filterbank and FFT flip?
~bus
~cus
~cus = Bus.audio(s);

Synth(\fftInv, [\inBus, ~cus, \outBus, 0])
Synth(\bdPT, [\pitch, 0.25, \time, 0.25, \mul, 100, \outBus, ~bus])
Synth(\bdPTRev, [\pitch, 0.25, \time, 0.5, \mul, 10, \outBus, ~bus])
~inOct.value(8, ~bus, 40, ~cus)

/* last section: alternate between (0) sound->fftinv->inoct, (1) sound->inoct->fftinv, (2) additive with both octave shift and inversion

hard pan all...
in total we'll need four buses (sound->fftinv, fftinv->inoct, sound->inoct, inoct->fftinv) and I'll just manually free some synths
