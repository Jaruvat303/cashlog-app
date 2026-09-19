# Cashlog UI Polish — Post-Redesign Fixes Spec

2026-09-19

## Problem Statement

หลังจาก redesign UI รอบแรกของ cashlog-app (Flutter client) เสร็จไปแล้ว ยังพบว่าหลายหน้าจอของแอปจริงยังไม่ตรงกับดีไซน์ที่ตั้งใจไว้ และมีข้อมูล/interaction บางส่วนหายไปหรืออยู่ผิดที่ ทำให้เกิดช่องว่างระหว่าง mockup กับแอปที่ใช้งานจริง โดยเฉพาะ:

- หน้าแรก: Banner ขาด label และข้อมูลบางอย่างที่ดีไซน์ไว้ (สแกนสลิปล่าสุด, ใช้จ่ายตามหมวดหมู่) และปุ่มเลือกเดือนอยู่ผิดตำแหน่ง
- หน้าเพิ่ม/แก้ไข Transaction: ตำแหน่งส่วน "ข้อมูลจากสลิป" และปุ่มบน Topbar ยังไม่ตรงกับดีไซน์ ดูสลิปแบบเต็มจอไม่ได้
- หน้าดูสรุป: มี Filter ที่ไม่จำเป็นบน Topbar, Account Card โชว์ข้อความ placeholder ที่ไม่มีประโยชน์แทนข้อมูลจริง, Pie chart เล็กเกินไปและ label ไม่ตรงดีไซน์
- หน้าบัญชี: Banner โชว์ข้อมูลหนี้สินที่ไม่มีจริงใน backend, List item มีข้อความ placeholder ที่ไม่ควรมี, หน้าเพิ่ม/แก้ไขบัญชียังไม่ได้ style ตามธีมใหม่
- หน้า Category: ตัวหนังสือใหญ่เกินไปจนตัดคำ, บาง category แสดงไอคอน fallback (ไฟล์) เพราะ frontend resolve icon_key จาก backend ไม่ครบ, หน้าเพิ่ม/แก้ไขยังไม่ได้ style ตามธีมใหม่

## Solution

แก้ไข UI/UX ของ 5 หน้าจอ (หน้าแรก, เพิ่ม/แก้ไข Transaction, ดูสรุป, บัญชี, Category) ให้ตรงกับ mockup ที่สรุปไว้ในเซสชัน grill-me (Sept 2026) โดยไม่แก้ backend schema หรือ architecture ใดๆ งานหลักคือ:

- จัดตำแหน่ง/ลบ element ที่ผิดที่ (ปุ่มเลือกเดือน, ข้อมูลจากสลิป, Filter, บรรทัดหนี้สิน)
- เติม label/ข้อมูลที่ดีไซน์ต้องการแต่แอปจริงยังไม่มี (ใช้จ่ายตามหมวดหมู่, สแกนสลิปล่าสุด)
- แทนที่ข้อความ placeholder ด้วยข้อมูลจริงที่มีอยู่แล้ว (`matching_keywords` ของบัญชี)
- แก้บัค icon resolver ที่ทำให้บาง category โชว์ไอคอน fallback
- ทำ visual consistency ให้หน้าเพิ่ม/แก้ไข บัญชี และ category ใช้ component style เดียวกับหน้าเพิ่ม/แก้ไข Transaction ที่เพิ่งปรับไปแล้ว

## User Stories

