# Spec: จัดระบบสีของ cashlog-app (Color System Cleanup)

สถานะ: ยืนยันแล้วจาก grill-me session (Oct 2026) พร้อมส่งต่อให้ AI อีกตัวลงมือทำ
ผู้ใช้แอป: Jar คนเดียว (single-user app)

---

## Problem Statement

ตอนนี้สีของแอปเยอะเกินไปและไม่สอดคล้องกัน มองจากมุมผู้ใช้และผู้พัฒนาได้ดังนี้

- **สีใน token มีประมาณ 45 ค่า** หลายค่าเทาเกือบเหมือนกัน (เส้นขอบ/พื้นผิว 9 ค่าที่แยกไม่ออกด้วยตา) และตัวอักษรมี 7 ค่าที่ชื่อสื่อความหมายสลับกัน (`textTertiary` เข้มกว่า `textSecondary`)
- **แบรนด์ไม่ชัด**: ปุ่มและ focus ring เป็นฟ้า แต่ FAB ใน theme ตั้งเป็นม่วง ขณะที่ FAB จริงเป็น gradient และการ์ด hero เป็น gradient ฟ้า→ม่วง ทำให้ฟ้าตรงมุมซ้ายบนของการ์ดได้ contrast กับตัวอักษรขาวแค่ 3.2:1
- **รายการที่ยังไม่ระบุหมวดหมู่ใช้สีเหลือง** (ไอคอนวงกลมขอบเหลือง + badge เหลือง) ซ้ำทุกแถว สีเดียวในแอปที่ไม่อยู่ในโทนม่วง และเด่นเกินความสำคัญจริง เพราะรายการเหล่านี้ไม่ใช่ error แค่ยังไม่จัดหมวด
- **ตัวเลขเงินอ่านยาก**: สีรายจ่าย (`F2784B`) และรายรับ (`22B573`) บนพื้นขาวได้เพียง 2.78:1 และ 2.65:1 ทั้งที่เป็นข้อมูลสำคัญที่สุดในแอป ตัวอักษรใน pill เทา (เช่น "ใช้จ่าย") ได้แค่ 2.85:1
- **มี abstraction ที่ไม่มีประโยชน์**: `FinanceColors` (ThemeExtension) เป็นแค่ห่อ `AppColors.income/expense` อีกชั้น ทั้งที่ไม่มีแผนทำ dark mode

## Solution

จัดระบบสีใหม่ให้เหลือชุดเล็กที่มีความหมายชัด (15 ค่า + ฟังก์ชัน `tint`) และปรับหน้าตาแอปให้ตรงกัน

- แบรนด์เป็น **ม่วงล้วน** (gradient ม่วงเข้ม→ม่วงอ่อนเล็กน้อย) ใช้ `primary` ตัวเดียวสำหรับปุ่ม, focus ring, FAB, แท็บ/ไอคอนที่ถูกเลือก ตัดฟ้าออก
- **ไม่มีสีเหลือง/warning** ในแอปอีกต่อไป ไม่มีการเตือนด้วยสี รายการไม่มีหมวดหมู่ยังใช้ไอคอน + เดิม แต่พื้นเป็นเทาอ่อน
- ตัวเลขรายรับ/รายจ่ายผ่านเกณฑ์ contrast สำหรับตัวอักษรหนา (3:1) และตัวอักษรเทาใน pill ผ่าน 4.5:1
- ลบ `FinanceColors` ให้ทุกหน้าอ่านสีจาก `AppColors` ตรงๆ
- สีของหมวดหมู่ (progress bar, donut, legend) **ไม่แตะ** ยังมาจาก backend เหมือนเดิม

## User Stories

