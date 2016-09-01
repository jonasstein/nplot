function [scandata, xlabeltext] = makescandata(plotstruct)

% function [scandata, xlabeltext] = makescandata(plotstruct)
%
% Perform the interpolation/integration/projection according to the
% definition in plotstruct.scandef
% The x-axis coordinate is chosen appropriately (either according to
% definitio, or determined automatically)
% scandata :  x,y,dy of the result
% xlabeltext: Name of the x coordinate

% (This is basically the old content of doscanplot.m)
% P. Steffens 09/2012



%%
% scandata = []; xlabeltext = [];

if ~isfield(plotstruct.scandef,'xdat'), 
    return; end
startpoint = [plotstruct.scandef.xdat(1), plotstruct.scandef.ydat(1)];
endpoint   = [plotstruct.scandef.xdat(2), plotstruct.scandef.ydat(2)];
np         =  plotstruct.scandef.np;

%% construct the scan points
scanpath = repmat(startpoint,np,1) + (0.5:(np-0.5))'/np  * (endpoint-startpoint);

%% Obtain values and errors by interpolation, integration or pojection


if strcmpi(plotstruct.scandef.type,'Interpolation')
    datalist = plotstruct.datalist;
    datalist.coordlist = plotstruct.coordlist;
    datalist.coordtype = plotstruct.type; % ** Translations... unfortunately... conventions should be changed...
        if strcmpi(plotstruct.type,'qeplane'), datalist.coordtype = 'A4ENERGY'; end
        if strcmpi(plotstruct.type,'qxqyen'),  datalist.coordtype = 'ANGLESENERGY'; end
    [scandata.y, scandata.dy]  = linearinterpolation (datalist, [scanpath(:,1), scanpath(:,2)]);
end

if strcmpi(plotstruct.scandef.type,'Integration')
    integ = integratepatch (plotstruct.datalist.faces, plotstruct.vertexlist, plotstruct.datalist.valuelist(:,1), plotstruct.datalist.valuelist(:,2), ...
                            startpoint - plotstruct.scandef.framevec, [endpoint-startpoint; 2 * plotstruct.scandef.framevec], [np,1] );
    sd  = integ{1};
    scandata.y = sd(:,1);  scandata.dy = sd(:,2);                   
end

if strcmpi(plotstruct.scandef.type,'Projection')
    % Find all points within the parallelogramm
    % Now cut along the two edges parallel to framevec:
    normal = [-plotstruct.scandef.framevec(2), plotstruct.scandef.framevec(1)]; normal = normal' ./ sqrt(normal*normal');
    C1 = startpoint * normal;
    C2 = endpoint   * normal;
    % Indizes of those points between the two edges
    between1 = (plotstruct.coordlist(:,1) * normal(1) + plotstruct.coordlist(:,2) * normal(2) < C1) == ...
               (plotstruct.coordlist(:,1) * normal(1) + plotstruct.coordlist(:,2) * normal(2) > C2);
    % Cut along the two edges parallel to the scan line:
    normal = endpoint-startpoint; normal = [-normal(2), normal(1)]; normal = normal' ./ sqrt(normal*normal');
    C1 = (startpoint + plotstruct.scandef.framevec) * normal;
    C2 = (startpoint - plotstruct.scandef.framevec) * normal;
    % Indizes of those points between the two edges
    between2 = (plotstruct.coordlist(:,1) * normal(1) + plotstruct.coordlist(:,2) * normal(2) < C1) == ...
               (plotstruct.coordlist(:,1) * normal(1) + plotstruct.coordlist(:,2) * normal(2) > C2);

    % These points make the scan
    scandata.y  = plotstruct.datalist.valuelist(between1 & between2, 1);
    scandata.dy = plotstruct.datalist.valuelist(between1 & between2, 2);     
    
    % Find the projection (along framevec) of these points on the scanline
    C = startpoint * normal;
    ind = find(between1 & between2);
    scanpath = zeros(0,2);
    for i=1:numel(ind)
        scanpath(i,:) = plotstruct.coordlist(ind(i),:) + (C - plotstruct.coordlist(ind(i),:)*normal)/(plotstruct.scandef.framevec*normal) * plotstruct.scandef.framevec;
    end    
end


%% Determine x-coordinate

% first, calculate HKL values
UB = UBmatrix( plotstruct.datalist.sampleinfo.lattice, plotstruct.datalist.sampleinfo.ax, plotstruct.datalist.sampleinfo.bx);
[H, K, L] = calcHKL( scanpath(:,1), scanpath(:,2), -plotstruct.datalist.QVERT, UB );  % ** '-'

% Now, x-coordinate depending on setting of scandef.xaxiscoord:
switch plotstruct.scandef.xaxiscoord
    case 'AUTO'
        [m,i] = max( max(scanpath,[],1) - min(scanpath,[],1)); %i is No. of column with largest variation; take this as x-axis
        xlabels=[];
        if isfield(plotstruct,'axesnames') && ~isempty(plotstruct.axesnames), 
            xlabels = plotstruct.axesnames;
            scandata.x = scanpath(:,i);  % ** Hier evtl gleich echte H,K, oder L ??
        elseif strcmpi(plotstruct.type, 'qxy'),  
            xlabels= {['Q_x (' char(197) '^{-1})'],['Q_y (' char(197) '^{-1})']};
            scandata.x = scanpath(:,i);
            if getoption('plotopt.preferHKL') % Do the plot in HKL coords instead Angstroms
                HKL = [H, K, L];
                [m,i] = max( max(HKL,[],1) - min(HKL,[],1)); %i is No. of column with largest variation; take this as x-axis
                xlabels= {'H (r.l.u)', 'K (r.l.u)', 'L (r.l.u)'};
                scandata.x = HKL(:,i);
            end
        elseif strcmpi(plotstruct.type, 'qeplane')
            xlabels={['|Q| (' char(197) '^{-1})'], 'Energy (meV)'}; 
            scandata.x = scanpath(:,i);
        elseif strcmpi(plotstruct.type, 'angles')
            xlabels={'Scattering angle (in plane)', 'Sample rotation angle'}; 
            scandata.x = scanpath(:,i);
        else
            scandata.x = scanpath(:,i);
        end
        if ~isempty(xlabels), xlabeltext = xlabels{i}; end
    case 'QMOD'
        xlabeltext = ['|Q| (' char(197) '^{-1})'];
        scandata.x = sqrt(scanpath(:,1).^2+scanpath(:,2).^2) .* sign(scanpath(:,1));        % ** Besser machen!
    case 'QX'
        xlabeltext = ['Q_x (' char(197) '^{-1})'];
        scandata.x = scanpath(:,1);
    case 'QY'
        xlabeltext = ['Q_y (' char(197) '^{-1})'];
        scandata.x = scanpath(:,2);
    case 'QH'
        xlabeltext = 'H (r.l.u)';
        scandata.x = H;
    case 'QK'
        xlabeltext = 'K (r.l.u)';
        scandata.x = K;
    case 'QL'
        xlabeltext = 'L (r.l.u)';
        scandata.x = L;
    case 'QM'
        xlabeltext = ['|Q| (' char(197) '^{-1})'];
        scandata.x = scanpath(:,1);
    case 'EN'
        xlabeltext = 'Energy (meV)';
        scandata.x = scanpath(:,2);
end

