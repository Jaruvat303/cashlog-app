# Tickets: จัดระบบสีของ cashlog-app

ตั๋ว 6 ใบสำหรับลงมือตาม `cashlog-color-system-spec.md` (Parent ของทุกตั๋ว) ทำเป็น wide refactor แบบ expand–contract ใน branch เดียว: 01 = expand, 02–05 = migrate เป็นชุดตามหน้า, 06 = contract

ทำตาม **frontier**: ตั๋วที่ blocker ทั้งหมดเสร็จแล้วจึงเริ่มได้ ตั๋ว 02–05 ไม่พึ่งกันเอง ทำสลับลำดับได้ ทุกตั๋วต้องจบด้วย `dart analyze` และเทสต์ที่มีอยู่ผ่านทั้งหมด และควรเคลียร์ context ระหว่างตั๋วถ้าทำได้

ข้อควรรู้สำหรับผู้ลงมือ: อย่าเปลี่ยน layout ของ FAB/เมนูล่าง, อย่าแตะสีหมวดหมู่ที่มาจาก backend และอย่าแตะไอคอน `!` บนหน้าสรุป (ดู Out of Scope ใน spec)

---

### `01` — วางรากระบบสีใหม่ (Expand)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: ระบบสีชุดใหม่พร้อมใช้งานข้างของเก่า แอปรันได้เหมือนเดิม และปุ่ม/FAB/focus ring เปลี่ยนเป็นม่วงแล้ว ชื่อ token เก่ายังอยู่ครบจนกว่าจะถึงตั๋ว 06 ผู้ใช้เห็นว่าสีหลักของแอปเป็นม่วงทั้งปุ่มหลัก, FAB และช่องกรอกที่โฟกัส

**Acceptance criteria**:
- [x] `AppColors` มี token ใหม่ครบตามตารางใน spec: `surfaceMuted`, `textBody`, `textMuted`, `textDisabled`, `primary` (`7656F6`), `primaryLight`, `primaryGradient`, และฟังก์ชัน `tint`
- [x] token ที่ใช้ชื่อเดิมแต่ค่าเปลี่ยนโดยตั้งใจได้ค่าใหม่แล้ว: `primary`, `border`, `income`, `expense`, `transfer`
- [x] ชื่อเก่าคงอยู่ระหว่างช่วง migrate และถูกลบเมื่อจบ contract ในตั๋ว 06
- [x] theme ใช้ token ใหม่: `ColorScheme` seed/primary เป็น `primary`, ปุ่ม FilledButton, focus ring ของ input, FAB และ snackbar ชี้ไป `primary`
- [x] ทำ "รายการสำรวจ" ว่าไฟล์/widget ไหนเรียก token เก่าตัวไหน (รวมสี `Color(0xFF...)` ที่ hardcode) และแนบไว้ในบันทึกของตั๋ว 02–05 ว่าแต่ละตั๋วต้องแก้อะไร ถ้ามีไฟล์ที่ไม่ตรงกับการแบ่งใน 02–05 ให้ระบุว่าควรไปอยู่ตั๋วไหน
- [x] ตรวจว่าโปรเจกต์มี golden test หรือไม่ และบันทึกผลไว้สำหรับตั๋ว 06
- [x] ตรวจว่า + ในกล่องไอคอนของรายการไม่มีหมวดหมู่กดแล้วเปิดตัวเลือกหมวดหมู่ได้ทันทีหรือไม่ และบันทึกผลไว้สำหรับตั๋ว 03
- [x] unit test ใหม่หนึ่งไฟล์ตรวจ contrast ratio: `textBody` บน `surface` และ `surfaceMuted` ≥ 4.5:1, ขาวบน `primary` ≥ 4.5:1, ขาวบน `primaryLight` ≥ 4.0:1, `income` และ `expense` บน `surface` ≥ 3.0:1, `transfer` บน `surface` ≥ 4.5:1
- [x] `dart analyze` และเทสต์ที่มีอยู่ผ่าน (รวมเทสต์ที่ pump ด้วย `MaterialApp()` เปล่า)

