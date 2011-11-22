f = open('sample_image.image', 'w')

for i in range(640*480):
    if i >= 2**18:
        f.write(str(i - 2**18));
    else:
        f.write(str(i))
        
    f.write('\n')
