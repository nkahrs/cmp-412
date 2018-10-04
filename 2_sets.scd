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