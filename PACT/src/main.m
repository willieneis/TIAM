function [SFDA,ATA] = main(gtFileString,trackFileString,sizeConvertCoef,varargin)
% This function returns the SFDA and ATA, for a given set of groundtruth
%   and tracking results.
% INPUTS:
%   (1) gtFileString: a string specifying the groundtruth tracks file.
%   (2) trackFileString: a string specifying the tracking results file.
% NOTE:
%   The groundtruth and tracking results files must be in one of the forms
%   specified in the PACT user guide.
% NOTE:
%   Numbered types for  gtFileType and resultFileType:
%   gtFileType: 1 - ViPER; 2 - .csv
%   resultFileType: 1 - TIAM; 2 - .csv

    % Deduce file types
    if length(strfind(trackFileString,'.mat')) > 0 
        resultFileType = 1;
    else
        resultFileType = 2;
    end
    if length(strfind(gtFileString,'.txt')) > 0 
        gtFileType = 1;
    else
        gtFileType = 2;
    end
    
    % Make gtcell
    if gtFileType==1
        gtcell = parseViperFile(gtFileString);
    else
        gtcell = parseCsv(gtFileString);
    end

    % Make resultcell
    if resultFileType==1
        load(trackFileString,'datacell');
        if nargin<3
            error(['When using TIAM results as an input file, you must include ', ...
            'the size-conversion coefficient as the third input argument']);
        end
        datacell = convertUnitsToPixel(datacell,sizeConvertCoef);
        resultcell = dc2rc(datacell);
    else
        resultcell = parseCsv(trackFileString);
    end

    % If either cell only has centroids, fix bboxes
    if size(gtcell{1},2)<6 || size(resultcell{1},2)<6
        gtcell = fixbbox(gtcell);
        resultcell = fixbbox(resultcell);
    end

    % Compute SFDA and ATA
    startframe = min([findStartFrame(resultcell),findStartFrame(gtcell)]);
    endframe = max([findEndFrame(resultcell),findEndFrame(gtcell)]);
    SFDA = pm_sfda(resultcell, gtcell, startframe, endframe); % compute sfda
    ATA = pm_ata(resultcell, gtcell); % compute ata
    fprintf('SFDA = %f\n',SFDA);
    fprintf('ATA = %f\n',ATA);

    % Aux functions
    function outcell = parseCsv(csvFileString)
        % Parse (standard) .csv input files
        csvmat = csvread(csvFileString);
        zeroind = find(sum(csvmat(:,2:end),2)==0); zeroind(end+1) = size(csvmat,1)+1;
        outcell = {};
        for i=2:length(zeroind)
            outcell{end+1} = csvmat(zeroind(i-1)+1:zeroind(i)-1,:); 
            startframe = outcell{end}(1,1); endframe = outcell{end}(end,1);
            outcell{end}(:,1) = [];
            outcell{end} = [repmat([startframe,endframe],size(outcell{end},1),1),outcell{end}];
        end
    end

    function groundcell = parseViperFile(viperFileString)
        % Parse ViPER ground-truth input file type
        if resultFileType>1
            groundcell = gt2gtcell(viperFileString);
        else
            groundcell = gt2gtcell(viperFileString); 
            groundcell = fixbbox(groundcell);
        end
    end

    function celly = shiftGtCell(celly,shiftAmount)
        % Shift a cell (in time / start and end frames)
        for cp = 1:length(celly)
            celly{cp}(:,1) = celly{cp}(:,1) + shiftAmount;
            celly{cp}(:,2) = celly{cp}(:,2) + shiftAmount;
        end
    end

    function startf = findStartFrame(thecell)
        % Find start frame (over all tracks in a cell)
        minframevec = [];
        for ind = 1:length(thecell)
            minframevec(end+1) = thecell{ind}(1,1);
        end
        startf = min(minframevec);
    end

    function endf = findEndFrame(acell)
        % Find end frame (over all tracks in a cell)
        maxframevec = [];
        for indy = 1:length(acell)
            maxframevec(end+1) = acell{indy}(1,2);
        end
        endf = max(maxframevec);
    end

    function rc = dc2rc(dc)
        % dc -> rc
        if size(dc{1},2) < 40
            for i = 1:length(dc)
                socell = cell(1,4); sorcell = {}; sorrcell = {}; bw = 25;
                rc{i} = dc{i}(:,1:4); rc{i}(:,3) = rc{i}(:,3) - (bw/2);
                rc{i}(:,4) = rc{i}(:,4) - (bw/2); rc{i}(:,5:6) = bw;
            end
        else
            for i = 1:length(dc)
                sFrame = dc{i}(1,1);
                eFrame = dc{i}(1,2);
                for fr = 1:size(dc{i},1)
                    xCoords = dc{i}(fr,17:28);
                    yCoords = dc{i}(fr,29:40);
                    bboxWidth = max(xCoords)-min(xCoords);
                    bboxLength = max(yCoords)-min(yCoords);
                    rc{i}(fr,:) = [sFrame,eFrame,min(xCoords),min(yCoords),bboxWidth,bboxLength];
                end
            end
        end
    end

    function newcell = fixbbox(oldcell)
        % Fix bbox at a specified width
        fixval = 25;
        for j=1:length(oldcell)
            newcell{j} = oldcell{j};
            if size(newcell{j},2)==6
                % replace bbox corner with centroid
                newcell{j}(:,3:4) = newcell{j}(:,3:4) + (newcell{j}(:,5:6)/2);
            end
            newcell{j}(:,3:4) = newcell{j}(:,3:4) - (fixval/2);
            newcell{j}(:,5:6) = fixval;
        end
    end
end
