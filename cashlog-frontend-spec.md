# Cashlog Mobile — Frontend Architecture Spec

**สถานะ:** Draft v1 — สรุปจากบทสนทนา grill-me (29 การตัดสินใจ)
**ผู้เขียน:** Jar (solo developer)
**ขอบเขต:** Flutter client แอปสำหรับ `cashlog-api` (Go/Fiber backend, Cloud Run `asia-southeast1`)
**แพลตฟอร์ม:** Android เท่านั้น (v1), minSdk 26+, ทดสอบจริงบน Android 14

---

## 1. บริบทและสมมติฐานหลัก

- ผู้ใช้แอปคือเจ้าของแอปเพียงคนเดียว (single-owner app) — ไม่มีระบบ multi-user
- Backend ยืนยันตัวตนด้วย static API Key เดียว (`X-API-Key` header) ไม่มี JWT/login
- Backend ออกแบบมาให้รองรับ **auto-scan gallery ย้อนหลัง 30 วัน** อยู่แล้ว (idempotency ผูกกับ `local_image_name` + Redis TTL 30 วัน)
- ธนาคารที่ใช้งานจริง: **SCB EASY** และ **Dime!** — ทั้งสองแอปมี album แยกใน Android gallery ชื่อ "SCB EASY" และ "Dime!" ตามลำดับ (ยืนยันจาก screenshot เครื่องจริง)
- ไม่สามารถอ่าน SRS (Google Docs) ได้เนื่องจากติด permission — สเปกนี้อ้างอิงจากบทสนทนา grill-me เท่านั้น ควรตรวจทานกับ SRS ฉบับเต็มอีกครั้งก่อนเริ่ม implement

---

## 2. State Management

**เลือก: Riverpod + `riverpod_generator` (codegen)**

- ใช้ `@riverpod` annotation ต้องมี `build_runner` ใน dev workflow
- เหตุผล: ต่อเนื่องจาก pattern ที่ใช้ใน ANS Part project อยู่แล้ว (Riverpod providers colocated ต่อ feature), ลด boilerplate สำหรับ endpoint จำนวนมาก

---

## 3. Project Structure

**เลือก: Feature-first** (ไม่ใช่ layer-first แบบสมมาตรกับ Go backend)

```
lib/
├── main.dart
├── core/
│   ├── network/
│   │   ├── dio_client.dart
│   │   └── failure.dart
│   ├── db/
│   │   ├── app_database.dart
│   │   └── tables/
│   ├── env/
│   │   └── env.dart
│   └── router/
│       └── app_router.dart
├── features/
│   ├── slip_scan/{data,domain,presentation}/
│   ├── transactions/{data,domain,presentation}/
│   ├── dashboard/{data,domain,presentation}/
│   ├── accounts/{data,domain,presentation}/
│   └── categories/{data,domain,presentation}/
└── shared/
    └── widgets/
```

แต่ละ feature มี data/domain/presentation ของตัวเอง ไม่แชร์ layer ข้าม feature ยกเว้นผ่าน `core/` และ `shared/`

---

## 4. Networking

- **Library:** `dio` (รองรับ multipart upload, interceptor, custom header ได้สะดวกกว่า `http` package เปล่า)
- **Auth header:** `X-API-Key` แนบทุก request ผ่าน dio interceptor, ค่า key มาจาก compile-time constant (ดูหัวข้อ Environment)
- **Error handling pattern:** ใช้ `dartz` (`Either<Failure, T>`) ตาม SRS section 5.1 และตาม pattern ที่ใช้ใน ANS Part อยู่แล้ว — dio interceptor แปลง error เป็น `Failure` แล้ว **repository/usecase คืนค่าเป็น `Either<Failure, T>` เสมอ ไม่ throw exception ข้าม layer** (`Left(failure)` เมื่อ fail, `Right(data)` เมื่อสำเร็จ) เพื่อ consistency กับโปรเจกต์อื่นของผู้พัฒนา

