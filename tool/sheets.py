import sys
from PIL import Image
L=sys.argv[1:]
for i in range(0,len(L),2):
    o=Image.new('RGB',(1930,1046),'white')
    for j,n in enumerate(L[i:i+2]):
        im=Image.open(f'test/goldens/out/cmp_{n}.png').convert('RGB')
        o.paste(im.resize((im.width*1046//im.height,1046)),(j*970,0))
    o.save(f'test/goldens/out/cmp_two{i//2}.png')
