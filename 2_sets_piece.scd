(
Routine({
	var dur, pattern, ch, thisdur, allfreqs, totaldur;
	var fftInv, fftInvLS, fftInvRS;

	allfreqs = [926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239]; // brake drum spectrum
	pattern = Pseq(2*926/allfreqs.reverse, inf).asStream; // recurring pattern to draw durations etc from
	dur = 0; // duration elapsed
	totaldur = 0;
	ch = 0; // left or right?

	// two FFT inversion channels pointing going opposite directions: busses and synths
	fftInv = [Bus.audio(s), Bus.audio(s)];
	fftInvLS = Synth(\fftInv, [\inBus, fftInv[0], \outBus, 0]);
	fftInvRS = Synth(\fftInv, [\inBus, fftInv[1], \outBus, 1]);

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
	while({dur < 10}, { // introduce additive resynthesis
	thisdur = pattern.next;
	Synth(\bdPT, [\pitch, thisdur, \time, thisdur, \mul, 1, \outBus, ch]);
	ch = 1 - ch;
	~additive.value(allfreqs, 2/3/thisdur, false, nil, thisdur, ch, 1, true);
	dur = dur + (1/thisdur);
	(1/thisdur).postln.wait;
	thisdur = pattern.next;

	Synth(\bdPTRev, [\pitch, thisdur, \time, thisdur, \mul, 1, \outBus, ch]);
	ch = 1 - ch;
	~additive.value(allfreqs, 2/3/thisdur, false, nil, thisdur, ch, 1, false);
	dur = dur + (1/thisdur);
	(1/thisdur).postln.wait;
	});
	["2 done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	while({dur < 10}, { // combine additive synthesis with inversion
		thisdur = 1/2/(pattern.next);
		// ~additive.value(allfreqs, thisdur, true, nil, thisdur, ch, 1, false);
		// ch = 1 - ch;
		thisdur = 1/2/(pattern.next);
		Synth(\bdPTRev, [\pitch, thisdur, \time, thisdur, \mul, 10**(1/thisdur), \outBus, fftInv[ch]]);
		ch = 1 - ch;
		~additive.value(allfreqs, thisdur, true, nil, thisdur, fftInv[ch], 10**(2/thisdur), true);
		ch.postln;
		thisdur.postln.wait;
		dur = dur + thisdur;
	});
	["3 done", dur].postln;

	totaldur = totaldur + dur;
	dur = 0;
	// cleanup
	[fftInv[0], fftInv[1], fftInvLS, fftInvRS].do{arg i; i.free;};
	"resources freed".postln;
	("total duration: " ++ totaldur).postln;


}).play;
)

~foo = 2*926/[926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239]
~foo.linexp(0, 1, 2.5, 7).round
~foo

1/(((0.25/thisdur).linexp((1/16),1,4,1).round)