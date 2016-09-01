function errstr = converterror(value,err,opt,prec)

% Format Value and Error into a single string
% if opt='pm' then format with "+/-",else with brackets
% prec for additional precision (e.g. prec = 2 for the two first
% significant digits), default: 1

% P. Steffens, 09/2012

pm = nargin>2 && strcmpi(opt,'pm');
if nargin<4, prec = 1; end

if err<=0
    errstr = num2str(value);
    if pm, errstr = [errstr, ' \pm 0']; end
    return;
end

% position of first significant digit in err
pos = floor(log(err)/log(10)) - prec + 1;

if round(err / 10^pos)==1, pos = pos - 1; end

pos = min([pos,0]);  % Never round before decimal point

%     rerr = round(err/10^(pos-1));    
%     rval = round(value/10^(pos-1))  * 10^(pos-1); 
%     if pm, rerr = rerr * 10^(pos-1); end
% else
    rerr = round(err/10^pos);
    rval = round(value/10^pos)  * 10^pos;
    if pm, rerr = rerr * 10^pos; end
% end

if pm
    if pos<0, fstring = ['%0.' num2str(abs(pos)) 'f']; else fstring = '%d'; end
    errstr = [num2str(rval,fstring),' \pm ', num2str(rerr,fstring)];
else
    errstr = [num2str(rval) '(' num2str(rerr) ')'];
end
    



