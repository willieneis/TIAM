
function datacell = get_speed_new(datacell)


% this function includes separate speed features for each celltrack in datacell for the following time steps: 1, 4 (two steps forward vs two steps back), 8 (four steps forward vs 4 steps back), normalized displacment (last time step vs 1st time step), and displacement, in that order.



for cp = 1 : length(datacell)
	
	
	if size(datacell{cp}, 1) >= 9

		% if datacell{cp} is greater than or equal to 9 frames long
		
		% time step = 1
		for f = 2 : size(datacell{cp}, 1)
			dist = norm([datacell{cp}(f, 3), datacell{cp}(f, 4)] - [datacell{cp}(f-1, 3), datacell{cp}(f-1, 4)]);
			datacell{cp}(f, 9) = dist;
		end
		datacell{cp}(1, 9) = datacell{cp}(2, 9);
		
		% time step = 4
		for f = 3 : size(datacell{cp}, 1) - 2
			dist = norm([datacell{cp}(f-2, 3), datacell{cp}(f-2, 4)] - [datacell{cp}(f+2, 3), datacell{cp}(f+2, 4)]);
			datacell{cp}(f, 10) = dist / 4;
		end
		datacell{cp}(1:3, 10) = datacell{cp}(4, 10);
		datacell{cp}((size(datacell{cp}, 1) - 1) : size(datacell{cp}, 1), 10) = datacell{cp}((size(datacell{cp}, 1) - 2), 10);
		
		% time step = 8
		for f = 5 : size(datacell{cp}, 1) - 4
			dist = norm([datacell{cp}(f-4, 3), datacell{cp}(f-4, 4)] - [datacell{cp}(f+4, 3), datacell{cp}(f+4, 4)]);
			datacell{cp}(f, 11) = dist / 8;
		end
		datacell{cp}(1:5, 11) = datacell{cp}(6, 11);
		datacell{cp}((size(datacell{cp}, 1) - 3) : size(datacell{cp}, 1), 11) = datacell{cp}((size(datacell{cp}, 1) - 4), 11);
		
		% overall ("normalized displacement")
		end_f = size(datacell{cp}, 1);
		displacement = norm([datacell{cp}(1, 3), datacell{cp}(1, 4)] - [datacell{cp}(end_f, 3), datacell{cp}(end_f, 4)]);
		datacell{cp}(:, 12) = displacement / end_f;
		
		% displacement
		datacell{cp}(:, 13) = displacement;


	
	elseif size(datacell{cp}, 1) >= 5

		% if datacell{cp} is greater than or equal to 5 frames long and less than 9 frames long

		% time step = 1
		for f = 2 : size(datacell{cp}, 1)
			dist = norm([datacell{cp}(f, 3), datacell{cp}(f, 4)] - [datacell{cp}(f-1, 3), datacell{cp}(f-1, 4)]);
			datacell{cp}(f, 9) = dist;
		end
		datacell{cp}(1, 9) = datacell{cp}(2, 9);
		
		% time step = 4
		for f = 3 : size(datacell{cp}, 1) - 2
			dist = norm([datacell{cp}(f-2, 3), datacell{cp}(f-2, 4)] - [datacell{cp}(f+2, 3), datacell{cp}(f+2, 4)]);
			datacell{cp}(f, 10) = dist / 4;
		end
		datacell{cp}(1:3, 10) = datacell{cp}(4, 10);
		datacell{cp}((size(datacell{cp}, 1) - 1) : size(datacell{cp}, 1), 10) = datacell{cp}((size(datacell{cp}, 1) - 2), 10);
		
		% time step = 8
		datacell{cp}(:,11) = 0;
		% set equal to 0 if there aren't at least 8 steps
		
		% overall ("normalized displacement")
		end_f = size(datacell{cp}, 1);
		displacement = norm([datacell{cp}(1, 3), datacell{cp}(1, 4)] - [datacell{cp}(end_f, 3), datacell{cp}(end_f, 4)]);
		datacell{cp}(:, 12) = displacement / end_f;
		
		% displacement
		datacell{cp}(:, 13) = displacement;



	elseif size(datacell{cp}, 1) >= 2

		% if datacell{cp} is greater than or equal to 2 frames long and less than 5 frames long

		% time step = 1
		for f = 2 : size(datacell{cp}, 1)
			dist = norm([datacell{cp}(f, 3), datacell{cp}(f, 4)] - [datacell{cp}(f-1, 3), datacell{cp}(f-1, 4)]);
			datacell{cp}(f, 9) = dist;
		end
		datacell{cp}(1, 9) = datacell{cp}(2, 9);
		
		% time step = 4
		datacell{cp}(:,10) = 0;
		% set to 0 if there aren't at least 4 steps.
		
		% time step = 8
		datacell{cp}(:,11) = 0;
		% set to 0 if there aren't at least 8 steps
		
		% overall ("normalized displacement")
		end_f = size(datacell{cp}, 1);
		displacement = norm([datacell{cp}(1, 3), datacell{cp}(1, 4)] - [datacell{cp}(end_f, 3), datacell{cp}(end_f, 4)]);
		datacell{cp}(:, 12) = displacement / end_f;
		
		% displacement
		datacell{cp}(:, 13) = displacement;
		

	else 
		
		% this should only be the case if datacell{cp} is one frame long. set every speed field to 0.
		datacell{cp}(:,9) = 0;
		datacell{cp}(:,10) = 0;
		datacell{cp}(:,11) = 0;
		datacell{cp}(:,12) = 0;
		datacell{cp}(:,13) = 0;

	end
end
