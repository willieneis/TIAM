function resultcell = parser_dynamik(dynamik_mat_file)
% given a saved dynamik workspace .mat file, parses results into resultcell

    % load TT mat into workspace
    load(dynamik_mat_file)

    for i=1:max(TT(:,2))
        cellmat = TT(find(TT(:,2)==i),:);
        resultcell{i}(:,3:6) = cellmat(:,6:9);
        resultcell{i}(:,1) = cellmat(1,1);
        resultcell{i}(:,2) = resultcell{i}(1,1)+size(resultcell{i},1)-1;
    end
