# writes ref|mine side by side; usage: compare.py <time fragment> <render name>
import sys,glob
from PIL import Image
g=glob.glob(f'test/goldens/reference/*{sys.argv[1]}*')+glob.glob(f'../SS of DU/*{sys.argv[1]}*')
ref=Image.open(g[0]).convert('RGB').resize((1272,2772))
me=Image.open(f'test/goldens/out/{sys.argv[2]}.png').convert('RGB')
o=Image.new('RGB',(ref.width*2+20,ref.height),'magenta');o.paste(ref,(0,0));o.paste(me,(ref.width+20,0))
o.resize((o.width*1500//o.height,1500)).save(f'test/goldens/out/cmp_{sys.argv[2]}.png')