### Retry policy ต่อ error code

| กลุ่ม | error_code | พฤติกรรม |
|---|---|---|
| Transient (auto-retry) | `ErrTimeout`, `ErrGeminiUnavailable`, `ErrInternalDB`, `ErrContextCanceled` | retry อัตโนมัติ |
| Permanent (โชว์ error ให้ user ตัดสินใจ) | `ErrNotFound`, `ErrDuplicateRequest`, `ErrInvalidInput`, `ErrGeminiEmptyResponse`, `ErrSlipParseFailed`, `ErrAccountInactive`, `ErrTransferSameAccount`, `ErrCategoryNotAllowedForTransfer` | ไม่ auto-retry |
| Special case | `ErrGeminiQuotaExhausted` | ไม่ retry ทันที — mark เป็น `failed` ใน `scanned_slips` แล้วให้ scan รอบถัดไปหยิบมา retry เอง (กัน loop ยิง Gemini ตอน quota หมด) |

### Body size limit
- Fiber backend ใช้ default `BodyLimit` (4MB) ไม่มีการ override
- **ต้อง compress รูปก่อนอัปโหลดเสมอ** ด้วย `flutter_image_compress` (บีบเหลือ ~1-2MB) เพื่อกัน 413 error และประหยัด data

### Rate limit
- Backend จำกัด request ด้วย Fiber `limiter` middleware แยก 2 กลุ่ม:
  - endpoint ทั่วไปใน `/api/v1`: **60 req / 60 วินาที**
  - `POST /upload-slip` โดยเฉพาะ: **10 req / 60 วินาที**
- **Client ต้องยิง upload สลิปแบบ sequential + delay คงที่** (เว้น ~7 วินาทีต่อไฟล์ ให้ปลอดภัยกว่า 10/60s) ไม่ใช่ fire ทุกไฟล์พร้อมกัน — สำคัญมากตอน scan รอบแรกที่อาจเจอไฟล์ใหม่ย้อนหลัง 30 วันทีเดียวหลายไฟล์

---

## 5. Environment / Config

- มี 2 environments อยู่แล้ว: dev และ prod (ทั้งคู่ deploy บน Cloud Run, API Key คนละชุด, database แยกโหมด dev/public)
- ใช้ `--dart-define-from-file=env/dev.json` และ `env/prod.json` — ไม่ทำ Flutter flavors เต็มรูปแบบ (เกินความจำเป็นสำหรับ single-owner app)
- แต่ละไฟล์ env มีอย่างน้อย: `BASE_URL`, `API_KEY`

---

## 6. Auth / API Key Storage

- **Build-time inject** ผ่าน `--dart-define` เท่านั้น ไม่มีหน้า login/settings ให้กรอก key
- เหตุผล: single-owner app ไม่มี multi-tenant, ลดความซับซ้อนที่ไม่จำเป็น

---

## 7. Slip Auto-Scan Flow

### 7.1 Interaction model
**Hybrid:** auto-scan แบบ foreground เท่านั้น (ไม่ทำ background service) + ปุ่ม manual แนบสลิปแยกไว้

### 7.2 Scan trigger
สแกนทั้ง **cold start** และ **app resume** (จับผ่าน `WidgetsBindingObserver` → `AppLifecycleState.resumed`)

### 7.3 Permission
- Android 14 (API 34) — ใช้ `READ_MEDIA_IMAGES` เป็นหลัก
- minSdk 26 พร้อม fallback `READ_EXTERNAL_STORAGE` สำหรับเครื่องเก่ากว่า Android 13
- ขอ full library access ตรงๆ พร้อมข้อความอธิบายเหตุผล (ไม่ต้องกังวลเรื่อง privacy review เพราะเป็นแอปส่วนตัว)

### 7.4 Library
`photo_manager` — query album ตามชื่อ (`SCB EASY`, `Dime!`) ได้ตรงๆ โดยไม่ต้อง hardcode path ลึก

