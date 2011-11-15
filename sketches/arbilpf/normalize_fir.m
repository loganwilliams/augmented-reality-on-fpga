function [Bo] = normalize_fir(B)
	[H,W] = freqz(B,[1],2^10);
	max_amp = max(abs(H));
	Bo = B/max_amp;
end
