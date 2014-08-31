function datacell = get_polarity_default(datacell)

% this function returns a datacell with polarity in column 41
	% only to be used after get_outline has been called on datacell (filling columns 17-40 with DIC outline data)

for cp = 1 : size(datacell, 2)
	for pos = 1 : size(datacell{cp}, 1)
        eccentricity=1; % 0 for circle 1 for line
        circularity=0; % 1 for circle, 0 for line
        aspectRatio=0; % no axis (is a point); above 1 for deviations from circle
        
        datacell{cp}(pos,17) = eccentricity;
        datacell{cp}(pos,18) = circularity;
        datacell{cp}(pos,19) = aspectRatio;

    end
    
    % display information
	fprintf('polarity calculation complete for cell-track: %d/%d \n',cp,size(datacell,2));
    
end    
