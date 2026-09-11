# Cashlog Mobile — Tickets

อ้างอิงจาก `cashlog-frontend-spec.md`. แต่ละ ticket เป็น tracer-bullet — ทำงานจบเป็น vertical slice ใช้งานได้จริง ไม่ใช่แบ่งตาม layer (ไม่มี "สร้าง model ทั้งหมดก่อน" แยกจาก "สร้าง UI ทั้งหมด")

Format: **[ID] ชื่อ** — blocked by: … 

---

## Foundation (ต้องทำก่อนสุด)

### T1 — Project scaffold + networking core
สร้างโปรเจกต์ Flutter, ตั้ง `core/network/dio_client.dart` (dio + `X-API-Key` interceptor), `core/network/failure.dart` (sealed `Failure` mapping จาก 12 error_code + retry policy ตามสเปกข้อ 4) — repository/usecase คืนค่าเป็น **`Either<Failure, T>`** (dartz) เสมอ ไม่ throw exception ข้าม layer, ตั้ง `core/env/env.dart` อ่านค่าจาก `--dart-define`, ทำไฟล์ `env/dev.json` และ `env/prod.json`
**Blocked by:** ไม่มี (จุดเริ่ม)
**Acceptance:** ยิง 1 GET request (เช่น `/health` หรือ `/accounts`) จาก dev build สำเร็จ, error ที่ไม่รู้จักไม่ทำให้แอป crash, ตัวอย่าง repository method คืน `Either<Failure, T>` ได้ถูกต้องทั้งเคส success/fail

### T2 — Drift database + schema
สร้าง `core/db/app_database.dart` พร้อมทั้ง 5 ตาราง (`ScannedSlips`, `CachedTransactions`, `CachedAccounts`, `CachedCategories`, `PendingManualActions`) ตามสเปกข้อ 8, รัน `build_runner` ได้ไม่ error
**Blocked by:** T1 (ใช้ env/project scaffold เดียวกัน)
**Acceptance:** เขียน/อ่านทั้ง 5 ตารางได้ผ่าน unit test ง่ายๆ

### T3 — Navigation shell
ตั้ง `go_router` + bottom nav 4 แท็บ (Dashboard / Transactions / Accounts / Categories) เป็นหน้าเปล่าๆ ที่ navigate ไปมาได้
**Blocked by:** T1
**Acceptance:** สลับแท็บได้ครบ ไม่ crash, deep-link กลับมาแท็บเดิมได้หลัง hot restart

---

## Core CRUD (แกนของแอป)

### T4 — Accounts CRUD (end-to-end)
Feature slice เต็ม: list (จาก cache + refresh จาก API) → create → edit → delete ผ่าน UI จริง เขียนลง `cached_accounts` ด้วย รวม **local bank_icon map** (ชื่อ+โลโก้+สี ต่อธนาคาร, เก็บเป็น static data ในแอป) ให้ผู้ใช้เลือกธนาคารตอนสร้าง account แล้วส่งแค่ code string (`bank_icon`) ไป backend, มี fallback ไอคอนกลางสำหรับ code ที่ไม่รู้จัก

**Cache sync ต้องเป็น upsert-only** (ไม่ลบ record ที่หายไปจาก `GET /accounts` response) เพราะ endpoint filter เฉพาะ `is_active=true` — บัญชีที่ปิดแล้วต้องยังอยู่ใน local cache เพื่อ lookup ชื่อ/โลโก้ของ transaction เก่า หน้ารายการบัญชี filter `isActive=true` ตอน **query** ไม่ใช่ตอน sync

หน้ารายละเอียด account **ไม่ยิง network ใหม่** — query จาก `cached_accounts` ตรงๆ (ไม่มี `GET /accounts/:id` ใน backend และไม่จำเป็นต้องมี เพราะ list response มีฟิลด์ครบอยู่แล้ว)