1. As a Cashlog user, I want the Home banner to show the current month without an interactive dropdown, so that month switching only happens in one place (ดูสรุป) and I don't get confused by two controls doing the same thing.
1. As a Cashlog user, I want the month switcher centered in the ดูสรุป page's Topbar, so that it reads clearly as the primary navigation control for that screen.
1. As a Cashlog user, I want the Home banner to show a "ใช้จ่ายตามหมวดหมู่" label above the category bar, so that I understand what the colored bar represents without guessing.
1. As a Cashlog user, I want the category bar and legend to show my top 8 spending categories for the month plus an "อื่นๆ" bucket for the rest, so that the summary stays informative even when I have many categories.
1. As a Cashlog user, I want the category legend to wrap onto multiple lines/rows, so that all 9 entries are readable on a phone-width banner.
1. As a Cashlog user, I want the Home banner to show the timestamp of my last successful auto-scanned slip, so that I know the auto-scan pipeline is working without opening the app's logs.
1. As a Cashlog user, I want that "last scan" info consolidated into the banner itself (not floating in a separate row below it), so that the banner is the single place I check my month's status.
1. As a Cashlog user, I want the "ข้อมูลจากสลิป" section moved to the bottom of the Add/Edit Transaction screen, so that the fields I edit most often (amount, category, account) are reachable first.
1. As a Cashlog user, I want to tap the slip thumbnail on the Edit Transaction screen and see it full-screen with pinch-to-zoom/pan, so that I can verify small print on the receipt.
1. As a Cashlog user, I want a close control on the full-screen slip viewer, so that I can dismiss it without losing my place in the edit form.
1. As a Cashlog user, I want the Add Transaction screen's Topbar to have no trailing action, so that I'm not shown a delete option for a transaction that doesn't exist yet.
1. As a Cashlog user, I want the Edit Transaction screen's Topbar to show a delete icon instead of an overflow ("...") menu, so that deleting a transaction is a single, direct tap.
1. As a Cashlog user, I want the ดูสรุป page's Topbar to have no filter icon, so that the header stays uncluttered since filtering already happens via the chip row below it.
1. As a Cashlog user, I want each Account Card on ดูสรุป to show the account's `matching_keywords` value in white text instead of the generic "ประมาณการจากรายการที่บันทึกไว้" placeholder, so that the card tells me something specific about that account.
1. As a Cashlog user, I want the pie chart on ดูสรุป to be visually larger, so that it's easier to read at a glance.
1. As a Cashlog user, I want percentage labels positioned around the pie chart's perimeter without leader lines, so that the chart looks clean and matches the mockup.
1. As a Cashlog user, I want the Accounts page banner to show only my total assets as one figure, so that I'm not shown a misleading "หนี้สิน" breakdown that the backend doesn't actually track as a separate entity.
1. As a Cashlog user, I want the placeholder estimate text removed from each account row in the Accounts list, so that the list looks intentional rather than showing debug/filler copy.
1. As a Cashlog user, I want the Add/Edit Account screen restyled to match the Add/Edit Transaction screen (icon+label+chevron rows, sticky bottom action button), so that the whole app feels visually consistent.
1. As a Cashlog user, I want category labels rendered in a smaller, thinner font that wraps to two lines, so that long category names don't get cut off or overflow their tile.
1. As a Cashlog user, I want every category to display its correct icon instead of a generic "file" fallback icon, so that I can recognize categories at a glance.
1. As a Cashlog user, I want the Add/Edit Category screen restyled to match the Add/Edit Transaction screen, so that creating or editing a category feels consistent with the rest of the app.

## Implementation Decisions

**หน้าแรก (Home)**
- ปุ่มเลือกเดือนบน Home banner ถูกถอดออก banner โชว์เดือนปัจจุบันแบบ static เท่านั้น การสลับเดือนทำได้จากหน้า ดูสรุป เท่านั้น (ปุ่มย้ายไปอยู่กลาง Topbar ของหน้านั้น)
- แถบ "ใช้จ่ายตามหมวดหมู่": เปลี่ยนจากหมวดคงที่เป็น dynamic — ดึง top 8 หมวดที่ใช้จ่ายมากสุดของเดือนนั้นจาก per-category breakdown ที่ CalculateSummary มีอยู่แล้ว ที่เหลือรวมเป็น "อื่นๆ" (รวมเป็น 9 segment)
- เพิ่ม header label "ใช้จ่ายตามหมวดหมู่" เหนือแถบสี (ปัจจุบันแอปจริงไม่มี)
- Legend ใช้ layout แบบ flex-wrap รองรับ 2 บรรทัดต่อรายการ (ใช้ font style เดียวกับที่ปรับในหน้า Category) และแถบสีบังคับ minimum-width ต่อ segment ป้องกัน segment บางเกินจนมองไม่เห็นสีเมื่อ % น้อย
- "สแกนสลิปล่าสุด": ย้ายจากตำแหน่งเดิม (แถวแยกใต้ banner) เข้ามารวมในตัว banner, ใช้ timestamp เดิมที่มีอยู่ (local-only last-successful-auto-scan) ไม่ต้องเพิ่ม logic ใหม่ และย่อ label ให้สั้นแบบ mockup

