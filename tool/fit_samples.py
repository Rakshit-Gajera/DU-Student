import json
from PIL import Image
k=1272/918; q=1272/470
R='test/goldens/reference/Screenshot_20261105-%s_DU Student.png'
N='../SS of DU/Screenshot_20261105-%s_DU Student.png'
d=[ # name,text,file,box in 918-scale
('sectiontitle','Attendance','105730',(80,250,315,295)),
('sectiontitle2','Data Change Request','105730',(97,1565,532,1612)),
('mentor_sub','CSE | Assistant Professor | 00','105730',(218,1392,592,1425)),
('notimetable','No TimeTable','105730',(328,690,590,732)),
('dcr_total','Total Data Change Request :','105730',(73,1652,500,1690)),
('approved','Approved','105730',(103,1726,253,1762)),
('activity','Commencement of Next Semester','105730',(229,878,787,915)),
('header_sub','BTech+Hons-5B | Roll No. 424 | Batch 2','105730',(162,176,660,208)),
('mentor_name','Mr. Dharmik P Vasiyani','105730',(220,1348,658,1390)),
('semester','Semester','105730',(52,348,178,378)),
('appbar','Attendance Detail','105759',(147,138,545,190)),
('menu','Notifications','105740',(133,392,376,436)),
('att_date','09-Oct-26','105754',(60,890,207,925)),
('att_detail','Management System - II -','105759',(38,470,345,500)),
('course_head','Course','105759',(200,370,284,400)),
('lms_name','Computer Network','105814',(384,642,690,682)),
('lms_code','2301CS501','105814',(384,695,545,730)),
('unit_title','Unit 3 Greedy Algorithm','105818',(28,998,450,1042)),
('unit_sub','3 - Greedy Algorithm','105818',(28,1048,325,1085)),
('splash_ver','App Version :','105725',(325,1880,518,1915)),
]
n=[ # 470-scale box inside own image
('sem_wise','Sem Wise Result','115013',(150,258,320,287)),
('subject_row','Software Engineering','115013',(22,508,200,530)),
('grade_lbl','Exam Season','115013',(155,396,220,410)),
('cal_item','Term Registration','115105',(62,174,195,194)),
('dcr_title','I-Card Updation','115111',(16,170,180,196)),
('fb_title','2025-26 - Odd (Active) | Student | Subject','115133',(76,250,392,272)),
('griev_title','Water leakage in bus','115220',(16,338,232,364)),
('griev_sub','Transportation Service','115220',(16,367,190,387)),
('griev_desc','comfortable to sit, hence there\'s always a problem','115217',(20,410,445,432)),
('sheet_title','Select Delivery Mode','115330',(20,474,265,502)),
('sheet_item','In Person','115330',(12,650,90,674)),
('lmsr','DAA (2301CS402)','115150',(24,212,160,236)),
('empty','No Recent Circulars','115313',(135,568,335,596)),
('field','Select Purpose','115326',(22,212,152,236)),
]
out=[]
for nm,t,f,b in d: out.append(dict(name=nm,text=t,file=R%f,box=[int(v*k) for v in b]))
for nm,t,f,b in n: out.append(dict(name=nm,text=t,file=N%f,box=[int(v*q) for v in b]))
def ink(im):
    bg=im.getpixel((0,0)); px=im.load(); W,H=im.size
    best=0; D=[[0]*W for _ in range(H)]
    for y in range(H):
        for x in range(W):
            p=px[x,y]; v=sum(abs(p[i]-bg[i]) for i in range(3)); D[y][x]=v; best=max(best,v)
    xs=[x for x in range(W) for y in range(H) if D[y][x]>best*.35]; ys=[y for y in range(H) for x in range(W) if D[y][x]>best*.35]
    return (min(xs),min(ys),max(xs)+1,max(ys)+1),best
for s in out:
    im=Image.open(s['file']).convert('RGB').crop(s['box']); bb,b=ink(im); s['width']=(bb[2]-bb[0])/3
json.dump(out,open('test/goldens/out/fit_samples.json','w'))
print(len(out),[round(s['width']) for s in out])
