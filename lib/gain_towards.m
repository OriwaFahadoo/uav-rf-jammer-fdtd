function g = gain_towards(F, from, to, field)
% GAIN_TOWARDS  Gain (linear) of pattern F in the direction from -> to (mm).
%   field: 'Greal' (default, with ground reflection) or 'Greal_fs' (antenna alone).
if nargin < 4, field = 'Greal'; end
d  = to - from;
th = acos(d(3) / norm(d));
ph = mod(atan2(d(2), d(1)), 2*pi);
[~, it] = min(abs(F.th - th));
[~, ip] = min(abs(angle(exp(1i * (F.ph - ph)))));
g = F.(field)(it, ip);
end
