% SETUP_PATHS  Called by every step script. Finds openEMS; set OPENEMS_DIR if it is somewhere else.
%   Mac (MacPorts): '/opt/local'     Linux build: '/opt/openEMS' or ~/opt/openEMS     Windows: 'C:\openEMS'
OPENEMS_DIR = getenv('OPENEMS_DIR');
if isempty(OPENEMS_DIR)
  for c = {'/opt/local', '/opt/openEMS', fullfile(getenv('HOME'), 'opt', 'openEMS'), 'C:\openEMS'}
    if exist(c{1}, 'dir'), OPENEMS_DIR = c{1}; break; end
  end
end
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here, 'lib'), fullfile(here, 'params'));
cands = {fullfile(OPENEMS_DIR, 'matlab'), fullfile(OPENEMS_DIR, 'CSXCAD', 'matlab'), ...
         fullfile(OPENEMS_DIR, 'share', 'openEMS', 'matlab'), fullfile(OPENEMS_DIR, 'share', 'CSXCAD', 'matlab')};
for k = 1:numel(cands)
  if exist(cands{k}, 'dir'), addpath(cands{k}); end
end
if isempty(which('InitFDTD')) || isempty(which('InitCSX'))
  error('openEMS / CSXCAD MATLAB files not found. Set OPENEMS_DIR in setup_paths.m (now: %s).', OPENEMS_DIR);
end
if exist('OCTAVE_VERSION', 'builtin'), more off; max_recursion_depth(20000);
else, set(0, 'RecursionLimit', 20000); end   % SmoothMesh recurses deeply on the fine TSA600 / reflector meshes
clear here cands k c
