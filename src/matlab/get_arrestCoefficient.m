
function datacell = get_arrestCoefficient(datacell, thresh, datacellcolumn)

% this function returns a datacell with the arrest coefficient in column 14


% note: arrest coefficient threshold was, in the past, fixed at 0.3 (roughly 20% value of all speeds of attached cells)
% (this is 0.3 speed before any conversion i think)
% thresh = 0.3;




for cp = 1 : length(datacell)
	pathlength = size(datacell{cp}, 1);
	arrestcount = 0;
	for f = 1 : size(datacell{cp}, 1)
		if datacell{cp}(f, datacellcolumn) < thresh
			arrestcount = arrestcount + 1;
		end
	end
	datacell{cp}(:, 14) = arrestcount/pathlength;
end