1. As Jar, I want the whole app to read as one purple brand, so that the app feels intentional rather than a mix of blue, violet, and yellow
2. As Jar, I want the hero card on the home screen to use a purple-dominant gradient, so that the small white labels on it are easier to read
3. As Jar, I want the white text on the top-left of the hero card to be clearly legible, so that I can read "ค่าใช้จ่ายเดือนนี้" and the last-scan time without squinting
4. As Jar, I want the category legend labels on the hero card to be pure white (not semi-transparent), so that they stay legible against the lower-right of the gradient
5. As Jar, I want each colored dot in the hero legend to have a thin white outline, so that similar colors (two purples, grey, navy) are easier to tell apart on a purple background
6. As Jar, I want all categories still listed on the hero card as they are today, so that I don't lose information I rely on
7. As Jar, I want the primary buttons, input focus rings, and selected tab/icon in the bottom navigation to share the same purple, so that nothing looks like a slightly different shade of the same color
8. As Jar, I want the floating "+" button to match the brand gradient and its glow to be a softer purple tint, so that it doesn't look disconnected from the rest of the UI
9. As Jar, I want the selected "รายจ่าย/รายรับ/ย้ายเงิน" tab on the summary page to use the same brand gradient, so that selection looks the same everywhere
10. As Jar, I want the account cards on the summary page to use the same brand gradient as the hero card, so that gradients across the app look related
11. As Jar, I want transactions that have no category to look calm, so that a long list of them doesn't shout at me
12. As Jar, I want an uncategorized transaction's icon box to keep the "+" symbol, so that I still understand it means "add a category here"
13. As Jar, I want that icon box to have a soft grey background and no yellow, so that it matches the other category icon boxes
14. As Jar, I want the text "ยังไม่ระบุหมวดหมู่" to appear as plain grey text where a category name would normally be shown, so that I can see the state without an extra colored badge
15. As Jar, I want the "ใช้จ่าย" type pill to have readable dark-grey text on its grey pill, so that I can read it at a glance
16. As Jar, I want expense amounts to be a slightly deeper orange, so that the numbers are easier to read on white
17. As Jar, I want income amounts to be a slightly deeper green, so that the numbers are easier to read on white
18. As Jar, I want transfer amounts and icons to be a neutral slate color rather than the brand purple, so that moving money between accounts reads as neither income nor expense nor "brand"
19. As Jar, I want the light tinted backgrounds behind income/expense/transfer icons to be derived from the same base colors, so that icon boxes always match their amount colors
20. As Jar, I want secondary captions and hints to use a consistent grey, so that I can tell primary information from secondary information
21. As Jar, I want body-level secondary text (e.g. text on chips, neutral icons) to use a darker grey than hint text, so that it stays readable
22. As Jar, I want disabled/placeholder elements to use one consistent faint grey, so that disabled state is recognizable everywhere
23. As Jar, I want borders, dividers, and muted surfaces to come from a small consistent set, so that screens don't contain five nearly identical greys
24. As Jar, I want the bottom-sheet handle to use the standard border color instead of an ad-hoc grey, so that sheets match the rest of the app
25. As Jar, I want the category colors coming from the backend to keep working exactly as they do today, so that my existing categories don't change appearance or require a data migration
26. As Jar, I want the "!" icon on the summary page left as it is, so that nothing changes in a feature I haven't verified yet
27. As Jar, I want the floating "+" button's position and the bottom navigation layout unchanged, so that this color cleanup doesn't introduce layout changes
28. As the developer, I want a short, meaningfully named set of color tokens, so that I can pick the right color without comparing hex values
29. As the developer, I want a single `tint` helper for translucent versions of any color, so that I don't need a separate constant per translucent variant
30. As the developer, I want the old color names removed (not just deprecated) once migration is done, so that the compiler flags any leftover usage and no dead values stay behind
31. As the developer, I want the `FinanceColors` extension removed, so that there is only one way to read income/expense colors
32. As the developer, I want a test that locks in the minimum contrast of key foreground/background pairs, so that future color tweaks can't silently make text unreadable
33. As the developer, I want existing widget tests to keep passing without a themed app, so that the cleanup doesn't force me to rewrite test setups

## Implementation Decisions

### 1. Final token set (`AppColors`)