**Audit notes (01)**:
- Golden tests: ไม่พบใน `test/` หรือ `integration_test/`
- กล่อง + ใน `TransactionListTile` เป็น `CategoryQuickAssignChip` ซึ่งกดแล้วเรียก `showCategoryGridPicker` ทันที จึงคงเส้นขอบ `border` 1.5px
- ตั๋ว 02: `ExpenseTotalWidget`/`GradientHeroCard` และ `AppShell` — เปลี่ยน gradient, ข้อความ/จุด legend และสีเมนูล่าง
- ตั๋ว 03: `transaction_list_tile.dart` และ `category_quick_assign_sheet.dart` — เปลี่ยนสี semantic, พื้น/ขอบกล่อง + และข้อความรายการไม่มีหมวดหมู่
- ตั๋ว 04: `transactions_page.dart` (แท็บสรุปรายเดือน/การ์ดบัญชี), `trend_page.dart` (สรุปรายปี), `trend_line_chart.dart` และ chart — ย้ายโทนสีโดยคงสีหมวดหมู่ backend และไอคอน `!`
- ตั๋ว 05: `transaction_form_fields.dart`, form pages, account/category pages และ `shared/widgets/` — ย้าย token สำหรับ form, chip, sheet, buttons และ shared controls; `pending_actions_banner.dart` กับ gallery-permission banner ใช้โทนกลางแทน warning เหลือง
- สี `Color(0xFF...)` ที่คงไว้: `bank_icon.dart` เป็นแผนที่สีธนาคารฝั่ง client; `category_icon.dart` เป็น fallback และ palette สีหมวดหมู่; `slip_gallery_debug_page.dart` เป็นสีสถานะบนหน้า debug เท่านั้น
- สีขาว/โปร่งใสที่คงไว้เป็น foreground บน gradient, วงกลม/เส้นตกแต่ง hero, overlay และสีโปร่งใสสำหรับ layout; สีดำใน full-screen image viewer เป็น backdrop; สี alpha อื่นเป็นเงา/เส้นตกแต่ง

**Blocked by**: None — can start immediately.

---

### `02` — หน้าแรก: การ์ด hero และเมนูล่าง (Migrate)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: ผู้ใช้เปิดหน้าแรกแล้วเห็นการ์ด hero เป็น gradient ม่วงล้วน อ่านตัวอักษรขาวบนการ์ดได้ชัด จุดสีหมวดหมู่ใน legend แยกกันออก และไอคอนที่ถูกเลือกในเมนูล่างเป็นม่วงเดียวกับ FAB

**Acceptance criteria**:
- [x] พื้นหลังการ์ด hero ใช้ `primaryGradient` (topLeft → bottomRight)
- [x] ตัวอักษรบนการ์ด รวมถึง legend เป็นขาวเต็ม ไม่ใช้ขาวโปร่งสำหรับข้อความที่ต้องอ่าน
- [x] จุดสีหมวดหมู่ใน legend มีขอบขาวบาง (ประมาณ 1.5px)
- [x] ยังแสดงทุกหมวดบนการ์ดเหมือนเดิม และแถบ progress ไม่เปลี่ยน
- [x] ไอคอน/ป้ายที่ถูกเลือกในเมนูล่างใช้ `primary` (เดิมเป็นฟ้า `4F8EF7`) ส่วนไอคอนที่ไม่ถูกเลือกใช้โทนเทาจาก token ใหม่
- [x] layout, ตำแหน่งและขนาดของ FAB และเมนูล่างไม่เปลี่ยน
- [x] ไม่มีการเรียก `accentA`, `accentB`, `accentGradient` เหลือในหน้านี้และเมนูล่าง
- [ ] ถ่ายภาพหน้าแรกเทียบก่อน/หลังแนบใน PR เพื่อให้เจ้าของโปรเจกต์ตรวจ gradient ด้วยตา (ถ้าอ่อนไป ทางเลือกสำรองคือปลายเป็น `7C3AED` ตามที่ระบุใน spec)
- [x] `dart analyze` และเทสต์ผ่าน

**Audit notes (02)**: `ExpenseTotalWidget` ใช้ gradient ผ่าน `GradientHeroCard`; ข้อความบน hero และ legend เป็นขาวเต็ม จุดสีหมวดหมู่มีขอบขาว 1.5px และเมนูล่างเลือกใช้ `primary` โดยไม่เปลี่ยน layout. ยังไม่ได้ถ่ายภาพเทียบ เพราะไม่มี PR/อุปกรณ์จริงให้แนบผลตรวจ gradient ในงานนี้

**Blocked by**: `01` — วางรากระบบสีใหม่ (Expand)

---

