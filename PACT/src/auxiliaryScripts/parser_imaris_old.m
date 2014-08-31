function resultcell = parser_imaris(csvString)
% note: csvString is assumed to be a .csv file (i.e. a .xls imaris 
% file converted into a csv using open office / excel [excel untested])

    % import data
    M = importdata(csvString);
    mat = M.textdata;
    mat2 = M.data;

    % remove weird imaris cellpath ID formatting
    mat2(:,2) = mat2(:,2) - 1000000000;

    % remove title text from mat
    mat = mat(2:end,:);

    % loop through each cellpath and add to resultcell
        % note: result cell matrices only contain: startframe,endframe, x pos, y pos
    finalPath = mat2(end,2)+1;  % this is finalPath, noting that the first path is 0-indexed
    for i = 1 : finalPath
        newmat = [];
        nextind = find(mat2(:,2) == i-1);	% the indices of cellpath i-1
        for j = 1 : length(nextind)
            newmat(j,1) = mat2(nextind(1),1);			% cellpath startframe
            newmat(j,2) = mat2(nextind(end),1);			% cellpath endframe
            newmat(j,3) = str2num(mat{nextind(j),1});	% x pos
            newmat(j,4) = str2num(mat{nextind(j),2});	% y pos
        end
        newmat(:,2) = newmat(1,1)+size(newmat,1)-1; % in case of inconsistencies
        resultcell{i} = newmat;	% add to resultcell
    end
