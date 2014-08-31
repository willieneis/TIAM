function celltrack2csv(celltrackFileString,outputFileName)
% note: celltrackFileString is assumed to be an output file 
% exported from the CellTrack software.

    resultcell = parser_celltrack(celltrackFileString);
    cell2csv(resultcell);

    function cell2csv(acell)
        % write csv from a cell array, acell
        mat = [];
        for i=1:length(acell)
            mat = [mat; i 0 0];
            newmat = acell{i}(:,3:end);
            firstcol = [acell{i}(1,1):acell{i}(1,2)]';
            newmat = [firstcol,newmat];
            mat = [mat; newmat];
        end
        csvwrite([outputFileName, '.csv'],mat);
    end

end
