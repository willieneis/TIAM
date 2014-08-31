function metric = pm_sfda(resultcell, gtcell, startframe, endframe, opt)

% resultcell contains a sequence of object-result-matrices (each matrix has position of objects for a sequence of frames)
% gtcell contains a sequence of gt-result-matrices (each matrix has a position of objects for a sequence of frames)

if nargin<5, opt = []; end

metric_vec = [];
objects_present_counter = 0;
for t = startframe : endframe
	rectmat1 = [];
	rectmat2 = [];
	for k = 1 : length(resultcell)
		if t >= resultcell{k}(1,1)  &&  t <= resultcell{k}(1,2)
			rectmat1 = [rectmat1; resultcell{k}(t-resultcell{k}(1,1)+1, 3:6)];
		end
	end
	for k = 1 : length(gtcell)
		if t >= gtcell{k}(1,1)  &&  t <= gtcell{k}(1,2)
			rectmat2 = [rectmat2; gtcell{k}(t-gtcell{k}(1,1)+1, 3:6)];
		end
	end
	if size(rectmat1, 1) > 0  &&  size(rectmat2, 1) > 0
		metric_vec(t) = pm_fda(rectmat1, rectmat2, opt);
		objects_present_counter = objects_present_counter + 1;
	else
		metric_vec(t) = 0;
	end
end
metric = sum(metric_vec) / objects_present_counter;