### `03` — Transaction tile และรายการไม่มีหมวดหมู่ (Migrate)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: ในลิสต์รายการ ผู้ใช้เห็นจำนวนเงินอ่านง่ายขึ้น และรายการที่ยังไม่ระบุหมวดหมู่ดูสงบ ไม่มีสีเหลือง ยังเห็นไอคอน + ที่บอกว่าเพิ่มหมวดหมู่ได้ ส่วนข้อความ "ยังไม่ระบุหมวดหมู่" เป็นข้อความเทาธรรมดา

**Acceptance criteria**:
- [x] จำนวนเงินใช้ `expense` / `income` / `transfer` ตามประเภทรายการ และพื้นกล่องไอคอนของรายการปกติเป็น `tint` ของสีประเภทนั้น
- [x] pill ประเภท ("ใช้จ่าย" ฯลฯ) พื้น `surfaceMuted` ตัวอักษร `textBody`
- [x] รายการไม่มีหมวดหมู่: คงกล่องไอคอนเดิมที่มีสัญลักษณ์ + พื้น `surfaceMuted` ไอคอน + สี `textMuted` ไม่มีสีเหลืองและไม่มี badge สีเหลืองเหลืออยู่
- [x] ขอบของกล่อง + ตามผลตรวจจากตั๋ว 01: ถ้ากด + เปิดตัวเลือกหมวดหมู่ได้ทันที ใส่ขอบบาง 1.5px สี `border` ถ้าไม่ใช่ ไม่มีขอบ
- [x] ข้อความ "ยังไม่ระบุหมวดหมู่" เป็นข้อความเทา (`textMuted`) ไม่ใช่ pill ในตำแหน่งเดียวกับชื่อหมวดหมู่ของรายการปกติ
- [x] ไม่มีการเรียก `warning*`, `incomeSurface`, `expenseSurface`, `transferSurface` เหลือใน tile และ widget ลิสต์รายการ
- [x] widget test ใหม่ของ tile ที่ไม่มีหมวดหมู่: มีไอคอน +, มีข้อความ "ยังไม่ระบุหมวดหมู่" และไม่ใช้สีเหลืองจากชุด warning เดิม
- [x] เทสต์เดิมที่ pump ด้วย `MaterialApp()` เปล่ายังผ่านโดยไม่ต้องแก้ setup
- [x] `dart analyze` และเทสต์ผ่าน

**Audit notes (03)**: `CategoryQuickAssignChip` กดแล้วเปิด category picker ได้ทันที; กล่อง + จึงใช้พื้น `surfaceMuted`, ไอคอน `textMuted` และขอบ `border`. `ยังไม่ระบุหมวดหมู่` เป็นข้อความธรรมดา และ warning ของรายการขยะยังคงแสดง แต่เปลี่ยนเป็นโทนกลาง ไม่ลบพฤติกรรมแจ้ง junk

**Blocked by**: `01` — วางรากระบบสีใหม่ (Expand)

---

### `04` — หน้าสรุป (Migrate)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: หน้าสรุปใช้ม่วงแบรนด์เดียวกับหน้าอื่น แท็บที่เลือกและการ์ดบัญชีเป็น gradient เดียวกับการ์ด hero และสี semantic ของแท็บ/legend ตรงกับ token ใหม่

**Acceptance criteria**:
- [x] แท็บที่เลือก (รายรับ/รายจ่าย/ย้ายเงิน) ใช้ `primaryGradient` และแท็บที่ไม่ได้เลือกใช้ `surfaceMuted` พร้อมตัวอักษร `textBody`
- [x] การ์ดบัญชี (ใช้จ่าย/ลงทุน ฯลฯ) ใช้ `primaryGradient` และตัวอักษรบนการ์ดเป็นขาวเต็ม
- [x] ตัวหนังสือรอง/คำอธิบายในหน้าใช้ `textBody` หรือ `textMuted` ตามหลักใน spec (hint/caption เท่านั้นที่ใช้ `textMuted`)
- [x] เส้นคั่นและขอบใช้ `divider` / `border`
- [x] **ไม่แตะ**: ไอคอน `!` มุมขวาบน, สีหมวดหมู่ใน donut chart และ legend (มาจาก backend)
- [x] ไม่มีการเรียก token เก่า (`accentA/B`, `tabTrackBg`, `pillChipBg`, `textTertiary`, `textFaint` ฯลฯ) เหลือในหน้านี้
- [ ] ถ่ายภาพหน้าสรุปเทียบก่อน/หลังแนบใน PR
- [x] `dart analyze` และเทสต์ผ่าน

