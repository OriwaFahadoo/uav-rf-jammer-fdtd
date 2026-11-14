function v = add_fill(v, fill, res)
% ADD_FILL  Add a regular block of mesh lines 'fill' to the fixed lines v, leaving out the fill lines that
% fall within 0.6 * res of a line already in v (avoids tiny cells next to the antenna's own lines).
keep = true(size(fill));
for k = 1:numel(fill)
  if any(abs(v - fill(k)) < 0.6 * res), keep(k) = false; end
end
v = [v fill(keep)];
end
