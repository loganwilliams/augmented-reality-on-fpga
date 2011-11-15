function [Y] = down_up_x(X, L)
	Y = zeros(size(X));
	for j=1:L:size(X,2)
		Y(:,j,:) = X(:,j,:);
	end
end
