blocks = find_system('sldemo_absbrake', 'BlockType', 'Lookup_n-D');

for i = 1:numel(blocks)
    fprintf('Block %d: %s\n', i, blocks{i});
    fprintf('  Breakpoints: %s\n', get_param(blocks{i}, 'BreakpointsForDimension1'));
    fprintf('  Table: %s\n\n', get_param(blocks{i}, 'Table'));
end