**Audit notes (04)**: แท็บสรุปรายเดือนใน `transactions_page.dart` และแท็บ breakdown รายปีใน `trend_page.dart` ใช้ `primaryGradient`; การ์ดบัญชีใช้ gradient เดียวกันผ่าน `GradientHeroCard`. คงสีหมวดหมู่จาก backend ใน pie/line chart และไม่ได้แก้ไอคอน `!`. ยังไม่ได้ถ่ายภาพเทียบเนื่องจากไม่มี PR/อุปกรณ์จริงในงานนี้

**Blocked by**: `01` — วางรากระบบสีใหม่ (Expand)

---

### `05` — หน้า Add/Edit และ widget ที่ใช้ร่วมกัน (Migrate)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: หน้าเพิ่ม/แก้ไขรายการและ widget ร่วม (chip, ช่องกรอก, bottom sheet) ใช้สีชุดเดียวกับหน้าอื่นทั้งหมด และไม่มีที่ไหนอ่านสีผ่าน `FinanceColors` อีก

**Acceptance criteria**:
- [x] chip: ที่ไม่ได้เลือกพื้น `surface` ขอบ `border` ตัวอักษร `textBody`, ที่เลือกพื้น `textPrimary`
- [x] ช่องกรอกและ bottom sheet ใช้ `border`, `surface`, `primary` (focus) ตาม token ใหม่
- [x] `SheetHandle` ใช้ `border` แทนสี hardcode เดิม
- [x] เงาของ `AppShadows.accent` ใช้ `tint(primary, .32)` (เงาการ์ดปกติไม่เปลี่ยน)
- [x] ทุกที่ที่เรียก `context.financeColors.income/expense` เปลี่ยนเป็น `AppColors.income/expense` ตรงๆ
- [x] widget ร่วมอื่นๆ ที่รายการสำรวจจากตั๋ว 01 ระบุไว้ ย้ายไป token ใหม่ครบ (ถ้ารายการนี้ใหญ่เกินหนึ่ง context ให้แยกย่อยก่อนลงมือและแจ้งผู้ใช้)
- [x] ไม่มีการเรียก token เก่าเหลือในไฟล์ที่ตั๋วนี้รับผิดชอบ
- [x] `dart analyze` และเทสต์ผ่าน

**Audit notes (05)**: ย้ายสีใน add/edit transaction, category/account forms และ shared widgets; `SheetHandle` ใช้ `border`, focus ใช้ `primary`, และเงา accent ใช้ `tint(primary, .32)`. ลบ `FinanceColors` และเปลี่ยนจุดที่เคยอ่าน extension ให้ใช้ `AppColors` โดยตรง

**Blocked by**: `01` — วางรากระบบสีใหม่ (Expand)

---

### `06` — ลบของเก่าและตรวจรอบสุดท้าย (Contract)

**Parent**: `cashlog-color-system-spec.md`

**What to build**: ระบบสีเหลือชุดเดียว ไม่มีชื่อเก่าหรือค่าที่ตกค้างอีก และแอปทั้งหมดมีหน้าตาม่วงเดียวกันโดยไม่มีสีเหลืองเลย

