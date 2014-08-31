function resultcell2 = convertUnitsToPixel(resultcell,umPerPix)

% some results are given in micrometer units. this function converts the results to pixel units.
    % umPerPix is micrometers per pixel (the usual conversion listed in imageJ, I think)
    % note: umPerPix often 0.439 or 0.664

for cp = 1 : length(resultcell)
	mat = resultcell{cp};
	mat(:,3) = mat(:,3) * (1/umPerPix);
	mat(:,4) = mat(:,4) * (1/umPerPix);
	resultcell2{cp} = mat;
end
