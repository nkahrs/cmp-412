(
Routine({
	var dur, pattern, ch, thisdur, allfreqs, totaldur, tmp;
	var fftInv, fftInvLS, fftInvRS, octShift;

	allfreqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239]; // brake drum spectrum
	pattern = Pseq(2*926/allfreqs.reverse, inf).asStream; // recurring pattern to draw durations etc from
	dur = 0; // duration elapsed
	totaldur = 0;
	ch = 0; // left or right?

	// two FFT inversion channels pointing going opposite directions: busses and synths
	fftInv = [Bus.audio(s), Bus.audio(s)];
	octShift = [Bus.audio(s), Bus.audio(s)];
	fftInvLS = Synth(\fftInv, [\inBus, fftInv[0], \outBus, 0]);
	fftInvRS = Synth(\fftInv, [\inBus, fftInv[1], \outBus, 1]);
	s.sync;

	while({dur < 5}, { // 5 seconds just time-shifting
		thisdur = pattern.next;
		thisdur.postln;
		Synth(\bdPT, [\pitch, 1, \time, 0.25/thisdur, \mul, (1+thisdur)**2-1, \outBus, ch]);
		ch = 1 - ch;
		dur = dur + thisdur;
		thisdur.wait;
	});
	["1a done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 5}, { // 5 seconds, introduce FFT inversion thing
		thisdur = pattern.next;
		thisdur.postln;
		Synth(\bdPT, [\pitch, 1, \time, (1/6)/thisdur, \mul, 10*min((1+thisdur)**3-1,1),
		\outBus, fftInv[ch]]);
		ch = 1 - ch;
		dur = dur + thisdur;
		(thisdur).wait;
	});
	["1b done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 5}, { // 5 seconds, have 2 normal, 1 inverted, all "octave"-shifted
		var thispitch;
		2.do{
			thisdur = pattern.next;
			thispitch = 1/((0.25/thisdur).linexp((1/16),1,4,1).round);
			[thisdur, thispitch].postln;
			Synth(\bdPT, [\pitch, thispitch,
			\time, 0.25/thisdur, \mul, (1+thisdur)**2-1, \outBus, ch]);
			ch = 1 - ch;
			dur = dur + thisdur;
			thisdur.wait;
		};
		thisdur = pattern.next;
		thispitch = ((0.25/thisdur).linexp((1/16),1,4,1).round);
		[thisdur, thispitch, "fft"].postln;
		Synth(\bdPT, [\pitch, thispitch,
		\time, 4*thisdur, \mul, (1+thisdur)**6-1, \outBus, fftInv[ch]]);
		ch = 1 - ch;
		dur = dur + (2*thisdur/3);
		(2*thisdur/3).wait;
	});
	["1c done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	tmp = ch;
	while({dur < 10}, { // introduce additive resynthesis
		thisdur = 1.5 * pattern.next;

		if( (tmp==ch), {
			Synth(\bdPTRev, [\pitch, thisdur, \time, thisdur, \mul, 1, \outBus, ch]);
			~additive.value(allfreqs, 2/3/thisdur, false, nil, thisdur, ch, 1, false);
			}, {
			Synth(\bdPT, [\pitch, thisdur, \time, thisdur, \mul, 1, \outBus, ch]);
			~additive.value(allfreqs, 2/3/thisdur, false, nil, thisdur, ch, 1, true);
		});

		ch = 1 - ch;
		dur = dur + (1/thisdur);
		(1/thisdur).postln.wait;

	});
	["2 done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 10}, { // combine additive synthesis with inversion
		thisdur = 1/2/(pattern.next);
		Synth(\bdPTRev, [\pitch, thisdur, \time, thisdur, \mul, min(20,10**(1/thisdur)), \outBus, fftInv[ch]]);
		ch = 1 - ch;
		~additive.value(allfreqs, thisdur, true, nil, thisdur, fftInv[ch], 10**(2/thisdur), true);
		thisdur.postln.wait;
		dur = dur + thisdur;
	});
	["3 done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 7}, { // pcs compressed into an octave, but recapitulating style of opening
		thisdur = pattern.next;
		(thisdur*[1,1.5]).postln;
		~additive.value(allfreqs, thisdur*4, false, min(8,thisdur*8.round), thisdur, ch, min((1+thisdur)**2-1, 2), false);
		ch = 1 - ch;
		thisdur = thisdur*1.5;
		dur = dur + thisdur;
		thisdur.wait;
	});
	["4a done", dur].postln;


	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 9}, { // recapitauling style of opening, but with filterbank
		thisdur = pattern.next;
		thisdur.postln;
		~inOct.value(min(8,thisdur*8.round),
			octShift[ch], thisdur*1.25, ch);
		s.sync;
		Synth(\bdPT, [\pitch, 1, \time, 0.25/thisdur, \mul, min((1+thisdur)**2-1, 10), \outBus, octShift[ch]]);
		ch = 1 - ch;
		thisdur = thisdur*1.5;
		dur = dur + thisdur;
		thisdur.wait;
	});
	["4b done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	// a big crossfade of FFT inversion versus pitch inversion
	tmp = [Bus.audio(s), Bus.audio(s), Bus.audio(s), nil];
	s.sync;
	{Out.ar(0, In.ar(tmp[0]) * EnvGen.kr(Env([0,1,0], [0.01,8], \sqr), doneAction:2))}.play;
	{Out.ar(1, In.ar(tmp[0]) * EnvGen.kr(Env([0,1,0], [8, 0.01], \sqr), doneAction:2))}.play;
	{Out.ar(1, In.ar(tmp[1]) * EnvGen.kr(Env([0,1,0], [0.01,8], \sqr), doneAction:2))}.play;
	{Out.ar(0, In.ar(tmp[1]) * EnvGen.kr(Env([0,1,0], [8, 0.01], \sqr), doneAction:2))}.play;
	~additive.value(allfreqs, 8, true, nil, 8, tmp[0], 2, true);
	tmp[3] = Synth(\fftInv, [\inBus, tmp[2], \outBus, tmp[1]]);
	Synth(\bdPTRev, [\pitch, 8, \time, 1.148/8, \mul, 20,
		\outBus, tmp[2]]);
	8.wait;
	tmp.do{arg i; i.free;};
	"5 done in 8".postln;
	totaldur = totaldur + 8;

	// closing section: trade off between buffer->fftinv->inoct, buffer->inoct->fftinv, and an additive synth
	// requires four buses (0-3), two synth-holders (4-5)), and (6) something to keep track of where we are in the cycle

	thisdur = 0;

	tmp = [Bus.audio(s), Bus.audio(s), Bus.audio(s), Bus.audio(s), nil, nil, 0];
	s.sync;
	2.do{
		while({thisdur < 2}, {// go twice, finish on the long note
			var thisoct, thismul, thistime;

			thisdur = pattern.next;

			thisoct = min(7, (thisdur*8).round)-1;
			thistime = thisdur;
			thismul = min((1+thisdur)**2, 5);
			[[thisoct, thistime, thismul], tmp[6]].postln;

			switch(tmp[6],
				0, { // sound -> fftinv -> inoct (clear last "1")
					tmp[5].free;
					tmp[5] = nil;
					~inOct.value(thisoct, tmp[0], 2*thisdur, ch); s.sync;
					tmp[4] = Synth(\fftInv, [\inBus, tmp[1], \outBus, tmp[0]]); s.sync;
					Synth(\bdPT, [\pitch, thistime, \time, thistime, \mul, 4**thismul, \outBus, tmp[1]]);
				},
				1, { // sound -> inoct -> fftinv
					tmp[4].free;
					tmp[4] = nil;
					tmp[5] = Synth(\fftInv, [\inBus, tmp[2], \outBus, ch]); s.sync;
					~inOct.value(thisoct, tmp[3], 2*thisdur, tmp[2]); s.sync;
					Synth(\bdPT, [\pitch, thistime, \time, thistime, \mul, 4**thismul, \outBus, tmp[3]]);
				},
				2, { // additive (clear last "0")
					~additive.value(allfreqs, 2/thisdur, true, thisoct, nil, ch, 0.75**thismul, false)
					// args for ~additive: freqs, dur, invert, octave, transpose, outBus, mul, reverse;
				}
			);

			ch = 1 - ch;
			tmp[6] = (tmp[6] + 1) % 3;

			dur = dur + thisdur;
			thisdur.wait;
		});
		thisdur = pattern.next;
	};
	["6 done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	// cleanup
	("total duration: " ++ totaldur).postln;
	"waiting 5 seconds for reverb".postln;
	5.wait;

	[fftInv[0], fftInv[1], fftInvLS, fftInvRS, octShift[0], octShift[1]].do{arg i; i.free;};
	6.do{arg i; if(tmp[i]==nil, {}, {tmp[i].free});};
	"resources freed".postln;


}).play;
)