### 7.5 Folder filter (source of truth)
Album ที่ scan: **"SCB EASY"** และ **"Dime!"** (ยืนยันจากเครื่องจริงของ Jar) — เก็บเป็น config list ที่แก้ได้ง่าย ไม่ hardcode ฝังลึก เผื่อธนาคารเปลี่ยน path ตอนอัปเดตแอป

### 7.6 Sequence

1. App เปิด/resume → trigger auto-scan
2. เช็ค permission (`READ_MEDIA_IMAGES`)
3. Query album "SCB EASY" + "Dime!" ผ่าน `photo_manager`
4. Diff กับตาราง `scanned_slips` (local) → เอาเฉพาะไฟล์ใหม่ที่ยังไม่เคย attempt
5. Compress รูปด้วย `flutter_image_compress`
6. **Upload ทีละไฟล์แบบ sequential + delay ~7 วินาที/ไฟล์** (ดูหัวข้อ 7.6.1)
7. `POST /upload-slip` (multipart, `X-API-Key`)
8. จัดการผลลัพธ์ 3 แบบ: `uploaded` (สร้าง transaction) / `duplicate` (backend เคย process แล้ว) / `failed` (error)
9. บันทึกผลลง `scanned_slips` + refresh transaction feed

### 7.6.1 Rate limit บน `/upload-slip`

⚠️ **Backend จำกัด `/upload-slip` ไว้ที่ 10 requests/60 วินาที** (ส่วน endpoint อื่นใน `/api/v1` จำกัด 60 requests/60 วินาที) — ยืนยันจาก `router.go` (`slipRateLimiter`)

**แนวทาง:** อัปโหลดทีละไฟล์แบบ **sequential + delay คงที่ ~7 วินาที/ไฟล์** (ปลอดภัยกว่า 10/60s เผื่อ error/retry) ไม่ทำ batch-then-backoff แบบซับซ้อนใน v1 เพราะ scan รอบปกติเจอไฟล์ใหม่ไม่กี่ไฟล์ต่อครั้งอยู่แล้ว (ยกเว้นตอน setup เครื่องใหม่ครั้งแรกที่ scan ย้อนหลัง 30 วันทีเดียว ซึ่งจะใช้เวลานานขึ้นตามจำนวนไฟล์ — แสดง progress ให้ผู้ใช้เห็นระหว่างรอ)

### 7.7 Junk detection

⚠️ **Backend gap ที่ต้อง handle ฝั่ง client:** Gemini prompt สั่งให้ตอบค่าว่าง/0 ถ้าอ่านภาพไม่ออก แทนที่จะ error แยก — เท่ากับว่ารูปที่ไม่ใช่สลิปจริง (หลุดเข้ามาใน album โดยบังเอิญ) จะสร้าง transaction `amount == 0` เข้าระบบเงียบๆ

**Rule:** transaction ที่ `amount == 0 && senderName.isEmpty && receiverName.isEmpty` → mark `isJunk = true` ฝั่ง client

**UX:** โชว์ใน feed ปกติพร้อม **badge เตือน** (เช่น ⚠️ "อ่านข้อมูลสลิปไม่ได้") มีทั้งปุ่ม **ลบ** (`DELETE /transactions/:id`) และ **แก้ไขเอง** (`PATCH` กรอก amount/sender เอง) — ไม่บังคับลบทิ้งอย่างเดียว เพราะบางทีอ่านได้แค่บางฟิลด์

การลบ junk transaction ออกจากแอปไม่กระทบ Redis cache ฝั่ง backend — ไฟล์นั้นจะไม่ถูกสแกนซ้ำอยู่ดี

### 7.8 หลังสแกนสำเร็จ
Auto-save เข้า feed ทันที ไม่บังคับ confirm/review ทีละใบ (แก้ทีหลังผ่าน PATCH ได้ ตาม pattern `category_id = nil` ที่ backend รองรับอยู่แล้ว)

