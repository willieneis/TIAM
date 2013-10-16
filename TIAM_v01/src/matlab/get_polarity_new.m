
function datacell = get_polarity_new(datacell);

	% this function returns a datacell with polarity in column 41
	% only to be used after get_outline has been called on datacell (filling columns 17-40 with DIC outline data)


for cp = 1 : length(datacell)
	if size(datacell{cp},2)>= 40
		polarity = [];
		for f = 1 : size(datacell{cp}, 1)
			% polarity formula (function of outline in datacell columns 17:40)
			vec = datacell{cp}(f,17:40);
			% now vec is size [1,24], where x=vec(1:12), y=vec(13:24)
			% mat contains outline position per row. ie (row,:) = [xpos, ypos]
			mat(1:12,1) = vec(1:12);
			mat(1:12,2) = vec(13:24);

			diamvec = [ norm([mat(1,:)-mat(7,:)]), norm([mat(2,:)-mat(8,:)]), norm([mat(3,:)-mat(9,:)]), norm([mat(4,:)-mat(10,:)]), norm([mat(5,:)-mat(11,:)]), norm([mat(6,:)-mat(12,:)]) ];
			smalldiam = min(diamvec);
			largediam = max(diamvec);

			if smalldiam == 0 || largediam == 0
				polarity(f) = 1;
			else
				polarity(f) = 1 - (smalldiam/largediam);
			end
		end
		datacell{cp}(:,41) = polarity;
	else
		datacell{cp}(:,41) = 0;
	end
end