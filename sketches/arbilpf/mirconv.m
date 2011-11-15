% must be row vectors
function [Y] = mirconv(X, H)
	l = size(H, 2);
	Xmir = horzcat(X((l+1):-1:2), X, X((end-1):-1:(end-l)));
	Ymir = conv(Xmir, H, 'same');
	Y = Ymir((1+l):(end-l));
end
