%% Set Camera Scale in physical distance by taking a picture of a tape measuerer

pt1=[130 248];
pt2=[127 193];
D=sqrt(((pt1(1)-pt2(1))^2)+((pt1(2)-pt2(2))^2));

pixels_per_mm = D/(10);