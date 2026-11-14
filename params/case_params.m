function P = case_params(stage, d_mm, ground)
% CASE_PARAMS  Scene for one stage: frozen Stage A TX at the origin, jammer of that stage at distance d.
%   stage  : 'A' 'B' 'C' 'D' (or 'A0', the old Stage A jammer, for the check)
%   d_mm   : TX feed -> jammer element (whip, or TSA600 mouth) in mm. Default 100 (settled Stage A case)
%   ground : true = PEC ground at z = 0 as in Stage A (default); false = free space (the cases' absorber box)
if nargin < 1, stage = 'A'; end
if nargin < 2 || isempty(d_mm), d_mm = 100; end
if nargin < 3 || isempty(ground), ground = true; end

P.stage  = upper(stage);
P.d_mm   = d_mm;
P.unit   = 1e-3;
P.f0     = 2.4e9;
P.fc     = 0.5e9;
c0       = 299792458;
P.lambda = c0 / P.f0 / P.unit;             % 124.9 mm
P.freq   = linspace(2.0e9, 2.8e9, 401);
P.ground = ground;

P.tx = tx_params();
P.tx.feed = [P.tx.pos P.tx.height];
P.jam = jammer_params(stage);
P.jam.feed = [d_mm 0 P.jam.height];        % element / mouth position
P.rx = rx_params();

% Mesh and run length: same as the settled Stage A (lambda/20, one wavelength to the PML)
P.max_res     = P.lambda / 20;
P.mesh_ratio  = 1.4;
P.pml_margin  = P.lambda + 8 * P.max_res;
P.NrTS        = 200000;
P.EndCriteria = 1e-4;
P.JS_target_dB = 10;

P.nf2ff_margin = P.lambda / 2;
P.dump_fd_h5   = true;                      % 2.4 GHz |E| on the horizontal feed plane
P.scene_ff     = ground && d_mm == 100;      % 0.1 m run also records the whole-scene pattern (plots 08, 09)

% where the runs go: cases/results/<stage>/... (CASES_RESULTS overrides, e.g. a scratch disk)
root = getenv('CASES_RESULTS');
if isempty(root), root = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results'); end
P.root = root;
if ground, g = 'pec'; else, g = 'free'; end
P.tag  = sprintf('stage%s_d%04d_%s', P.stage, round(d_mm), g);
end
