
function randomColorSquaresDemo()

clear java
javaaddpath src
g = TcMatGui

jef = imread('bigimg.jpg');

% while(true)
% 	xstart = randi(size(jef,1)-50);
% 	xend = xstart+randi([20,40]);
% 	ystart = randi(size(jef,2)-50);
% 	yend = ystart + randi([20,40]);
% 	jef(xstart:xend, ystart:yend, randi(3)) = randi(255);
% 	j = im2java(jef);
% 	g.getUserResponse('Click Me!', 'No click me!', 'Click one of the buttons below!', j,1,1);
% end


size(jef)
% jef2 = repmat(jef, 2,2);
jef2 = jef;
size(jef2)
j = im2java(jef2);
g.getUserResponse('Click Me!', 'No click me!', 'Click one of the buttons below!', j,1,1);