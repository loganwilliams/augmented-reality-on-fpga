function [Y] = ycrcb2rgb_read;
	fid = fopen('rgb.data');
	sizes = size(imread('test.jpg'));
	tb_output = fscanf(fid, '%d');
	Y = zeros(sizes,'uint8');
	count = 1;
	for i=1:size(Y,1)
		for j=1:size(Y,2)
			for k=1:size(Y,3)
				if (count > size(tb_output))
					break;
				end
				Y(i,j,k) = tb_output(count);
				count = count+1;
			end
		end
	end
	fclose(fid);
end