**เพิ่ม/แก้ไข Transaction**
- ส่วน "ข้อมูลจากสลิป" ย้ายไปอยู่ล่างสุดของฟอร์มในหน้าแก้ไข
- รูปสลิปแตะเพื่อเปิด full-screen photo viewer overlay (pinch-zoom/pan, ปุ่มปิด) ไม่ต้องแยก route ใหม่
- Topbar trailing action: โหมดเพิ่ม (create) → ไม่มีปุ่มขวา; โหมดแก้ไข (edit) → ปุ่มลบ (ไอคอนถังขยะ) แทนที่ปุ่ม overflow ("...")
- ปรับสี/spacing/component ของทั้งหน้าให้ตรงกับ mockup ที่แนบ (การ์ดจำนวนเงินด้านบน, chip แท็บ รายรับ/รายจ่าย/โอนเงิน, แถวฟิลด์แบบ icon+label+chevron, keypad ด้านล่าง)

**ดูสรุป (Summary)**
- เอาไอคอน Filter ออกจาก Topbar (ยืนยันตรงกับ mockup แล้ว — Topbar มีแค่ปุ่มเลื่อนเดือนซ้าย/ขวา + label เดือน กึ่งกลาง + ปุ่ม info)
- Account Card แต่ละใบ: แทนที่ subtitle text "ประมาณการจากรายการที่บันทึกไว้" ด้วยค่า field `matching_keywords` ของบัญชีนั้น (field มีอยู่แล้ว ไม่ต้องแก้ backend หรือสร้าง lookup table เพิ่ม) เปลี่ยนสีตัวอักษร subtitle เป็นสีขาว
- Pie chart: ขยายขนาดให้ใหญ่ขึ้น, เปลี่ยน label จาก legend list เป็น % ลอยรอบวงกลม (ไม่มีเส้นชี้ / leader line) ตามตำแหน่งมุมของแต่ละ segment

**บัญชี (Accounts)**
- Banner บนหน้า บัญชี: ตัดบรรทัด "สินทรัพย์ / หนี้สิน" แยกออก เหลือแค่ "สินทรัพย์รวมทั้งหมด" เป็นตัวเลขเดียว (เหตุผล: backend ไม่มี entity หนี้สินแยกเก็บอยู่แล้ว)
- เอาข้อความ "ประมาณการจากรายการที่บันทึกไว้" ออกจากแต่ละแถวใน Accounts list
- หน้า เพิ่ม/แก้ไข บัญชี: restyle ให้ใช้ component pattern เดียวกับหน้าเพิ่ม/แก้ไข Transaction (แถว icon+label+chevron, ปุ่ม action แบบ sticky ด้านล่าง) — ไม่มีการเปลี่ยน field หรือ logic ของฟอร์ม

**Category**
- ลด font-size และ font-weight ของ label หมวดหมู่ในหน้า grid, เปิด wrap รองรับ 2 บรรทัด (maxLines: 2, overflow แบบ ellipsis เมื่อเกิน)
- แก้บัค icon fallback: ตรวจสอบ icon resolver/picker list ของ frontend (จุดเดียวกับที่เคยแก้บัค income icon ก่อนหน้านี้) ว่าขาด mapping ให้ `icon_key` ค่าไหนของ backend บ้าง แล้วเพิ่มให้ครบ ไม่แก้ backend
- หน้า เพิ่ม/แก้ไข category: restyle ให้ใช้ component pattern เดียวกับหน้าเพิ่ม/แก้ไข Transaction เช่นเดียวกับหน้าบัญชี

## Testing Decisions

เทสที่ดีในงานนี้คือเทสที่ตรวจ external behavior/output ที่เห็นได้จริง (สิ่งที่ render, ค่าที่คำนวณออกมา) ไม่ใช่ตรวจ implementation detail ภายใน widget tree