| กลุ่ม | Token | ค่า | หมายเหตุ |
|---|---|---|---|
| Surfaces | `background` | `F5F6FA` | เดิม |
| | `surface` | `FFFFFF` | เดิม |
| | `surfaceMuted` | `F1F2F7` | รวมจาก `tabTrackBg`, `pillChipBg`, `neutralSurface` |
| | `border` | `E5E7EB` | รวมจาก `border`, `inputBorder`, `chipUnselectedBorder` (ค่าเปลี่ยนเล็กน้อยจาก `ECEDF0`) |
| | `divider` | `F0F0F5` | เดิม |
| Text | `textPrimary` | `1A1D29` | เดิม |
| | `textBody` | `5B6172` | **ชื่อใหม่** ค่าเดิมของ `textTertiary`; 6.2:1 บนขาว |
| | `textMuted` | `8B90A0` | **ชื่อใหม่** ค่าเดิมของ `textSecondary`; ใช้กับ hint/caption เท่านั้น |
| | `textDisabled` | `C3C8D2` | **ชื่อใหม่** แทน `textFaint` |
| Brand | `primary` | `7656F6` | 4.7:1 กับตัวอักษรขาว |
| | `primaryLight` | `8B5CF6` | ปลายของ gradient |
| | `primaryGradient` | `primary` → `primaryLight` | topLeft → bottomRight |
| Semantic | `income` | `16A164` | 3.3:1 บนขาว |
| | `expense` | `E8622C` | 3.4:1 บนขาว |
| | `transfer` | `64748B` | 4.8:1 บนขาว |
| Helper | `tint(color, alpha = 0.12)` | — | คืนสีเดิมที่ปรับ alpha ใช้แทน `*Surface` ทุกตัว |

ใช้ `withValues` สำหรับ `tint` (ต้อง Flutter 3.27+) ถ้า SDK เก่ากว่านั้นให้ใช้ `withOpacity`

**ชื่อ token ตัวอักษรใหม่ทั้งหมดโดยตั้งใจ**: ค่าของ `textSecondary` (เดิม `8B90A0`) กับ `textBody` (`5B6172`) ถูกสลับบทบาทกัน จึงไม่ให้ชื่อเก่าและใหม่ชนกัน เพื่อไม่ให้โค้ดเดิมคอมไพล์ผ่านแล้วสีเปลี่ยนเงียบๆ

### 2. ตารางแปลงชื่อเดิม → ใหม่

| เดิม | ใหม่ |
|---|---|
| `accentA`, `primary` (เดิม) | `primary` |
| `accentB` | `primaryLight` (เมื่อเป็นส่วนของ gradient) / `primary` (เมื่อใช้เป็นสีเดี่ยว) |
| `accentGradient` | `primaryGradient` |
| `primarySurface` | `tint(primary)` |
| `primarySurfaceBorder` | `tint(primary, .3)` |
| `primaryText` | `primary` |
| `border`, `inputBorder`, `chipUnselectedBorder` | `border` |
| `tabTrackBg`, `pillChipBg`, `neutralSurface` | `surfaceMuted` |
| `chipUnselectedBg` | `surface` |
| `chipSelectedBg` | `textPrimary` |
| `textSecondary` (เดิม) | `textMuted` |
| `textTertiary`, `chipUnselectedText`, `neutralIcon` | `textBody` |
| `textFaint` | `textDisabled` |
| `incomeSurface` / `expenseSurface` / `transferSurface` | `tint(income)` / `tint(expense)` / `tint(transfer)` |
| `warningIcon`, `warningIconBg`, `warningBorder`, `warningBadgeBg`, `warningBadgeBorder`, `warningBadgeText` | **ลบทิ้ง** (ไม่ใช้สีเหลืองอีก) |
| สี hardcode ของ handle ใน `SheetHandle` | `border` |
| สีเงาของ `AppShadows.accent` | `tint(primary, .32)` |
| `FinanceColors` / `context.financeColors.income/expense` | `AppColors.income` / `AppColors.expense` |

เงาของการ์ดปกติ (`AppShadows.card`) ไม่เปลี่ยน

### 3. Theme

- `ColorScheme.fromSeed` ใช้ `primary` เป็นทั้ง seed และ primary
- ปุ่ม FilledButton, focus ring ของ input, FAB, snackbar ฯลฯ ที่เคยชี้ไป `accentA`/`accentB` ให้ชี้ `primary` (เช่น FAB ใน theme เปลี่ยนจากม่วง `accentB` เป็น `primary`)
- ลบ `FinanceColors` ออกจาก `extensions` ของ theme
- ไม่มี dark mode ใน spec นี้

### 4. การ์ด hero หน้าแรก

