function [B] = get_pm_lpf(M, O)
	B = firpm(O, [0 0.85/M 1.15/M 1], [1 1 0 0], [30 1]);
end
