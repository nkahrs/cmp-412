(
Routine({
	var dur, pattern, ch, thisdur;
	var fftInv, fftInvLS, fftInvRS;

	pattern = Pseq(2*926/[926,2305,2499,2645,3239,3855,4220,4676,4757,5929,5995,6079,6153,6226,7239].reverse, inf).asStream; // recurring pattern to draw durations etc from
	dur = 0; // duration elapsed
	ch = 0; // left or right?

	// two FFT inversion channels pointing going opposite directions: busses and synths
	fftInv = [Bus.audio(s), Bus.audio(s)];
	fftInvLS = Synth(\fftInv, [\inBus, fftInv[0], \outBus, 0]);
	fftInvRS = Synth(\fftInv, [\inBus, fftInv[1], \outBus, 1]);

	while({dur < 5}, { // 5 seconds just time-shifting
		thisdur = pattern.next;
		thisdur.postln;
		Synth(\bdPT, [\pitch, 1, \time, 0.25/thisdur, \mul, (1+thisdur)**2-1, \outbus, ch]);
		ch = 1 - ch;
		dur = dur + thisdur;
		thisdur.wait;
	});
	["1a done", dur].postln;

	dur = 0;
	while({dur < 5}, { // 5 seconds, introduce FFT inversion thing
		thisdur = pattern.next;
		thisdur.postln;
		Synth(\bdPT, [\pitch, 1, \time, (1/6)/thisdur, \mul, 10*max((1+thisdur)**3-1,1),
			\outBus, fftInv[ch]]);
		ch = 1 - ch;
		dur = dur + thisdur;
		(thisdur*1.5).wait;
	});
	["1b done", dur].postln;

	// cleanup
	[fftInv[0], fftInv[1], fftInvLS, fftInvRS].do{arg i; i.free;};
	"resources freed".postln;

}).play;
)
