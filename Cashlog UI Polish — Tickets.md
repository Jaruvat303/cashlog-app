# Cashlog UI Polish — Tickets

2026-09-19

ตี๋ชหน้า 6 ใบ จาก Cashlog UI Polish — Post-Redesign Fixes Spec เรียงตามที่ blocker เสร็จก่อน: `#1 → #2 → #3` และ `#4 → #5`, `#4 → #6` (สอง track ทำคู่ขนานกันได้)

### `01` — Category: แก้ตัวหนังสือ + บัค icon fallback

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > Category

**What to build**: หน้า Category (grid list) โชว์ label หมวดหมู่แบบเล็ก/บางลง wrap ได้ 2 บรรทัดโดยไม่ overflow และทุก category โชว์ไอคอนที่ถูกต้องตาม `icon_key` จาก backend ไม่มีไอคอน fallback (ไฟล์) หลงเหลืออีก

**Acceptance criteria**:
- [ ] Label หมวดหมู่ใน grid ใช้ font-size/weight เล็ก/บางลงตามที่ตกลง
- [ ] Label ที่ยาวเกิน 1 บรรทัด wrap เป็น 2 บรรทัดได้ (maxLines: 2, ellipsis เมื่อเกิน) โดยไม่ตัดคำเพี้ยนหรือ overflow ออกนอกกรอบ
- [ ] icon resolver/picker list ของ frontend ครอบคลุมทุก `icon_key` ที่มีจริงในข้อมูล category ปัจจุบัน ไม่มี category ใดแสดงไอคอน fallback
- [ ] มี unit test loop ผ่านทุก `icon_key` ใน category seed data ยืนยันว่า resolver คืนไอคอนที่กำหนดเสมอ (regression test กันบัคคลาสเดียวกับ income icon ที่เคยเกิด)

**Blocked by**: None — เริ่มได้เลย

### `02` — Home: ย้าย month control + เติมข้อมูลที่หายไป

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > หน้าแรก (Home)

**What to build**: Home banner โชว์เดือนปัจจุบันแบบ static (ไม่มี dropdown), การสลับเดือนทำได้จากปุ่มใหม่ที่อยู่กึ่งกลาง Topbar ของหน้า ดูสรุป เท่านั้น และใช้งานสลับเดือนได้จริงจากจุดนั้น; แถบ "ใช้จ่ายตามหมวดหมู่" เปลี่ยนเป็น dynamic top-8 หมวด + "อื่นๆ" พร้อม header label ที่หายไปก่อนหน้านี้ และใช้ font style เดียวกับ label ที่ปรับใน #01; banner โชว์ timestamp "สแกนสลิปล่าสุด" รวมอยู่ในตัว banner (ย้ายจากแถวแยกเดิม)

