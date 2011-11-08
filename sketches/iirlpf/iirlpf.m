function [Y] = iirlpfimage(X, Mx, My)
	Y = zeros(size(X));
	% image dimensions, for easy reference
	M = size(Y, 1);
	N = size(Y, 2);
	C = size(Y, 3);
	% the ripple and stopband specifications were chosen pretty arbitrarily
	% these should be chosen so as to optimize the transition width
	[Bx, Ax] = ellip(2, 0.1, 30, 1/Mx);
	[Bx, Ax] = normalize_filter(Bx, Ax);
	[By, Ay] = ellip(2, 0.1, 30, 1/My);
	[By, Ay] = normalize_filter(By, Ay);

	% debugging statements
	[Hx, Wx] = freqz(Bx, Ax);
	plot(Wx, abs(Hx).^2);

	% note: the filters should be designed such that the square of their magnitudes
	% meets the specified requirements
	% the filtering mechanism that will be implemented will be an FPGA version
	% of filtfilt
	for c=1:C
		% filter in the Y direction and then flip the result
		for j=1:N
			Y(:,j,c) = filtfilt(By, Ay, X(:,j,c));
		end
		% repeat for X direction
		for i=1:M
			Y(i,:,c) = filtfilt(Bx, Ax, Y(i,:,c));
		end
	end
end

function [A1, A2] = split2order(A)
	r = roots(A/A(1));
	A1 = A(1)*[1 -r(1)];
	A2 = [1 -r(2)];
end

function [Bo, Ao] = normalize_filter(B, A)
	[H,W] = freqz(B,A,2^10);
	max_amp = max(abs(H));
	Bo = B/max_amp;
	Ao = A/max_amp;
end
