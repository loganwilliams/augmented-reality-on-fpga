function [Y] = filter_rows(X, B)
	Y = zeros(size(X));
	for c=1:size(X, 3)
		for i=1:size(X, 1)
			Y(i,:,c) = mirconv(X(i,:,c), B);
		end
	end
end
