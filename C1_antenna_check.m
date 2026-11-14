function C1_antenna_check(stage, ground, what)
% C1_ANTENNA_CHECK  Each antenna alone: resonance, S11, Zin, realized gain, pattern.
%   C1_antenna_check('A')           jammer of Stage A alone over the PEC ground (as in Stage A)
%   C1_antenna_check('C', false)    TSA600 alone in free space: the Case 1 / Case 4 gain calibration
%   C1_antenna_check('A', true, 'tx')  the frozen TX alone (same for every stage)
% Results: results/check_<who>_<pec|free>/check.mat
if nargin < 1, stage = 'A'; end
if nargin < 2 || isempty(ground), ground = true; end
if nargin < 3, what = 'jam'; end
setup_paths;
P = case_params(stage, 0, ground);
if ground, g = 'pec'; else, g = 'free'; end
if strcmp(what, 'tx'), who = 'tx'; else, who = ['jam' P.stage]; end
if ~exist(P.root, 'dir'), mkdir(P.root); end
here = cd(P.root);
path = ['check_' who '_' g];
if exist(fullfile(path, 'check.mat'), 'file')
  fprintf('%s: already done, skipped\n', path); cd(here); return;
end
if exist(path, 'dir'), rmdir(path, 's'); end
mkdir(path);
[CSX, FDTD, port, nf2ff, info] = build_scene(P, what, {what});
WriteOpenEMS(fullfile(path, 'scene.xml'), FDTD, CSX);
fprintf('\n=== %s alone (%s): %.2f M cells ===\n', who, g, info.ncells/1e6);
t = tic;
RunOpenEMS(path, 'scene.xml', '--numThreads=4');
Rz = [P.tx.R P.jam.R];
port{info.active} = calcPort(port{info.active}, path, P.freq, 'RefImpedance', Rz(info.active));
r = port_results(port, info.active, P);
F = farfield(nf2ff, path, P, info, r, 'farfield_3D.vtk');
i0 = r.i0;
if ~ground, F.Greal = F.Greal_fs; F.Gmax_dBi = 10*log10(max(F.Greal(:))); end
% gain towards -x (boresight of the directional jammers), at the horizon
[~, it] = min(abs(F.th - pi/2));  [~, ip] = min(abs(F.ph - pi));
F.G_bore_dBi = 10*log10(F.Greal(it, ip));
F.G_bore_fs_dBi = 10*log10(F.Greal_fs(it, ip));
F.G_back_fs_dBi = 10*log10(F.Greal_fs(it, 1));
save(fullfile(path, 'check.mat'), 'r', 'F', 'P', 'info');
cd(here);
fprintf('%s alone (%s): f_res %.3f GHz | @2.4 GHz S11 %.1f dB, Zin %.1f%+.1fj ohm | max realized gain %.2f dBi, towards -x %.2f dBi (free-space part %.2f, back %.2f) | eff %.0f %% | %.1f min\n', ...
  who, g, r.f_res/1e9, 20*log10(abs(r.s11(i0))), real(r.zin(i0)), imag(r.zin(i0)), F.Gmax_dBi, ...
  F.G_bore_dBi, F.G_bore_fs_dBi, F.G_back_fs_dBi, 100*F.eff, toc(t)/60);
end
