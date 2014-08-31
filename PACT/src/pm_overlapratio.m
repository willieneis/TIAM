function value = pm_overlapratio(rect1, rect2, opt)

% returns overlap ratio (Jaccard similarity) between rectangle rect1 and rectangle rect2

r_inter = rectint(rect1, rect2);
r_union = (rect1(3)*rect1(4))  +  (rect2(3)*rect2(4)) - r_inter;
value = r_inter / r_union;

% special options
if nargin<3, opt = []; end
if length(opt)==0
	value = value;
elseif length(opt)==1
    % option for upper threshold
	if value >= opt(1)
		value = 1;
	end	
elseif length(opt) == 2
    % option for upper and lower thresholds
	if value >= opt(2)
		value = 1;
	else
		value = 0;
	end
end