**Acceptance criteria**:
- [x] ลบ token เก่าทั้งหมดจาก `AppColors`: `accentA`, `accentB`, `accentGradient`, `primarySurface`, `primarySurfaceBorder`, `primaryText`, `inputBorder`, `chipUnselectedBorder`, `chipUnselectedBg`, `chipSelectedBg`, `tabTrackBg`, `pillChipBg`, `neutralIcon`, `neutralSurface`, `textSecondary` (ความหมายเดิม), `textTertiary`, `textFaint`, `chipUnselectedText`, `incomeSurface`, `expenseSurface`, `transferSurface`, และ `warning*` ทั้ง 6 ค่า
- [x] ลบ `FinanceColors` (ไฟล์และการลงทะเบียนใน theme) โดยโค้ดทุกจุดอ่านสีจาก `AppColors` ตรงๆ
- [x] `dart analyze` ไม่พบการอ้างอิงชื่อเก่า (ถ้าพบ ให้แก้ที่ต้นทางแทนการคืนชื่อเก่า)
- [x] ค้นหา `Color(0xFF...)` และ `Colors.` ที่ hardcode นอก `AppColors` ทั้งหมดและแจ้งผู้ใช้ว่าแต่ละจุดควรใช้ token อะไรหรือควรคงไว้เพราะเหตุใด (สีหมวดหมู่จาก backend และสีโปร่งใสของตกแต่งเช่นวงกลมใน hero ไม่ต้องแก้)
- [x] อัปเดต golden test ครั้งเดียว (ถ้าโปรเจกต์มี ตามผลตรวจจากตั๋ว 01) และตรวจภาพเทียบก่อน/หลัง
- [x] ยืนยันว่าเทสต์ที่ pump ด้วย `MaterialApp()` เปล่ายังผ่านโดยไม่ต้องแก้ setup
- [x] `dart analyze` และเทสต์ทั้งชุดผ่าน
- [ ] ตรวจด้วยตาบนเครื่องว่าทั้งสามหน้า (Home, Summary, Add) ไม่มีสีเหลืองและไม่มีสีฟ้า `4F8EF7` ตกค้าง

**Audit notes (06)**:
- ไม่พบ golden tests จึงไม่มีภาพ golden ที่ต้องอัปเดต
- ค้นไม่พบ token เก่าหรือ `FinanceColors` ใน `lib/` และ `test/`; `AppColors` เหลือ token ชุดใหม่เท่านั้น
- hardcode ที่คงไว้ตามหน้าที่: `bank_icon.dart` เป็นสีธนาคารใน local map; `category_icon.dart` มี fallback เทาและ `kCategoryColorChoices` สำหรับสีหมวดหมู่ (รวม `#4F8EF7`/`#FBBF24`) ซึ่งไม่ใช่สีแบรนด์และไม่ควรเปลี่ยนตามข้อกำหนดให้คงสีหมวดหมู่; `slip_gallery_debug_page.dart` ใช้สีสถานะเฉพาะหน้า debug
- `Colors.white` ใช้กับข้อความ/ไอคอนบน gradient และสีขอบ legend; `Colors.white.withValues(...)`/สีโปร่งใสเป็นของตกแต่งและ overlay; `Colors.black` เป็นพื้น viewer เต็มจอ; `Color(0x33141428)`, `Color(0x14141428)` และ alpha colors เป็นเงา/เส้นตกแต่ง ไม่ควรแทนด้วยสีข้อความหรือพื้นผิว
- จุดที่พบ `Colors.` (รวม 31 ไฟล์): `core/router/app_shell.dart`, `core/theme/app_theme.dart`; `features/accounts/presentation/pages/{account_detail_page,account_form_page,accounts_page}.dart`; `features/categories/presentation/pages/{categories_page,category_form_page}.dart`; `features/dashboard/presentation/pages/{dashboard_page,trend_page}.dart` และ `features/dashboard/presentation/widgets/{auto_scan_processing_indicator,auto_scan_status_text,expense_pie_chart,expense_total_widget,pending_actions_banner,trend_line_chart}.dart`; `features/slip_scan/presentation/widgets/manual_slip_attach_button.dart`; `features/transactions/presentation/pages/{add_transaction_page,transaction_form_page,transactions_page}.dart` และ `features/transactions/presentation/widgets/{category_quick_assign_sheet,transaction_form_fields,transaction_list_tile}.dart`; `shared/widgets/{anchored_dropdown_panel,category_picker_sheet,circular_icon_button,form_text_field,full_screen_image_viewer,gradient_hero_card,pill_form_row,primary_gradient_button,segmented_tabs}.dart`. สีขาวเป็น foreground บน gradient/ไอคอน, สีดำเป็น backdrop, และสีโปร่งใสเป็นสถานะ/overlay; สี semantic อื่นย้ายเป็น token แล้ว
- warning ของรายการขยะ, pending actions และ permission เปลี่ยนเป็นเทากลางโดยยังคงข้อความ/พฤติกรรมเตือน; ไอคอนเตือนในรายการขยะยังอยู่ตาม business rule
- ยังไม่ได้ยืนยัน gradient ด้วยตาบน Home/Summary/Add บนอุปกรณ์จริง; ต้องตรวจบนอุปกรณ์ก่อนตัดสินว่าจะใช้ออปชัน `7C3AED` หรือไม่

**Blocked by**: `02`, `03`, `04`, `05`
