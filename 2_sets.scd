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
	// sound = SinOsc.ar(22050/32);
	target = 3; // how many octaves below Nyquist to target
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

// freqs from below, to push all into an octave
// freqs= [ 231.5, 288.125, 312.375, 330.625, 202.4375, 240.9375, 263.75, 292.25, 297.3125, 185.28125, 187.34375, 189.96875, 192.28125, 194.5625, 226.21875 ]*2;

// freqs from further below to invert about 2000Hz
// freqs = [ 512.75067916442, 205.99007761659, 189.99885110294, 179.51120185491, 146.59065418532, 123.1665704037, 112.51353765551, 101.5413021613, 99.812303743168, 80.082160382231, 79.200521919308, 78.106124182637, 77.166768877986, 76.26198665375, 65.590154566411 ];

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
