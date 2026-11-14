function v = grade_mesh(v, maxres, ratio)
% GRADE_MESH  Fast replacement for SmoothMesh on one axis, for models with many fixed lines (TSA600, reflector).
% Keeps every fixed line, fills each gap so that no cell exceeds maxres and neighbouring cells grow by at most
% about 'ratio' away from the fine regions. SmoothMesh does the same but is very slow with hundreds of fixed lines.
v = sort(v(:)');
out = v(1);
a = min(maxres, v(2) - v(1));                       % size of the cell to the left of the current line
for i = 1:numel(v) - 1
  G = v(i+1) - v(i);
  if i + 1 < numel(v), b = min(maxres, v(i+2) - v(i+1)); else, b = maxres; end
  if G <= min([maxres, ratio*a, ratio*b]) + 1e-9
    out(end+1) = v(i+1); a = G; continue;           %#ok<AGROW>
  end
  pl = v(i); pr = v(i+1); sl = a; sr = b; L = []; Rr = [];
  while true
    R  = pr - pl;
    nl = min(sl*ratio, maxres); nr = min(sr*ratio, maxres);
    if R <= max(nl, nr) + 1e-9
      if R < 0.5 * min(sl, sr) && (~isempty(L) || ~isempty(Rr))
        % last cell too small: drop the last inserted line and split the merged cell in two
        if ~isempty(L) && (isempty(Rr) || sl >= sr)
          pl = L(end); L(end) = []; if isempty(L), q = v(i); else, q = L(end); end
          L(end+1) = (q + pr) / 2; %#ok<AGROW>
          if ~isempty(Rr), L(end) = (q + pr) / 2; end
        else
          pr = Rr(end); Rr(end) = []; if isempty(Rr), q = v(i+1); else, q = Rr(end); end
          Rr(end+1) = (pl + q) / 2; %#ok<AGROW>
        end
      end
      break;
    end
    if nl <= nr, pl = pl + nl; sl = nl; L(end+1) = pl; %#ok<AGROW>
    else,        pr = pr - nr; sr = nr; Rr(end+1) = pr; %#ok<AGROW>
    end
  end
  seg = sort([L Rr v(i+1)]);
  out = [out seg]; %#ok<AGROW>
  if numel(seg) > 1, a = seg(end) - seg(end-1); else, a = seg(end) - v(i); end
end
v = unique(out);
end
