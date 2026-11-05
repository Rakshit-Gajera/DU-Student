import json
from PIL import Image
Image.MAX_IMAGE_PIXELS=None
import numpy as np
S=json.load(open('test/goldens/out/fit_samples.json')); M=json.load(open('test/goldens/out/fit_meta.json'))
F=np.asarray(Image.open('test/goldens/out/fit.png').convert('L'),float)
def norm(a):
    # a: greyscale diff from bg, scaled 0..1 cropped to ink
    a=a/max(a.max(),1); ys,xs=np.where(a>.35); return a[ys.min():ys.max()+1,xs.min():xs.max()+1]
res={}
for i,m in enumerate(M):
    res.setdefault(m['name'],[]).append((i,m))
for s in S:
    im=np.asarray(Image.open(s['file']).convert('RGB').crop(s['box']),float)
    bg=im[0,0]; r=norm(np.abs(im-bg).sum(2)); h,w=r.shape
    rows=[]
    for i,m in res[s['name']]:
        c=255-F[i*120:(i+1)*120,:]; c=norm(c)
        ci=np.asarray(Image.fromarray((c*255).astype('uint8')).resize((w,h),Image.BILINEAR),float)/255
        rows.append((float(((ci-r)**2).mean()),m['face']+('+fake' if m['fake'] else ''),round(m['size'],1),round(float(ci.mean()/r.mean()),2)))
    rows.sort()
    print(f"{s['name']:14}", ' | '.join(f"{a[1]} {a[2]} e{a[0]:.3f} ink{a[3]}" for a in rows[:3]))
