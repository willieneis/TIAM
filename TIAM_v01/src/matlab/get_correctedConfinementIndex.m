
function datacell = get_correctedConfinementIndex(datacell);

% this function returns a datacell with the corrected confinement index in column 16


for cp = 1 : length(datacell)
	if size(datacell{cp},1) > 1
		totallength = 0;
		cci = 0;
		for f = 2 : size(datacell{cp},1)
			totallength = totallength + norm(datacell{cp}(f,3:4)-datacell{cp}(f-1,3:4));
		end
		displacement = norm(datacell{cp}(end,3:4)-datacell{cp}(1,3:4));
		cci = (displacement/totallength) * sqrt(size(datacell{cp},1));
		datacell{cp}(:,16) = cci;
	else
		datacell{cp}(:,16) = 0;
	end
end