### 7.9 Bank icon mapping (client-owned)

⚠️ **Backend เปลี่ยน schema** (`icon_key` + `color_hex` → `bank_icon` เดียว, string อิสระไม่มี enum validate ฝั่ง server, `example: "scb"`)

**แนวทาง:** Frontend เป็นเจ้าของข้อมูล "ชื่อธนาคาร + รูปภาพ/โลโก้" ทั้งหมด ผ่าน local static map ในโค้ด (เช่น `assets/bank_icons/`) — backend เก็บแค่ `bank_icon` เป็น code string (เช่น `"scb"`, `"dime"`) ไว้ map ตอนแสดงผลเท่านั้น ไม่มี asset/สีใน backend เลย

- ตอนสร้าง account: ผู้ใช้เลือกธนาคารจาก list ที่ frontend รู้จัก (ชื่อ + โลโก้ + สี) → ส่ง `bank_icon` code ไป backend
- ตอนแสดงผล (feed/dashboard): backend คืน `bank_icon` code กลับมา → frontend lookup ใน local map เพื่อโชว์ชื่อ/โลโก้/สี
- ถ้าเจอ `bank_icon` code ที่ไม่อยู่ใน local map (เช่นสร้างจาก client เวอร์ชันเก่ากว่า) → fallback เป็นไอคอนกลาง + โชว์ code ดิบเป็นชื่อ
- `colorHex` **ไม่มีอยู่ใน backend/drift schema แล้ว** — คำนวณจาก local map เสมอ ไม่ persist แยก

---

## 8. Local Persistence (drift)

**Engine:** `drift` (typed sqlite)

### 8.1 Schema

