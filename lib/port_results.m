function r = port_results(port, a, P)
% Port impedances: TX = P.tx.R, jammer = P.jam.R (the TSA600 port is not 50 ohm). s21 is power-normalised.
% PORT_RESULTS  Match of the driven port a and its transmission into the other port (TX = 1, jammer = 2).
[~, i0] = min(abs(P.freq - P.f0));
r.i0   = i0;
r.s11  = port{a}.uf.ref ./ port{a}.uf.inc;
r.zin  = port{a}.uf.tot ./ port{a}.if.tot;
r.Pinc = port{a}.P_inc(i0);
r.Pacc = port{a}.P_acc(i0);
o = 3 - a;
r.s21 = [];
Rz = [P.tx.R P.jam.R];
if ~isempty(port{o}), r.s21 = (port{o}.uf.ref / sqrt(Rz(o))) ./ (port{a}.uf.inc / sqrt(Rz(a))); end
x = imag(r.zin); k = find(sign(x(1:end-1)) ~= sign(x(2:end)));
if isempty(k), r.f_res = NaN;
else
  [~, j] = min(abs(P.freq(k) - P.f0)); k = k(j);
  r.f_res = P.freq(k) - x(k) * (P.freq(k+1) - P.freq(k)) / (x(k+1) - x(k));
end
end
