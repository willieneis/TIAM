
function datacell = get_turnAngle(datacell, speedthresh);

% this function returns a datacell with the turnangle in column 15

% note: turn angle is currently signed, based on clockwise or counter-clockwise turn. Take absolute value to get absolute turn angle (before, for e.g., averaging over frames).

% note: haven't incorporated speedthresh in yet. the idea is to only consider turnangle for cells traveling a certain speed.



for cp = 1 : length(datacell)
	turnangle = [];
    turnangle(1) = 0;
	for f = 3 : size(datacell{cp},1)
        if not(isequal(datacell{cp}(f,3:4),datacell{cp}(f-1,3:4))) & not(isequal(datacell{cp}(f-1,3:4),datacell{cp}(f-2,3:4)))
            vector1 = datacell{cp}(f,3:4) - datacell{cp}(f-1,3:4);
            vector2 = datacell{cp}(f-1,3:4) - datacell{cp}(f-2,3:4);
            turnangle(f-1) = abs(acosd(dot(vector1, vector2) / (norm(vector1) * norm(vector2))));
            % find which direction cell turned
            [theta1,rho1] = cart2pol(vector1(1),vector1(2));
            [theta2,rho2] = cart2pol(vector2(1),vector2(2));
            newtheta = theta2 - theta1;
            [vec1,vec2] = pol2cart(newtheta,1);
            if vec2 < 0
                turnangle(f-1) = -1 * turnangle(f-1);
            end
        else
            turnangle(f-1) = 0;
        end
	end
	if length(datacell{cp}(:,15))>0
        turnangle(size(datacell{cp},1)) = 0;
		datacell{cp}(:,15) = turnangle;
	else
		datacell{cp}(:,15) = 0;
	end

    % check for NaN elements in datacell{cp}
    if length(find(isnan(datacell{cp}(:,15)))) > 0
        disp('WARNING: NaN elements produced by get_turnAngle function');
    end

end
