function fitfunctions

% call 'fitfunctions' to obtain a list of available functions

files = what('Functions');
if isempty(files), fprintf('Fulder "Functions" not found.\n'); return; end
files = files.m;

fprintf('----------------------------\nList of available functions:\n----------------------------\n');
for nf = 1:length(files)
    fname = files{nf};
    [st,en] = regexp(fname,'\w+(?=\.m$)');
    fname = fname(st:en);
    if ~isempty(fname)
        try
            eval([' [val, paramnames, paramnum, description] = ' fname '([],[]);']);
            fprintf('%15s.m: %s \n', fname, description);
        catch
        end
    end
end

fprintf('Type ''showfunction [functionname]'' for help on particular function.\n');

fprintf('Use file ''template.m'' to implement a new function.\n');
