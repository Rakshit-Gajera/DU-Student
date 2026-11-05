# usage: device_compare.py <out.png> <reference time> <capture.png> [more pairs]
# Puts the original screenshot next to the capture from the real phone.
import glob, sys
from PIL import Image
out = sys.argv[1]
args = sys.argv[2:]
pairs = [(args[i], args[i + 1]) for i in range(0, len(args), 2)]
W, H = 480, 1046
o = Image.new('RGB', (len(pairs) * (W * 2 + 20), H), 'magenta')
for n, (t, cap) in enumerate(pairs):
    ref = (glob.glob(f'test/goldens/reference/*{t}*') + glob.glob(f'../SS of DU/*{t}*'))[0]
    x = n * (W * 2 + 20)
    o.paste(Image.open(ref).convert('RGB').resize((W, H)), (x, 0))
    o.paste(Image.open(cap).convert('RGB').resize((W, H)), (x + W + 4, 0))
o.save(out)
