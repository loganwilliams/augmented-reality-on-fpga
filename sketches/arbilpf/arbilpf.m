function [Y] = arbilpf(X, Mx, My, O)
	Y = zeros(size(X));
	% the ripple and stopband specifications were chosen pretty arbitrarily
	% these should be chosen so as to optimize the transition width
	Bx = get_pm_lpf(Mx, O);
	By = get_pm_lpf(My, O);

	% debugging statements
	[Hx, Wx] = freqz(Bx, [1]);

	% note: the filters should be designed such that the square of their magnitudes
	% meets the specified requirements
	% the filtering mechanism that will be implemented will be an FPGA version
	% of filtfilt
	Y = filter_rows(filter_cols(X, By), Bx);
end