**Blocked by:** T1, T2, T3
**Acceptance:** สร้าง/แก้/ลบ account จากมือถือ แล้วเห็นผลใน backend จริง (ตรวจผ่าน Postman ได้), เลือกธนาคารจาก list แล้วโลโก้/สีโชว์ถูกต้องตอน redisplay, ปิด account แล้ว transaction เก่าที่ผูกกับ account นั้นยังโชว์ชื่อ/โลโก้ถูกต้อง (ไม่ fallback เป็น "unknown")

### T5 — Categories CRUD (end-to-end)
เหมือน T4 แต่เป็น categories รวม **delete guard** (FR-2.2): ก่อนลบ นับจำนวน `cached_transactions` ที่ `categoryId == X` แล้วแจ้งเตือนผู้ใช้ก่อน confirm — ไม่เพิ่ม endpoint backend ใหม่ ใช้ cache นับเอง
**Blocked by:** T1, T2, T3
**Acceptance:** ลบ category ที่มี transaction ผูกอยู่ → เห็น dialog บอกจำนวนที่ได้รับผลกระทบก่อนลบจริง, ลบแล้ว transaction เหล่านั้นกลายเป็นไม่มีหมวดหมู่ (ไม่ถูกลบ)

### T6 — Manual transaction create/edit
ฟอร์มสร้าง/แก้ transaction ธรรมดา (ไม่ใช่จาก slip) ต้องเลือก account + category ได้จริง
**Blocked by:** T4, T5 (ต้องมี account/category ให้เลือกก่อน)
**Acceptance:** สร้าง income/expense/transfer ได้ครบ 3 แบบ, validation ฝั่ง client ตรงกับ backend rule (เช่น `ErrTransferSameAccount`, `ErrCategoryNotAllowedForTransfer`)

### T7 — Transaction feed
List หน้าแรก + infinite scroll pagination ต่อเดือน + month selector
**Blocked by:** T2, T3, T6 (ต้องมีทางสร้าง transaction ก่อนถึงจะมีอะไรให้ list)
**Acceptance:** scroll โหลดหน้าถัดไปได้, สลับเดือนแล้ว list เปลี่ยนถูกต้อง

### T8 — Dashboard summary
หน้า summary ผูกกับ month/year state เดียวกับ T7
**Blocked by:** T7

---

## Slip Auto-Scan (ฟีเจอร์หลักของแอป)

### T9 — Gallery permission + album query
ขอ permission `READ_MEDIA_IMAGES` (+ fallback เครื่องเก่า) → query album "SCB EASY"/"Dime!" ผ่าน `photo_manager` → แสดง list ชื่อไฟล์ที่เจอ (debug screen พอ ยังไม่ต้องอัปโหลดจริง)
**Blocked by:** T1
**Acceptance:** ทดสอบบนเครื่องจริง Android 14 เห็นรายชื่อไฟล์ครบตามที่มีใน 2 album

### T10 — Slip upload pipeline
ต่อจาก T9: diff กับ `scanned_slips` → compress (`flutter_image_compress`) → อัปโหลด**ทีละไฟล์แบบ sequential + delay ~7 วินาที/ไฟล์** (backend rate limit 10 req/60s บน `/upload-slip`) → `POST /upload-slip` → handle 3 ผลลัพธ์ (uploaded/duplicate/failed) → เขียนผลลง `scanned_slips` + refresh feed (T7) — ต้องมี progress indicator ระหว่าง upload หลายไฟล์ (เช่น ตอน setup เครื่องใหม่ scan ย้อนหลัง 30 วันทีเดียว)
**Blocked by:** T9, T2, T7
**Acceptance:** สแกนสลิปจริง 1 ใบ → เห็น transaction ใหม่โผล่ใน feed, สแกนซ้ำรอบสองไม่ยิงซ้ำ (duplicate ถูก skip ฝั่ง client จาก local diff), สแกนพร้อมกัน >10 ไฟล์ไม่โดน 429

