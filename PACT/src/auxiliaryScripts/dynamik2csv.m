function dynamik2csv(dynamikFileString,outputFileName)
% note: dynamikFileString is assumed to be a .mat saved
% workspace file after running the DYNAMIK software.

    resultcell = parser_dynamik(dynamikFileString);
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