**Acceptance criteria**:
- [ ] Home banner ไม่มี dropdown เลือกเดือนอีกต่อไป โชว์เดือนปัจจุบันแบบอ่านอย่างเดียว
- [ ] หน้า ดูสรุป มีปุ่มเลือกเดือนอยู่กึ่งกลาง Topbar และกดสลับเดือนได้จริง (ข้อมูลในหน้าเปลี่ยนตามเดือนที่เลือก)
- [ ] แถบสี "ใช้จ่ายตามหมวดหมู่" มี header label กำกับอยู่เหนือแถบ
- [ ] แถบสีและ legend แสดง top 8 หมวดที่ใช้จ่ายมากสุดของเดือนนั้น + segment "อื่นๆ" รวมยอดที่เหลือ ถูกต้องตามข้อมูลจริง
- [ ] Legend label ใช้ font-size/weight และการ wrap 2 บรรทัดแบบเดียวกับที่ปรับในหน้า Category (#01)
- [ ] แถบสีมี minimum-width ต่อ segment ไม่บางจนมองไม่เห็นสีเมื่อ % น้อย
- [ ] Banner โชว์ "สแกนสลิปล่าสุด: <เวลาที่สแกนล่าสุด>" โดยใช้ timestamp local-only ที่มีอยู่แล้ว (ไม่ต้องเพิ่ม logic ใหม่)

**Blocked by**: `01` — Category: แก้ตัวหนังสือ + บัค icon fallback

### `03` — ดูสรุป: ส่วนที่เหลือของหน้า

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > ดูสรุป (Summary)

**What to build**: Topbar ของหน้า ดูสรุป ไม่มีไอคอน Filter อีกต่อไป; Account Card แต่ละใบโชว์ค่า `matching_keywords` ของบัญชีนั้นแทนข้อความ placeholder เดิม ด้วยสีตัวอักษรขาว; Pie chart แสดงใหญ่ขึ้นพร้อม % ลอยรอบวงกลมไม่มีเส้นชี้

**Acceptance criteria**:
- [ ] Topbar หน้า ดูสรุป ไม่มีไอคอน Filter (คงไว้แค่ปุ่มเลื่อนเดือน + label เดือนกึ่งกลาง + ปุ่ม info ตามที่ #02 วางไว้)
- [ ] Account Card ทุกใบโชว์ค่า `matching_keywords` ของบัญชีนั้นเป็น subtitle แทน "ประมาณการจากรายการที่บันทึกไว้"
- [ ] สีตัวอักษร subtitle ของ Account Card เป็นสีขาว
- [ ] Pie chart ขนาดใหญ่ขึ้นกว่าเดิมอย่างเห็นได้ชัด
- [ ] Label % วางลอยรอบวงกลมตามมุมของแต่ละ segment โดยไม่มีเส้นชี้ (leader line)

**Blocked by**: `02` — Home: ย้าย month control + เติมข้อมูลที่หายไป (แก้ Topbar เดียวกันต่อจากที่ #02 วาง month switcher ไว้ กันชนกันตอนแก้)

### `04` — เพิ่ม/แก้ไข Transaction: reposition + restyle

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > เพิ่ม/แก้ไข Transaction

**What to build**: หน้าแก้ไขรายการย้ายส่วน "ข้อมูลจากสลิป" ไปอยู่ล่างสุดของฟอร์ม, แตะรูปสลิปเปิด full-screen photo viewer (pinch-zoom/pan + ปุ่มปิด) ได้, Topbar สลับ trailing action ตามโหมด (เพิ่ม = ไม่มีปุ่มขวา, แก้ไข = ปุ่มลบแทนปุ่ม overflow "..."), และทั้งหน้าปรับสี/spacing/component ให้ตรงกับ mockup ที่แนบในสเปก ตั๋วนี้เป็นตัวตั้ง component pattern (แถว icon+label+chevron, ปุ่ม action แบบ sticky ด้านล่าง) ที่ #05 และ #06 จะเอาไปใช้ต่อ

**Acceptance criteria**:
- [ ] หน้าแก้ไขรายการ: ส่วน "ข้อมูลจากสลิป" อยู่ล่างสุดของฟอร์มเสมอ
- [ ] แตะรูปสลิป (หรือ placeholder "แตะเพื่อดูสลิป") เปิด overlay เต็มจอ, pinch-to-zoom และ pan ได้, มีปุ่มปิดกลับสู่ฟอร์มเดิมโดยข้อมูลที่กรอกไว้ไม่หาย
- [ ] หน้าเพิ่มรายการ (create): Topbar ไม่มีปุ่มขวา
- [ ] หน้าแก้ไขรายการ (edit): Topbar โชว์ปุ่มลบ (ไอคอนถังขยะ) แทนปุ่ม overflow "..."
- [ ] มี widget test ยืนยัน Topbar trailing action ถูกต้องตามโหมด (create ไม่มีปุ่ม / edit มีปุ่มลบ)
- [ ] สี, spacing, และ component ของทั้งหน้า (การ์ดจำนวนเงิน, chip แท็บ รายรับ/รายจ่าย/โอนเงิน, แถวฟิลด์ icon+label+chevron, keypad) ตรงกับ mockup ที่แนบในสเปก

**Blocked by**: None — เริ่มได้เลย (ทำคู่ขนานกับ `01` ได้)

### `05` — บัญชี: banner + list + restyle ฟอร์ม

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > บัญชี (Accounts)

**What to build**: Banner หน้าบัญชีโชว์แค่ "สินทรัพย์รวมทั้งหมด" เป็นตัวเลขเดียว (ตัดบรรทัดสินทรัพย์/หนี้สินแยกออก), แต่ละแถวใน Accounts list ไม่มีข้อความ placeholder "ประมาณการจากรายการที่บันทึกไว้" แล้ว, และหน้าเพิ่ม/แก้ไขบัญชี restyle ให้ใช้ component pattern เดียวกับหน้า Transaction (#04)

**Acceptance criteria**:
- [ ] Banner หน้าบัญชีโชว์ยอดสินทรัพย์รวมเป็นตัวเลขเดียว ไม่มีบรรทัดแยก "สินทรัพย์" / "หนี้สิน" อีก
- [ ] แต่ละแถวใน Accounts list ไม่มีข้อความ "ประมาณการจากรายการที่บันทึกไว้" หลงเหลือ
- [ ] หน้าเพิ่ม/แก้ไขบัญชีใช้แถว icon+label+chevron และปุ่ม action แบบ sticky ด้านล่าง เหมือนหน้า Transaction ที่ #04 วางไว้
- [ ] ฟิลด์และ logic เดิมของฟอร์มเพิ่ม/แก้ไขบัญชี (ชื่อบัญชี, ประเภท/ไอคอน, ยอดเริ่มต้น ฯลฯ) ยังทำงานถูกต้องเหมือนเดิม ไม่มีการเปลี่ยน behavior

**Blocked by**: `04` — เพิ่ม/แก้ไข Transaction: reposition + restyle (ต้องมี component pattern จากตั๋วนี้ก่อนถึงเอามา restyle ฟอร์มบัญชีได้)

### `06` — Category: restyle ฟอร์มเพิ่ม/แก้ไข

**Parent**: Cashlog UI Polish — Post-Redesign Fixes Spec, ส่วน Implementation Decisions > Category

**What to build**: หน้าเพิ่ม/แก้ไข category restyle ให้ใช้ component pattern เดียวกับหน้า Transaction (#04) — ปิดจบทุก requirement ของหน้า Category ร่วมกับ #01

**Acceptance criteria**:
- [ ] หน้าเพิ่ม/แก้ไข category ใช้แถว icon+label+chevron และปุ่ม action แบบ sticky ด้านล่าง เหมือนหน้า Transaction ที่ #04 วางไว้
- [ ] ฟิลด์และ logic เดิมของฟอร์มเพิ่ม/แก้ไข category (ชื่อ, ไอคอน, สี, ประเภทรายรับ/รายจ่าย ฯลฯ) ยังทำงานถูกต้องเหมือนเดิม ไม่มีการเปลี่ยน behavior

**Blocked by**: `04` — เพิ่ม/แก้ไข Transaction: reposition + restyle
