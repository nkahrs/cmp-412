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

(
{
	var sound, chain, balance;
	sound = SoundIn.ar(0);
	//sound = Pulse.ar(MouseX.kr(40,4000));
	chain = FFT(LocalBuf(1024), sound);
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