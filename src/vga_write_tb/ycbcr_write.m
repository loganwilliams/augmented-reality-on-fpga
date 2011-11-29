img = rgb2ycbcr(imread('test.jpg'));
fid = fopen('ycbcr.data','w');
for i=1:size(img,1)
	for j=1:size(img,2)
		for k=1:size(img,3)
			fprintf(fid, '%d\n', img(i,j,k));
		end
	end
end
fclose(fid);
