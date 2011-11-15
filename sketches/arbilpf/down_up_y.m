function [Y] = down_up_y(X, L)
	Y = zeros(size(X));
	for i=1:L:size(X,1)
		Y(i,:,:) = X(i,:,:);
	end
end