- **Top-8-category aggregation logic** (pure function/usecase level): unit test ว่าเมื่อมี category มากกว่า 8 หมวด ฟังก์ชันคืนค่า top 8 ตาม amount ถูกต้อง และ "อื่นๆ" รวมยอดที่เหลือถูกต้อง; เมื่อมีน้อยกว่า 8 หมวด ไม่ควรมี "อื่นๆ" ที่เป็น 0 โผล่มา
- **Icon resolver mapping**: unit test ที่ loop ผ่านทุก `icon_key` ที่มีจริงใน category seed data (ทั้ง 30 ค่าตาม init_categories.sql) แล้วยืนยันว่า resolver คืนไอคอนที่กำหนดไว้เสมอ ไม่ตกไปที่ fallback icon — เป็น regression test กันบัคคลาสเดียวกับที่เคยเกิดกับ income icon
- **Topbar trailing action ต่อโหมด**: widget test ยืนยันว่าหน้า Add Transaction ไม่ render ปุ่มขวาบน Topbar และหน้า Edit Transaction render ปุ่มลบ (ไม่ใช่ปุ่ม overflow) เสมอ
- **Account Card subtitle**: widget test ยืนยันว่า subtitle ใช้ค่า `matching_keywords` ของ account ที่ส่งเข้ามา และสีตัวอักษรเป็นสีขาว
- **Category label wrap**: widget/golden test ยืนยันว่า label ยาวๆ wrap ได้ 2 บรรทัดโดยไม่ overflow และ label สั้นไม่เพี้ยน
- **Full-screen slip viewer**: manual/exploratory test บนอุปกรณ์จริง — แตะรูป, pinch-zoom, pan, ปิดด้วยปุ่ม X แล้วกลับมาที่ฟอร์มแก้ไขโดยข้อมูลที่กรอกไว้ไม่หาย (เพราะเป็น overlay ไม่ใช่ route ใหม่)

Prior art: ใช้ pattern เดียวกับ unit test ที่เขียนไว้ตอนแก้บัค `CalculateSummary` เทียบ "INCOME" ตัวใหญ่/เล็ก และ pattern widget test ที่ใช้ตอนแก้บัค icon resolver ของ income category ก่อนหน้านี้

## Out of Scope

- ไม่แก้ backend schema, API contract, หรือ DTO ใดๆ (`matching_keywords` ที่ใช้เป็น field ที่มีอยู่แล้ว)
- ไม่มีการสร้าง entity หรือฟีเจอร์หนี้สิน/liability ใหม่ — แค่ตัดการแสดงผลออกจาก banner
- ไม่แก้ business logic ของ transaction, category, หรือ account domain (เช่น dynamic balance computation, transaction type conversion)
- ไม่รวม redesign เต็มรูปแบบของหน้าอื่นที่ไม่ได้อยู่ใน 5 หน้าที่ระบุ (เช่น หน้า Settings, Login/Onboarding)
- ไม่รวมการเปลี่ยน backend rate limit, auth, หรือ deployment ใดๆ

## Further Notes

- สเปกนี้เป็นการปิดรอบ "polish" หลัง launch ของ Cashlog UI redesign (เซสชัน grill-me เดือนกันยายน 2026) ต่อจาก redesign หลักที่ใช้ธีมสี #FCF2E5 / #524646 / #EC5B38 ที่ตกลงกันไว้ก่อนหน้า
- ดีไซน์อ้างอิง: ไฟล์ mockup 2 ไฟล์ที่แนบมาในเซสชัน (Cashlog_Home_Redesign.pdf, Cashlog_Home_Redesign__1_.pdf) ครอบคลุมหน้า Home, ดูสรุป, เพิ่ม/แก้ไข Transaction (รายรับ/รายจ่าย/โอนเงิน), บัญชี (list + detail), Category (list + picker), และแก้ไขรายการแบบโอนเงิน
- งานบัค icon fallback ควรถือเป็น bug fix แยกจาก visual restyle แม้จะอยู่ในหน้า Category เดียวกัน เพราะ root cause เป็นเรื่อง data mapping ไม่ใช่ style