- พื้นหลังใช้ `primaryGradient`
- ตัวอักษรบนการ์ด (รวม legend) เป็นขาวเต็ม ไม่ใช้ขาวโปร่ง เพราะปลายล่างขวา (`primaryLight`) ได้ 4.2:1 กับตัวอักษรขาว
- จุดสีหมวดหมู่ใน legend มีขอบขาวบาง (ประมาณ 1.5px) เพื่อแยกสีที่ใกล้กัน
- **ยังแสดงทุกหมวดเหมือนเดิม** ไม่ตัดเหลือ 4 หมวด และไม่เปลี่ยนแถบ progress
- ถ้าลองแล้วรู้สึกว่า gradient อ่อนไป ทางเลือกสำรองคือเปลี่ยนปลายเป็น `7C3AED` (5.7:1) แต่ให้ตัดสินหลังเห็นของจริงบนเครื่อง ไม่ต้องเปลี่ยนล่วงหน้า

### 5. Transaction tile (รายการธุรกรรม)

- สีจำนวนเงิน: รายจ่าย `expense`, รายรับ `income`, ย้ายเงิน `transfer`
- พื้นหลังกล่องไอคอนหมวดหมู่ปกติ: `tint(<สีของ type>)` ตามเดิม
- **รายการที่ยังไม่ระบุหมวดหมู่**:
  - คงกล่องไอคอนเดิมไว้ (รูปทรงโค้ง มีสัญลักษณ์ **+**) เพราะ + สื่อว่า "เพิ่มหมวดหมู่ตรงนี้"
  - พื้นหลังกล่อง: `surfaceMuted` ไอคอน +: `textMuted`
  - ไม่มีสีเหลือง ไม่มี badge สีเหลือง
  - ขอบกล่อง: ถ้า + กดแล้วเปิดตัวเลือกหมวดหมู่ได้ทันที ให้ใส่ขอบบาง 1.5px สี `border` เพื่อบอกว่ากดได้ ถ้าต้องกดทั้งแถวเท่านั้น ไม่ต้องมีขอบ (ให้ผู้ลงมือตรวจจากพฤติกรรมในโค้ดปัจจุบัน)
  - ข้อความ "ยังไม่ระบุหมวดหมู่" แสดงเป็นข้อความเทาธรรมดา (ไม่ใช่ pill) ในตำแหน่งเดียวกับชื่อหมวดหมู่ของรายการปกติ สี `textMuted`
- pill ประเภท ("ใช้จ่าย", "รายรับ" ฯลฯ): พื้น `surfaceMuted` ตัวอักษรเปลี่ยนเป็น `textBody` (เดิม `textMuted` ได้ 2.85:1 → 5.5:1)

### 6. ปุ่ม FAB และแถบเมนูล่าง

- สีและ gradient เปลี่ยนตาม token ใหม่เท่านั้น (ไอคอนที่ถูกเลือกในเมนูล่างเปลี่ยนจากฟ้าเป็น `primary`)
- **ไม่เปลี่ยน layout/ตำแหน่ง/ขนาด** ของ FAB (แม้ FAB จะซ้อนทับรายการล่างสุด ผู้ใช้ยืนยันว่าไม่ใช่ปัญหา)

### 7. ไม่แตะในรอบนี้

- สีหมวดหมู่ (`color_hex` จาก backend) ทุกจุด: แถบ progress, donut, legend
- ไอคอน `!` บนหน้าสรุป (ผู้ใช้เชื่อว่าเป็นหน้ารายการที่ยังไม่ได้บันทึกลงฐานข้อมูล แต่ยังไม่ได้ยืนยัน)

### 8. กลยุทธ์ลงมือ (wide refactor → expand–contract)

การเปลี่ยนชื่อ/ลบ token กระทบหลายไฟล์ จึงเรียงเป็น 3 ช่วงใน branch เดียว
1. **Expand**: เพิ่ม token ใหม่ข้างของเก่า (ชื่อใหม่ไม่ชนกับชื่อเก่า ยกเว้น `primary`, `border`, `income`, `expense`, `transfer` ที่ใช้ชื่อเดิมแต่เปลี่ยนค่าโดยตั้งใจ) และย้าย theme ไปใช้ token ใหม่
2. **Migrate**: ย้ายการเรียกใช้เป็นชุดตามหน้า/กลุ่ม widget (ชื่อเก่ายังอยู่ ทุกชุดต้องผ่าน `dart analyze` และเทสต์)
3. **Contract**: ลบชื่อเก่าทั้งหมดและ `FinanceColors` ให้คอมไพเลอร์ฟ้องจุดที่ตกหล่น จากนั้นอัปเดต golden (ถ้ามี) ครั้งเดียวตอนท้าย

