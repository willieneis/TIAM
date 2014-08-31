function imaris2csv(imarisCsvFileString,outputFileName,sizeConversionCoefficient)
% This function takes an imaris results file (in .csv format) and produces a 
%   csv file in the defined .csv format for PACT.
% note: imarisCsvFileString is assumed to be a .csv file (ie. a .xls imaris 
%   file converted into a csv using open office / excel [excel untested]),
%   and sizeConversionCoefficient is the micrometer/pixel conversion value
%   when Imaris was used.

    resultcell = parser_imaris(imarisCsvFileString);
    resultcell = convertUnitsToPixel(resultcell,sizeConversionCoefficient);
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
