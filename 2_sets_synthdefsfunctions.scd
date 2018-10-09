// to load buffer
// synthdefs
(
// FFT-based inversion
SynthDef(\fftInv, {
	arg inBus, outBus;
	var sound, chain;
	sound = In.ar(inBus);
	chain = FFT(LocalBuf(1024), sound); // hardcoded FFT size of 1024
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
	Out.ar(outBus, IFFT(chain))
}).load(s);

~thebuf = Buffer.read(s, "/Volumes/snd/users/nkahrs/2 Fall 2018/cmp-412.git/trunk/10 06 brake drum single hit mono.wav");
SynthDef(\bdPT, {
	arg pitch, time, mul, outBus; // ratios of pitch and time, gain as multiplier, bus to sendo ut
	var pitchshift;
	// play rate = time shift
	// pitch shift = pitch / time. Only kinda works, but for this that's fine.
	pitchshift = pitch/time;
	Out.ar(outBus, mul*LPF.ar(
		PitchShift.ar(PlayBuf.ar(1, ~thebuf,time, doneAction:2), 0.05, pitchshift),
		min(7500*pitch, 22050)));
}).load(s);
)

// functions
(
~inOct={
	arg target, inbus;
	{
		var sound, filterbank, pitchshifts;
		sound = In.ar(inbus);
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
		Mix.ar(pitchshifts)
	}.play
};

// helpers to the big resynthesis one
~shiftoct = { // function to octave-shift a frequency until between maxs and mins
	arg freq, max, min;
	if((freq > max), // test
		{~shiftoct.value(freq / 2, max, min)}, // then
		// else
		{if((freq > min),
			{freq},
			{~shiftoct.value(freq * 2, max, min)}
	)}
	)
};

~shiftocts = {// for an entire list of frequencies
	arg freqs, max, min;
	var newfreqs;
	newfreqs = freqs.collect{arg i; ~shiftoct.value(i, max, min)};
	newfreqs
};

~inverts = {// "invert" a whole list of frequencies
	arg freqs;
	freqs.collect({arg i; 22050*22050/1024/i}) // fixed parameters: 22050 maps to 10 octaves down, vice versa
};

~additive = {// additive resynthesis with a lot of controls
	arg freqs, dur, invert, octave, transpose, outBus, mul;
	/* freqs: list of input frequencies
	dur: duration in seconds
	invert: if true, invert freqs; otherwise (including nil) no
	octave: put all freqs into a given octave (below nyquist), or ignore if not number
	transpose: transpose output by ratio if specified, or default to 1 if not number
	outBus: which bus to send out to (default 0)
	multiplier: how much to multiply output by (default 1)
	*/

	var foo, f0, amps, durs;
	foo = freqs.size;
	f0 = freqs[0];

	// calculate amps and durs now based on original spectral envelope: higher means shorter and softer
	amps = Array.fill(foo, {arg i; f0 / freqs[i] / foo});
	durs = Array.fill(foo, {arg i; dur * ((f0 / freqs[i])**0.5)});

	// I should add a way to reverse either of these

	if(invert==true, {freqs = ~inverts.value(freqs)});
	if(octave.isNumber, {
		var max, min;
		max = 22050/(2**octave);
		min = max/2;
		freqs = ~shiftocts.value(freqs, max, min);
	});
	if(transpose.isNumber, {freqs = freqs.collect({arg i; i*transpose})});

	if(outBus.isNil, {outBus = 0});
	if(mul.isNil, {mul = 1});

	// actual resynthesis
	foo.do{
		arg i;
		{var sound, env;
			sound = SinOsc.ar(freqs[i]) * amps[i];
			env = EnvGen.ar(Env(times:[0.01, durs[i]]), doneAction:2);
			Out.ar(outBus, mul*sound*env);
		}.play
	};
};
)


// test
~bus = Bus.audio(s);
{Out.ar(~bus, SinOsc.ar(MouseX.kr(20, 2000)))}.play
Synth(\fftInv, [\inBus, ~bus, \outBus, 0])
Synth(\bdPT, [\pitch, 1, \time, 1, \mul, 10, \outBus, ~bus])
~inOct.value(8, ~bus)
// to just play from bus
{In.ar(~bus)}.play
~additive.value([926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239], 5, true, nil, 1, ~bus, 1)


// functionality I need to add: reverse envelopes!
// have ~additive pass back the three arrays?