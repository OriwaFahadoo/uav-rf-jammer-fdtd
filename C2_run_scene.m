function C2_run_scene(stage, d_list, ground)
% C2_RUN_SCENE  Full scene for one stage: jammer driven, the frozen TX terminated in the 50 ohm receiver.
%   C2_run_scene('A')                      distances 100, 500, 1000, 2000 mm over the PEC ground
%   C2_run_scene('A', 1010, false)         free space at 1.01 m: the direct check against the case figure
% Finished runs (results/<tag>/done.txt) are skipped; delete the folder to redo one.
if nargin < 1, stage = 'A'; end
if nargin < 2 || isempty(d_list), d_list = [100 500 1000 2000]; end
if nargin < 3 || isempty(ground), ground = true; end
setup_paths;
for d = d_list
  P = case_params(stage, d, ground);
  if ~exist(P.root, 'dir'), mkdir(P.root); end
  here = cd(P.root);
  if exist(fullfile(P.tag, 'done.txt'), 'file')
    fprintf('%s: already done, skipped\n', P.tag); cd(here); continue;
  end
  if exist(P.tag, 'dir'), rmdir(P.tag, 's'); end
  mkdir(P.tag);
  [CSX, FDTD, ~, ~, info] = build_scene(P, 'jam');
  WriteOpenEMS(fullfile(P.tag, 'scene.xml'), FDTD, CSX);
  fprintf('\n=== %s: %.2f M cells ===\n', P.tag, info.ncells/1e6);
  t = tic;
  RunOpenEMS(P.tag, 'scene.xml', '--numThreads=4');
  fid = fopen(fullfile(P.tag, 'done.txt'), 'w'); fprintf(fid, '%.1f min\n', toc(t)/60); fclose(fid);
  fprintf('=== %s finished in %.1f min ===\n', P.tag, toc(t)/60);
  cd(here);
end
end
