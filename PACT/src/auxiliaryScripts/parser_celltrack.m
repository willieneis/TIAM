function resultcell = parser_celltrack(celltrack_txt_file)
% this function parses a celltrack txt file and returns a resultcell

    file = fopen(celltrack_txt_file);
    nextline = fgetl(file);
    nextline = fgetl(file);
    nextline = fgetl(file);
    % loop through and construct resultcell
    i=1;
    while(nextline(1)=='#')
        tmp = [];
        isEnd = 0;
        nextline = fgetl(file);
        while(nextline(1)~='#' && isEnd==0)
            tmp = addLine(tmp,nextline);
            nextline = fgetl(file);
            if nextline==-1
                isEnd = 1;
            end
        end
        % add start- and end-frame
        tmp(:,1:2) = repmat([1,size(tmp,1)],size(tmp,1),1);
        resultcell{i} = tmp;
        if isEnd==1
            break;
        end
        i = i+1;
    end


    function mat = addLine(mat,newline)
    % returns updated mat given newline, info from the next frame
    % disp(strsplit(newline,' '))
    strSplitCell = strsplit(newline,' ');
    splitVec = strCell2Nums(strSplitCell);
    xpts = splitVec(1:2:end);
    ypts = splitVec(2:2:end);

    % change the following 4 lines later
    x1 = xpts(1);
    x_width = abs(x1-xpts(floor(length(xpts)/2)+1));
    y1 = ypts(1);
    y_width = abs(y1-ypts(floor(length(ypts)/2)+1));
    mat(end+1,3:6) = [x1,y1,x_width,y_width];


    function terms = strsplit(s, delimiter)
    % split a string %author @dahua lin
    assert(ischar(s) && ndims(s) == 2 && size(s,1) <= 1, ...
        'strsplit:invalidarg', ...
        'The first input argument should be a char string.');
    if nargin < 2
        by_space = true;
    else
        d = delimiter;
        assert(ischar(d) && ndims(d) == 2 && size(d,1) == 1 && ~isempty(d), ...
            'strsplit:invalidarg', ...
            'The delimiter should be a non-empty char string.');
        d = strtrim(d);
        by_space = isempty(d);
    end
    %% main
    s = strtrim(s);
    if by_space
        w = isspace(s);            
        if any(w)
            % decide the positions of terms        
            dw = diff(w);
            sp = [1, find(dw == -1) + 1];     % start positions of terms
            ep = [find(dw == 1), length(s)];  % end positions of terms
            % extract the terms        
            nt = numel(sp);
            terms = cell(1, nt);
            for i = 1 : nt
                terms{i} = s(sp(i):ep(i));
            end                
        else
            terms = {s};
        end
    else    
        p = strfind(s, d);
        if ~isempty(p)        
            % extract the terms        
            nt = numel(p) + 1;
            terms = cell(1, nt);
            sp = 1;
            dl = length(delimiter);
            for i = 1 : nt-1
                terms{i} = strtrim(s(sp:p(i)-1));
                sp = p(i) + dl;
            end         
            terms{nt} = strtrim(s(sp:end));
        else
            terms = {s};
        end        
    end

    function vec = strCell2Nums(strCell)
    % convert a cell of string-numbers (size 1xn) to a vector of numbers
    for i=1:length(strCell)
        vec(i) = str2num(strCell{i});
    end
