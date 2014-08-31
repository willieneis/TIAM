function datacell = editTracks(datacell,breaksFileString,joinsFileString,arrestCoefThresh,arrestCoefDatacellColumn)

    % applies track breaks from file 'breaksFileString' and joins from
    %   file 'joinsFileString' to datacell and returns a datacell with 
    %   edited tracks.

    % some default input parameters
    if nargin<5, arrestCoefDatacellColumn = 11; end
    if nargin<4, arrestCoefThresh = 1.3; end

    todel = [];

    % make breaks
    breaks = dlmread(breaksFileString);
    breaksCell = cell(1,length(datacell));
    seCell = cell(1,length(datacell));
    for i=1:size(breaks,1)
        try
            ct = breaks(i,1);
            breakpts = breaks(i,find(breaks(i,:))); breakpts = breakpts(2:end);
            for j=1:length(breakpts)+1
                if j<=length(breakpts)
                    bf = breakpts(j)-datacell{ct}(1,1)+1;
                    ef = breakpts(j);
                else
                    bf = size(datacell{ct},1);
                    ef = datacell{ct}(1,2);
                end
                if j>1
                    bf_last = breakpts(j-1)-datacell{ct}(1,1)+1;
                    sf = breakpts(j-1)+1;
                else
                    bf_last = 0;
                    sf = datacell{ct}(1,1);
                end
                section = datacell{ct}(bf_last+1:bf,:);
                seSec = [sf,ef];
                if size(section,1)>0
                    breaksCell{ct}{j} = section;
                    seCell{ct}{j} = seSec;
                end
            end
            todel(end+1) = ct;
        catch
            error('ERROR==>error in input breaksFile, line %d.',i);
        end
    end
    
    % make joins
    joins = dlmread(joinsFileString);
    for i=1:size(joins,1)
        try
            joinpts = joins(i,find(joins(i,:)));
            cts = joinpts([1:2:end]);
            secs = joinpts([2:2:end]);
            mat = breaksCell{cts(1)}{secs(1)};
            for j=2:length(cts)
                mat = [mat; fillGap(breaksCell{cts(j-1)}{secs(j-1)}, seCell{cts(j-1)}{secs(j-1)}(2), breaksCell{cts(j)}{secs(j)}, seCell{cts(j)}{secs(j)}(1))];
                mat = [mat; breaksCell{cts(j)}{secs(j)}];
            end
            mat(:,1) = mat(1,1);
            mat(:,2) = mat(1,1)+size(mat,1)-1;
            datacell{end+1} = mat;
            for j=1:length(cts)
                breaksCell{cts(j)}{secs(j)} = [];
            end
        catch
            error('ERROR==>error in input joinsFile, line %d.',i);
        end
    end

    % added unjoined breaks to datacell
    for i=1:length(breaksCell)
        for j=1:length(breaksCell{i})
            if length(breaksCell{i}{j})>0
                mat = breaksCell{i}{j};
                mat(:,1) = seCell{i}{j}(1);
                mat(:,2) = seCell{i}{j}(2);
                datacell{end+1} = mat;
            end
        end
    end

    % delete old tracks
    fprintf('Number of celltracks modified: %d\n',length(todel));
    datacell(todel) = [];
        
    % RE-RUN: get_speed, arrest_coef, confinement_index, turn_angle, others?
    datacell = get_speed_new(datacell);
    datacell = get_arrestCoefficient(datacell,arrestCoefThresh,arrestCoefDatacellColumn);
    datacell = get_correctedConfinementIndex(datacell);
    datacell = get_turnAngle(datacell,0); % turnAngleCoefficient not incorporated into function yet. Set to 0 here.

    function gapmat = fillGap(cellmat1,endframe,cellmat2,startframe)
        gapwidth = startframe-endframe-1;
        if gapwidth<0
            error('ERROR: track-sections to join are inconsistent.');
        end
        if gapwidth>0
            xpos = linspace(cellmat1(end,3),cellmat2(1,3),gapwidth+2); xpos = xpos(2:end-1);
            ypos = linspace(cellmat1(end,4),cellmat2(1,4),gapwidth+2); ypos = ypos(2:end-1);
            gapmat = repmat(cellmat1(end,:),gapwidth,1);
            gapmat(:,3) = xpos;
            gapmat(:,4) = ypos;
        else
            gapmat = zeros(0,size(cellmat1,2)); 
        end
    end

end
