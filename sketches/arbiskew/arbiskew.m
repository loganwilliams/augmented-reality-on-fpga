% ARBISKEW
% project a rectangular image onto an arbitrarily shaped quadrilateral
% Logan Williams, 10/28/2011

% open the image to project
the_image = imread('IMG_5046.jpg', 'jpg');
the_image = im2double(the_image);

width = size(the_image,2);
height = size(the_image,1);

% projected quadrilateral co-ordinates
%   assumption: the quadrilateral is convex (or you get a weird result)
%   assumption: projected quadrilateral is smaller in
%       every dimension (or pixels are missing)
a_x = 1;
a_y = 100;
b_x = 50;
b_y = 30;
c_x = 200;
c_y = 1;
d_x = 200;
d_y = 200;

% the new image
projected_image = 0;

% initialize our iteration co-ordinates
main_loop_pos_x = a_x;
main_loop_pos_y = a_y;
sub_loop_pos_x = a_x;
sub_loop_pos_y = a_y;
int_x = 1;
int_y = 1;
destination_x = b_x;
destination_y = b_y;

theta_aprime = atan((a_x - d_x) / (a_y - d_y)); % angle of AD
% fix matlab's definition of atan
if (theta_aprime < 0)
    theta_aprime = theat_aprime + pi;
end

theta_bprime = atan((b_x - c_x) / (b_y - c_y)); % angle of BC
% fix matlab's definition of atan
if (theta_bprime < 0)
    theta_bprime = theta_bprime + pi;
end

% precalculate distances of two sides of projected quadrilateral
dist_ad = sqrt((a_x - d_x)^2 + (a_y - d_y)^2);
dist_bc = sqrt((b_x - c_x)^2 + (b_y - c_y)^2);

% iterate through every y pixel of the original image
while (int_y < height)
    % find the current distance between our point on AD and our destination
    %   point on BC (currently does not work, linear interpolation is not
    %   correct
    dist_cur = sqrt((main_loop_pos_x - destination_x)^2 + ...
        (main_loop_pos_y - destination_y)^2);
    
    % find the angle from our current point to the destination point. this
    % is the line that we will iterate along
    theta_cur = atan((destination_y - main_loop_pos_y) / ...
        (destination_x - main_loop_pos_x));
    
    % iterate through every x pixel of the original image
    while (int_x < width)
        % copy RGB data from original image to appropriate projected
        %   co-ordinate
        projected_image(int16(sub_loop_pos_y), int16(sub_loop_pos_x), 1) = ...
            the_image(int_y, int_x, 1);
        projected_image(int16(sub_loop_pos_y), int16(sub_loop_pos_x), 2) = ...
            the_image(int_y, int_x, 2);
        projected_image(int16(sub_loop_pos_y), int16(sub_loop_pos_x), 3) = ...
            the_image(int_y, int_x, 3);

        int_x = int_x + 1; %increment int_x
        
        % move our secondary iteration pixel at the appropriate angle, the
        % appropriate amount to reach our destination point on line CD when
        % int_x = width
        sub_loop_pos_x = sub_loop_pos_x + cos(theta_cur) * ((dist_cur) / (width));
        sub_loop_pos_y = sub_loop_pos_y + sin(theta_cur) * ((dist_cur) / (width));
    end
    
    % move our destination pixel along line BC
    destination_x = destination_x + sin(theta_bprime) * (dist_bc / height);
    destination_y = destination_y + cos(theta_bprime) * (dist_bc / height);

    int_x = 1; % reset int_x
    int_y = int_y + 1; % increment int_y
    
    % move our primary iteration pixel at the appropriate angle, the
    % appropriate amount to reach point D when int_y = height
    main_loop_pos_x = main_loop_pos_x + sin(theta_aprime) * (dist_ad / height);
    main_loop_pos_y = main_loop_pos_y + cos(theta_aprime) * (dist_ad / height);
    
    % reset our secondary iteration pixel to be the same as the primary
    sub_loop_pos_x = main_loop_pos_x;
    sub_loop_pos_y = main_loop_pos_y;
end

% show the result
imshow(projected_image);