```dart
// ── scanned_slips ──────────────────────────────────────────
// 1 row ต่อ 1 ไฟล์ที่เคย "พยายาม" ส่งไป backend แล้ว
enum SlipStatus { uploaded, duplicate, failed, junk }

class ScannedSlips extends Table {
  TextColumn get localImageName => text()();       // ต้องตรงกับที่ส่งให้ backend เป๊ะ
  TextColumn get sourceFolder => text()();         // "SCB EASY" | "Dime!"
  TextColumn get status => textEnum<SlipStatus>()();
  IntColumn get serverTransactionId => integer().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();
  DateTimeColumn get scannedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localImageName};
}

// ── cached_transactions ────────────────────────────────────
// read-through mirror ของ GET /transactions (ต่อเดือน)
class CachedTransactions extends Table {
  IntColumn get id => integer()();                 // ตรงกับ backend id เป๊ะ
  RealColumn get amount => real()();
  TextColumn get transactionType => text()();       // income | expense | transfer
  TextColumn get senderName => text().withDefault(const Constant(''))();
  TextColumn get receiverName => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  IntColumn get accountId => integer().nullable()();
  IntColumn get fromAccountId => integer().nullable()();
  IntColumn get toAccountId => integer().nullable()();
  TextColumn get source => text()();                // manual | slip
  TextColumn get localImageName => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  IntColumn get categoryId => integer().nullable()();
  BoolColumn get isJunk => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── cached_accounts / cached_categories ────────────────────
class CachedAccounts extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get accountType => text()();
  RealColumn get openingBalance => real()();
  TextColumn get matchingKeywordsJson => text()();  // JSON string, decode ใน repository
  TextColumn get bankIcon => text()();              // เก็บ code ตรงกับ backend เช่น "scb", "dime" — ไม่มี colorHex column แล้ว (ดูหัวข้อ 7.9)
  BoolColumn get isActive => boolean()();
  @override
  Set<Column> get primaryKey => {id};
}

class CachedCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get type => text()();                  // income | expense
  TextColumn get iconKey => text()();
  TextColumn get colorHex => text()();
  @override
  Set<Column> get primaryKey => {id};
}

// ── pending_manual_actions ─────────────────────────────────
// retry queue เฉพาะ manual create/update/delete ที่ fail (ไม่เกี่ยวกับ slip)
class PendingManualActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get actionType => text()();  // create_transaction | create_transfer | update_transaction | delete_transaction
  TextColumn get payloadJson => text()();
  IntColumn get targetTransactionId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastErrorCode => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**หมายเหตุ:** ไม่มี `cached_dashboard_summary` table แยก — backend มี Redis cache (TTL 1 ชม.) รองรับความเร็วอยู่แล้ว ฝั่ง client เก็บผลลัพธ์ล่าสุดไว้ใน Riverpod state (ไม่ persist ลง disk) แล้ว invalidate/refetch ตอนเปลี่ยนเดือนหรือมี transaction ใหม่

---

## 9. Offline Behavior

**เลือก: Online-only + read cache** (ไม่ใช่ offline-first เต็มรูปแบบ)

- อ่านข้อมูล (transactions/accounts/categories/dashboard) ได้แม้ออฟไลน์ จาก cache ใน drift
- สร้าง/แก้ไขข้อมูลต้องมีเน็ต (แอปนี้ core flow คือยิง Gemini ผ่าน backend อยู่แล้ว ต้องมีเน็ตเป็นทุนเดิม)
- เมื่อ manual create/update/delete **fail** (ตัดเน็ต/error) → เก็บ attempt ไว้ใน `pending_manual_actions` เป็น "รายการค้าง — แตะเพื่อลองใหม่" ไม่ใช่ full sync queue เต็มรูปแบบ แค่กันข้อมูลหาย

### Cache invalidation
- Mutation สำเร็จ (scan สำเร็จ / manual create / update / delete) → invalidate cache เฉพาะเดือนที่เกี่ยวข้อง
- ถ้าแก้ `transaction_date` ข้ามเดือน → invalidate ทั้งเดือนเก่าและเดือนใหม่

---

## 10. Transaction Feed

- **Pagination:** infinite scroll (backend รองรับ `page`/`limit` ต่อเดือนอยู่แล้ว default 20)
- **Junk items:** โชว์ปกติพร้อม badge (ดูหัวข้อ 7.7)

---

## 11. Dashboard

- Scope: monthly (default) — มี month/year selector ที่ drive ทั้ง transaction list และ dashboard summary provider
- Cache: in-memory Riverpod state เท่านั้น ไม่ persist (ดูหัวข้อ 8)

---

## 12. Accounts & Categories

**Scope v1:** CRUD เต็มรูปแบบทั้งคู่ (create/edit/delete ผ่าน UI) ตั้งแต่เริ่ม — ไม่เลื่อนไปทำทีหลัง เพราะ endpoint พร้อมหมดแล้วทั้งฝั่ง backend และ UI ไม่ซับซ้อน อีกทั้งต้องมี account ก่อนถึงจะ manual-create transaction ได้

### 12.1 Account detail — ไม่มี dedicated endpoint
`GET /accounts/:id` **ไม่มีอยู่จริงใน backend** (มีแค่ POST / GET-list / PATCH / DELETE) — และไม่จำเป็นต้องเพิ่ม เพราะ `AccountResponse` ที่ `GET /accounts` (list) คืนมามีฟิลด์ครบทุกตัวอยู่แล้ว (`id`, `name`, `account_type`, `opening_balance`, `matching_keywords`, `bank_icon`, `is_active`) หน้ารายละเอียด account จึง **query จาก `cached_accounts` local (drift) โดยตรง ไม่ยิง network request ใหม่**

### 12.2 Cache sync ของ accounts ต้องเป็น upsert-only

⚠️ **`GET /accounts` filter เฉพาะ `is_active = true`** (ยืนยันจาก `pg_account.go`) — บัญชีที่ปิดแล้ว (soft-delete) จะไม่ถูกส่งกลับมาจาก endpoint นี้เลย

**Rule:** การ sync `cached_accounts` จาก API ต้องเป็น **upsert เท่านั้น (insert/update ตาม response ใหม่ แต่ไม่ลบ record ที่หายไปจาก list)** เพื่อให้บัญชีที่ปิดไปแล้วยังอยู่ใน local cache สำหรับ lookup ชื่อ/โลโก้ของ transaction เก่าที่ยังผูกอยู่กับบัญชีนั้น — ส่วนหน้า "รายการบัญชี" ที่ต้องโชว์แค่บัญชี active ก็ query `WHERE isActive = true` ตอนอ่าน ไม่ใช่ตอน sync

### 12.3 Quick category assignment (BR-9, FR-5.3)

SRS ระบุชัดว่าต้องมีทางกำหนด/เปลี่ยนหมวดหมู่ของ transaction แบบเร็ว **แยกจากหน้าจอแก้ไขเต็มรูปแบบ** เพราะ transaction ที่มาจากสลิปเกือบทั้งหมดไม่มีหมวดหมู่ตั้งแต่แรก (BR-1 จำแนกได้แค่ income/expense/transfer ไม่ได้เดา category)

**พฤติกรรมหลัก (ตามที่ผู้ใช้อธิบาย):** tap ปุ่ม/chip แสดงหมวดหมู่ตรงในแถวของ transaction บน**หน้า feed หลักเลย** → เปิด bottom sheet เลือกหมวดหมู่ → `PATCH /transactions/:id` อัปเดตทันที ไม่เปิดหน้าแก้ไขเต็ม

**หน้าแก้ไขเต็มรูปแบบ (T6)** เป็น escape hatch สำหรับกรณีข้อมูลผิดปกติ (เช่น junk transaction จาก 7.7, หรือแก้ amount/account/note) ไม่ใช่ทางหลักสำหรับกำหนดหมวดหมู่

### 12.4 Category delete guard (FR-2.2)

ก่อนลบ category ต้องแจ้งเตือนจำนวน transaction ที่ผูกอยู่ก่อน — **นับจาก `cached_transactions` local (filter `categoryId == X`) ไม่เพิ่ม endpoint ใหม่ฝั่ง backend** เมื่อลบสำเร็จ transaction ที่เคยผูกจะกลายเป็น `category_id = null` (backend ไม่ลบ transaction ตาม FR-2.2)

---

## 13. Routing

**เลือก: `go_router`** — declarative, deep-link friendly, เข้ากับ Riverpod ง่าย, รองรับ bottom-nav + nested routes (Dashboard/Transactions/Accounts/Categories)

---

## 14. Open Items / ต้องตรวจสอบเพิ่ม

- [x] ~~อ่าน SRS ฉบับเต็ม~~ อ่านแล้ว (v1, 26 ส.ค. 2569) — ส่วนใหญ่ตรงกับ spec นี้
- [ ] **แก้เอกสาร SRS ข้อ BR-8/FR-4.8** ให้ตรงกับ decision จริง (frontend badge+ลบเอง ไม่ใช่ backend skip เงียบๆ) — เอกสารล้าหลังกว่า decision ที่ตกลงกันแล้ว ไม่กระทบโค้ด แค่ sync เอกสาร
- [ ] แก้เอกสาร SRS section 6.1 (Account fields) จาก `icon_key`/`color_hex` เป็น `bank_icon` ให้ตรงกับโค้ดจริง
- [ ] ยืนยัน album name "SCB EASY"/"Dime!" จะไม่เปลี่ยนหลังอัปเดตแอปธนาคารในอนาคต (ทำ config list ให้แก้ง่ายไว้แล้ว)
- [ ] ทดสอบพฤติกรรม `photo_manager` กับ Android scoped storage บนเครื่องจริง (Android 14)
- [ ] ตัดสินใจ UI รายละเอียดหน้า "ignored/junk review" (ถ้าต้องการ) เพิ่มเติมจาก badge ใน feed หลัก
