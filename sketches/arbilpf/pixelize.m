function [Y] = pixelize(X, M)
	Y = zeros(size(X));
	for k=1:size(Y,1)
		for l=1:size(Y,2)
			m = k-mod(k-1, M);
			n = l-mod(l-1, M);
			Y(k,l,:) = X(m, n, :);
		end
	end
end
