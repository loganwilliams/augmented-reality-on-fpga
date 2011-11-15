function [Y] = filter_cols(X, B)
	Y = zeros(size(X));
	for c=1:size(X, 3)
		for j=1:size(X, 2)
			Y(:,j,c) = mirconv(X(:,j,c)', B)';
		end
	end
end