### T11 — Scan trigger lifecycle
ผูก T10 เข้ากับ `AppLifecycleState` (cold start + resume)
**Blocked by:** T10
**Acceptance:** สลับไปแอปธนาคารแล้วกลับมา trigger scan ใหม่อัตโนมัติ

### T12 — Junk detection + badge UI
Rule `amount==0 && sender/receiver ว่าง` → `isJunk=true`, badge ในฟีด + ปุ่มลบ/แก้ไขเอง
**Blocked by:** T10, T7
**Acceptance:** สลิปที่อ่านไม่ออก (ทดสอบด้วยรูปสุ่มใน album) โชว์ badge ถูกต้อง, ลบได้, แก้ไขแล้ว badge หาย

---

## Resilience

### T13 — Pending manual actions retry queue
เมื่อ T6 (create/update/delete) fail จาก network/error → เก็บใน `pending_manual_actions` → UI "รายการค้าง — แตะเพื่อลองใหม่"
**Blocked by:** T6, T2

### T14 — Cache invalidation
Invalidate `cached_transactions`/dashboard ตามเดือนที่เกี่ยวข้องหลัง mutation สำเร็จ, รวมเคสแก้ `transaction_date` ข้ามเดือน
**Blocked by:** T6, T7, T8, T10

### T15 — Gemini quota retry
`ErrGeminiQuotaExhausted` → mark `failed` ใน `scanned_slips` ไม่ auto-retry ทันที ให้รอบสแกนถัดไปหยิบมาลองใหม่
**Blocked by:** T10

---

## Non-blocking / ทำคู่ขนานได้

### T16 — SRS reconciliation
อ่าน SRS ฉบับเต็มเทียบกับ `cashlog-frontend-spec.md` หา gap
**Blocked by:** ไม่มี — ควรทำให้เสร็จก่อน T6 เป็นอย่างช้า เผื่อมี business rule ที่ spec นี้พลาด

### T17 — Real-device scoped storage validation
ทดสอบ `photo_manager` กับ Android scoped storage ในสถานการณ์ขอบ (เช่น ลบรูปจาก album ระหว่างแอปเปิดอยู่)
**Blocked by:** T9

### T18 — Quick category assignment (BR-9, FR-5.3)
Tap chip/ปุ่มหมวดหมู่ตรงในแถวของ transaction บนหน้า feed หลัก (T7) → เปิด bottom sheet เลือกหมวดหมู่ → `PATCH /transactions/:id` ทันที ไม่เปิดหน้าแก้ไขเต็มรูปแบบ (T6) — เป็นทางหลักในการกำหนดหมวดหมู่ ส่วน T6 เป็น escape hatch สำหรับข้อมูลผิดปกติเท่านั้น
**Blocked by:** T5 (ต้องมี category ให้เลือก), T7
**Acceptance:** tap chip จาก feed → เลือกหมวดหมู่ → เห็นผลอัปเดตใน feed ทันทีโดยไม่ออกจากหน้า feed

### T19 — SRS document sync (non-code)
อัปเดตเอกสาร SRS ให้ตรงกับ decision จริงที่ตกลงกันแล้ว: (1) BR-8/FR-4.8 แก้จาก "backend skip เงียบๆ" เป็น "backend สร้าง transaction ปกติ, frontend detect+badge+ให้ลบ/แก้เอง" (2) section 6.1 Account fields แก้ `icon_key`/`color_hex` เป็น `bank_icon`
**Blocked by:** ไม่มี — ทำเมื่อไหร่ก็ได้ ไม่กระทบ dev

---

## Gaps found in T16

T16 (SRS reconciliation) พบ business rule 2 ข้อที่มีอยู่ใน SRS แต่ `cashlog-frontend-spec.md` ไม่เคยเขียนถึงเลย (ไม่ใช่แค่เอกสารไม่ตรงกันแบบ T19 — เป็นฟีเจอร์ที่ขาดไปทั้งฟีเจอร์) เพิ่มเป็น ticket ใหม่ที่นี่