## Testing Decisions

- **หลักการ**: ทดสอบเฉพาะพฤติกรรมที่มองเห็นได้ (สี/ข้อความที่ผู้ใช้เห็น) ไม่ทดสอบรายละเอียดภายใน เช่น ชื่อ private field
- **Seam หลักที่เสนอ**: การทดสอบระดับ token ด้วย unit test ไฟล์เดียวที่ตรวจ contrast ratio ของคู่สีสำคัญ (นี่คือ "สัญญา" ของระบบสีใหม่ และเป็นจุดที่สูงที่สุดที่ครอบคลุมทุกหน้า)
  - `textBody` บน `surface` และบน `surfaceMuted` ≥ 4.5:1
  - ขาวบน `primary` ≥ 4.5:1 และขาวบน `primaryLight` ≥ 4.0:1
  - `income`, `expense` บน `surface` ≥ 3.0:1
  - `transfer` บน `surface` ≥ 4.5:1
- **Seam เสริม (เพียงจุดเดียวที่พฤติกรรม widget เปลี่ยน)**: widget test ของ transaction tile ที่ไม่มีหมวดหมู่ ตรวจว่ามีไอคอน +, มีข้อความ "ยังไม่ระบุหมวดหมู่" และไม่มีสีเหลืองจากชุด warning เดิม
- **Prior art**: โปรเจกต์มี widget test ที่ pump หน้าจอด้วย `MaterialApp()` เปล่า (ไม่มี `theme:`) การลบ `FinanceColors` ต้องไม่ทำให้เทสต์เหล่านั้นล้ม และไม่ควรต้องแก้ setup
- **Golden test**: ผมไม่ทราบว่าโปรเจกต์มีหรือไม่ ถ้ามีให้อัปเดตครั้งเดียวในขั้น contract และตรวจด้วยตาเทียบภาพก่อน/หลัง

## Out of Scope

- Dark mode (ไม่มีแผนตอนนี้ ถ้าทำในอนาคตให้ออกแบบใหม่ ไม่ต้องรักษา `FinanceColors` ไว้)
- การเปลี่ยนสีหมวดหมู่หรือ palette หมวดหมู่ที่ backend (สีมาจาก `color_hex` ของ backend และคงเดิม)
- การจำกัดจำนวนหมวดหมู่บนการ์ด hero (ผู้ใช้เลือกแสดงทุกหมวด)
- banner รวม "ยังไม่จัดหมวด N รายการ" บนหน้าแรก (ผู้ใช้เลือกไม่ใช้สีในการเตือน และไม่เพิ่ม UI ใหม่)
- การเปลี่ยนไอคอนหรือพฤติกรรมของไอคอน `!` บนหน้าสรุป
- Layout ของ FAB (การซ้อนทับเนื้อหา ไม่มี notch)
- ตัวเลือก gradient อิ่มกว่า (`7C3AED`) จนกว่าจะเห็นของจริงแล้วไม่พอใจ

## Further Notes

- ค่า contrast ทั้งหมดในเอกสารนี้คำนวณตามสูตร WCAG 2.x relative luminance ตัวเลขหลักๆ: `4F8EF7` เดิมกับขาว 3.21:1, `8B90A0` บนขาว 3.18:1 และบน `surfaceMuted` 2.85:1, `F2784B` 2.78:1, `22B573` 2.65:1
- `textMuted` (3.18:1 บนขาว) ใช้กับ hint/caption เท่านั้น ห้ามใช้กับข้อความสำคัญ
- สีของจุดใน legend และ progress bar ที่มาจาก backend อาจยังมีสองม่วงที่แยกยาก (เช่น "เลี้ยงดูบุตร/ครอบครัว" กับ "สตรีมมิ่งและความบันเทิง") แก้ได้ที่ seed data ใน backend ในอนาคต ไม่ใช่งานนี้
- บันทึกบริบท: จาก grill-me session นี้ ผู้ใช้ยืนยันว่า "ไม่แน่ใจเรื่องสี gradient" และมอบหมายให้ตัดสินจากภาพหน้าจอจริง จึงควรให้ผู้ใช้ดูผลบนเครื่องหลังขั้น Expand (หน้าแรกและหน้าสรุป) ก่อนย้ายต่อ
