function F = farfield(nf2ff, path, P, info, r, vtkname)
% FARFIELD  Far-field pattern of the driven antenna at f0.
%   Realized gain uses the incident power, so mismatch and anything that absorbs
%   power is included. With the ground plane, the far-field box only sees the
%   antenna itself; the ground reflection is added here as the image antenna
%   (exact for an infinite PEC ground) and only the upper half space counts.
%   (openEMS's own 'Mirror' option gave wrong lobes for a box above the ground.)

% The antenna and its image are many wavelengths apart: sample theta finely.
if P.ground, dth = 0.5; else, dth = 2; end
dph = 3;
th = (0:dth:180) * pi/180;  ph = (0:dph:360-dph) * pi/180;
nf = CalcNF2FF(nf2ff, path, P.f0, th, ph, 'Center', info.center * P.unit, ...
               'Outfile', 'farfield.h5', 'Mode', 1);
Et = nf.E_theta{1};  Ep = nf.E_phi{1};                % (theta x phi), phase centre at the feed
Z0 = 376.730313;
F.Greal_fs = 4*pi * nf.r^2 * (abs(Et).^2 + abs(Ep).^2) / (2*Z0) / r.Pinc;   % antenna alone, no ground (free space)
if P.ground
  % image of a source at height h over PEC: vertical currents keep their sign,
  % horizontal ones flip; seen at theta it radiates like the original at pi - theta
  k  = 2*pi / (P.lambda * P.unit);
  h  = info.center(3) * P.unit;
  af = repmat(exp(-1j * 2*k*h * cos(th(:))), 1, numel(ph));
  Et = Et + flipud(Et) .* af;
  Ep = Ep - flipud(Ep) .* af;
end

U  = nf.r^2 * (abs(Et).^2 + abs(Ep).^2) / (2*Z0);    % radiation intensity W/sr
w  = sin(th(:)) * (dth*pi/180) * (dph*pi/180);       % solid-angle weights
if P.ground
  w(th > pi/2 + 1e-9) = 0;
  w(abs(th - pi/2) < 1e-9) = w(abs(th - pi/2) < 1e-9) / 2;
  U(th > pi/2 + 1e-9, :) = 0;                        % below the ground: no field
end
F.Prad  = sum(sum(U .* w));                          % radiated power (W)
F.eff   = F.Prad / r.Pacc;                           % radiation efficiency (~100% for a metal antenna)
F.Greal = 4*pi*U / r.Pinc;                           % realized gain (linear) vs (theta, phi)
F.D     = 4*pi*U / F.Prad;                           % directivity (linear)
F.Gmax_dBi = 10*log10(max(F.Greal(:)));
F.Dmax_dBi = 10*log10(max(F.D(:)));
F.th = th; F.ph = ph;
if nargin > 5
  G = F.Greal(:, [1:end 1]);                          % close the surface at phi = 360
  DumpFF2VTK(fullfile(path, vtkname), sqrt(G / max(G(:))), th*180/pi, [ph 2*pi]*180/pi, 'scale', 1);
end
end
