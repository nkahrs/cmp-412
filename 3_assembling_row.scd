(
// two hexachords
~x = [1, 3/2, 5/2, 7/2, 11/2,	33/32];
~y = [1, 3/2, 5/2, 7/2, 11/2,	11/2*3/2];

~x = ~x * (24.midicps);
~y = (1/~y.reverse) * (69.midicps);

// the row
~z = ~x ++ ~y;

// midi quantized version
~qz = (24+[0, 7, 16, 22, 30,	1, 8, 15, 23, 29,	38, 45]).midicps
// to compare...
)

(~zquant/~z).ratiomidi

(
// retrogrades are a bit different registrally
~rz = ~z.reverse;
~rz[5] = ~rz[5] * 8;
~rz[6] = ~rz[6] * 8;

~rqz = ~qz.reverse;
~rqz[5] = ~rqz[5] * 8;
~rqz[6] = ~rqz[6] * 8;
)


(
Routine({
	12.do{
		arg j;
		var i;
		i = [/*~rz[j], */~rqz[j]];
		i.postln;
		// i = i * 4;
		// [i, i.cpsmidi, i.cpsmidi.round % 12].postln;
		{LFSaw.ar(i)*EnvGen.kr(Env())}.play;
		1.wait;
}}).play;
)