### T20 — Account current_balance display (BR-7, FR-1.4, FR-6.3)
คำนวณและแสดง `current_balance` ของแต่ละบัญชีฝั่ง client ตามสูตร SRS BR-7 (§6.1): `opening_balance + SUM(income) - SUM(expense) - SUM(transfer ที่ from_account_id) + SUM(transfer ที่ to_account_id)` โดยคำนวณจาก `cached_transactions` ในเครื่อง — `GET /accounts` ไม่คืนค่านี้มาให้ ต้องแสดงทั้งในหน้ารายการบัญชี (FR-1.4) และหน้า dashboard แบบต่อบัญชี (FR-6.3) BR-7 ยังกำหนดให้ต้องมีข้อความกำกับ (disclaimer) ทุกที่ที่แสดงยอดคงเหลือ เช่น "ยอดประมาณจากข้อมูลที่บันทึกในระบบ" — **ไม่ใช่ทางเลือก ต้องมีเสมอ**
**Blocked by:** T4 (accounts), T7 (transaction feed — เป็นแหล่งข้อมูลสำหรับ aggregate)
**Acceptance:** เปิดหน้ารายการบัญชี → เห็นยอดคงเหลือที่คำนวณถูกต้องตามสูตร (ตรวจกับเลขที่คำนวณมือ) พร้อมข้อความ disclaimer เสมอ, เปิดหน้า dashboard ต่อบัญชี → เห็นยอดเดียวกัน, ปิด (soft-delete) บัญชีแล้วยังคำนวณยอดคงเหลือได้ถูกต้องจาก `cached_accounts` เดิม (ไม่ยิง network ใหม่)

### T21 — Manual slip attach button (BR-8, FR-4.1)
สร้างช่องทางรับสลิปช่องที่สองตาม SRS BR-8/FR-4.1: ปุ่มถ่ายภาพ/เลือกภาพจากคลังภาพ (ใช้ `image_picker` หรือเทียบเท่า) กดได้เองตลอดเวลา ป้อนเข้า upload pipeline **เดียวกัน**กับ auto-scan (T10) — ใช้แก้เคสที่ auto-scan กรอง folder ไปไม่ถึง ซึ่ง SRS ระบุว่าพบบ่อยกับรายรับ `cashlog-frontend-spec.md` §7.1 เอ่ยถึงปุ่มนี้ผ่านๆ ("ปุ่ม manual แนบสลิปแยกไว้") แต่ไม่เคยระบุรายละเอียด — ticket นี้คือ spec + implementation ส่วนที่ขาดไป
**Blocked by:** T10 (ใช้ upload pipeline เดียวกัน)
**Acceptance:** กดปุ่ม → ถ่าย/เลือกภาพ → ผ่าน pipeline เดียวกับ auto-scan (compress, `POST /upload-slip`, บันทึกผลลง `scanned_slips` เหมือนกัน) → เห็น transaction ใหม่โผล่ใน feed, ปุ่มกดได้ตลอดเวลาไม่ขึ้นกับสถานะ auto-scan

---

## Dependency overview (ลำดับแนะนำ)

```
T1 ─┬─ T2 ─┬─ T4 ─┬─ T6 ─┬─ T7 ─┬─ T8
    │      │      │      │      ├─ T14
    │      │      │      │      ├─ T18 (ต้องมี T5 ด้วย)
    │      │      │      │      └─ T20 (ต้องมี T4 ด้วย)
    │      │      └─ T5 ─┘      
    │      │                     
    │      └─ T9 ─── T10 ─┬─ T11
    │                      ├─ T12
    │                      ├─ T13 (ร่วมกับ T6)
    │                      ├─ T15
    │                      └─ T21
    └─ T3 (ขนานกับ T2)

T16, T17, T19 — ทำขนานได้ตลอด ไม่ block สาย main
```
