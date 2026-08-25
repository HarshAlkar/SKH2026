# VitalReach — Har Solution + Extra Ideas (Example ke saath)

Friend ko samjhana ho to ye file padho. Har cheez: **kya hai → example → simple line**.

**SIH Problem:** 26133 — rural healthcare access & quality (Maharashtra)

**Ek line product:**  
Village patient + ASHA + Doctor ek app pe — travel kam, records toot na, referral complete ho.

---

# PART A — JO ABHI BAN CHUKA HAI (LIVE)

## A1. Patient Login / OTP

**Kya hai:** Phone number + OTP / password se login. Role = Patient.

**Example:**  
Ramesh ka number `98765xxxxx`. OTP aaya → login → User Dashboard.

**Friend ko bolo:** *“Jaise WhatsApp login — phone se account.”*

---

## A2. AI Symptom Checker (ML)

**Kya hai:** Symptoms select / type karo → AI model disease + risk score batata hai.  
**Important:** Yeh **diagnosis nahi**, sirf **screening** (pehle se andaza).

**Example:**  
Ramesh select karta hai: *bukhar, sir dard, thakan*.  
AI: possible viral fever, severity **Moderate**.  
Agar High/Critical → village ASHA + doctor ko alert.

**Friend ko bolo:** *“Google jaisa nahi — trained medical ML model. Doctor ki jagah nahi leta.”*

---

## A3. Voice input (Hindi) — Patient

**Kya hai:** Type karne ki jagah bol ke symptoms bata sakte ho. App text mein convert karti hai.

**Example:**  
Ramesh bolta hai: *“Mujhe teen din se bukhar hai.”*  
App pehle text banaati hai → phir AI check.

**Friend ko bolo:** *“Jo padh-likh kam jaanta hai, woh bhi use kar sake.”*

---

## A4. Doctor Video / Audio Call

**Kya hai:** Internet pe live video ya sirf audio call doctor se (WebRTC).

**Example:**  
Ramesh “Consult Doctor” dabata hai → doctor accept → video call → mute/camera on-off.

**Friend ko bolo:** *“Zoom jaisa, lekin healthcare app ke andar — 50 km hospital jaane ki zarurat nahi.”*

---

## A5. Prescription + PDF

**Kya hai:** Doctor dawai likhta hai → patient app pe dekh sakta hai → PDF bhi.

**Example:**  
Doctor: Paracetamol 500mg, 5 din, din mein 2 baar.  
Ramesh “My Prescriptions” mein dekh leta hai, print/PDF bhi.

**Friend ko bolo:** *“Paper slip kho jaaye to bhi phone pe dawai list safe.”*

---

## A6. Medicine Tracker + Alarm

**Kya hai:** Kab kaunsi dawai leni hai — schedule + phone alarm (OS level).

**Example:**  
Paracetamol 8am aur 8pm.  
Phone alarm bajta hai even agar app band ho.

**Friend ko bolo:** *“Diabetes / BP patient dawai bhoolta nahi — reminder system.”*

---

## A7. Nearby Clinics Map

**Kya hai:** Map pe paas ke clinics / hospitals (OpenStreetMap).

**Example:**  
Ramesh map kholta hai → 8 km pe PHC, 25 km pe Rural Hospital dikhta hai.

**Friend ko bolo:** *“Google Maps jaisa, lekin health facilities focus.”*

---

## A8. Emergency — Notify ASHA

**Kya hai:** Patient emergency mein apne village ki ASHA ko notify kare.

**Example:**  
Raat ko tez bukhar → “Notify ASHA” → Lata (ASHA) ko alert milta hai.

**Friend ko bolo:** *“112 jaisa full ambulance system nahi — pehle village ASHA tak signal.”*

---

## A9. ASHA — Village Patients List

**Kya hai:** ASHA sirf **apne assigned village** ke patients dekhti hai.

**Example:**  
ASHA Lata = Kaman Village.  
Uske list mein Ramesh, Sita (Kaman). Dusre village ke patients nahi.

**Friend ko bolo:** *“Har ASHA apne gaon ki notebook digital.”*

---

## A10. ASHA — Naya Patient Register

**Kya hai:** ASHA naya patient add karti hai (naam, age, gender, phone, village…).

**Example:**  
Naya bachcha / naya migrant aaya → Lata form bharti hai → system mein save → baad mein doctor bhi dekh sakta hai.

**Friend ko bolo:** *“Paper register ki jagah app pe naam chadhana.”*

---

## A11. ASHA — Health Update (Vitals)

**Kya hai:** BP, sugar, temperature, weight, symptoms save.

**Example:**  
Lata Ramesh ke ghar jaati hai: BP 150/95, sugar 210 → Update Health → high risk alert ban sakta hai.

**Friend ko bolo:** *“Ghar pe check-up note digital cloud pe.”*

---

## A12. ASHA — Village Visits

**Kya hai:** Kis patient ke ghar kab visit — schedule, pending, complete.

**Example:**  
Kal 10am Ramesh visit pending.  
Visit ke baad Lata “Completed” mark karti hai.

**Friend ko bolo:** *“Field visit planner + attendance.”*

---

## A13. ASHA — Risk Alerts

**Kya hai:** High / Critical patients ki list + manual alert bhi bana sakti hai.

**Example:**  
AI / vitals se Ramesh High Risk → Lata Risk Alerts screen pe dekhti hai → follow-up.

**Friend ko bolo:** *“Kaun dangerous hai, pehle woh dikhe.”*

---

## A14. ASHA — Emergency Referral

**Kya hai:** Patient ko higher hospital bhejne ka digital record (symptoms, severity, notes).

**Example:**  
Chest pain → Lata referral create: severity Critical, notes “suspect cardiac” → doctor / history mein dikhe.

**Friend ko bolo:** *“Referral slip digital — lost paper kam.”*  
*(Abhi basic hai; Smart Router baad mein.)*

---

## A15. ASHA — Doctor ko Call (patient ke liye)

**Kya hai:** ASHA patient ke behalf pe doctor se consult start kar sakti hai.

**Example:**  
Ramesh phone nahi chala pata → Lata Registered Doctors se video call start → doctor Ramesh ke case pe baat kare.

**Friend ko bolo:** *“ASHA bridge — patient aur doctor ke beech.”*

---

## A16. ASHA Dashboard

**Kya hai:** Numbers: total patients, high risk, pending visits, new alerts.

**Example:**  
Patients 42, High Risk 3, Pending Visits 5 → Lata aaj ka plan banati hai.

**Friend ko bolo:** *“WhatsApp status nahi — real village health summary.”*

---

## A17. Doctor — Patients / Consult / Rx / History

**Kya hai:** Doctor patients dekhe, call kare, prescription likhe, purani consults dekhe.

**Example:**  
Dr. Sharma call accept → Ramesh ke symptoms sunta hai → Paracetamol + rest prescribe → history mein save.

**Friend ko bolo:** *“Clinic jaisa kaam phone pe.”*

---

# PART B — JO BANANA HAI (VitalReach 2.0) — Example ke saath

## B1. Continuity-of-Care Graph (MUST)

**Kya hai:** Patient ki **poori timeline ek screen** pe — visit, vitals, referral, call, dawai, sab linked.  
Levels: ASHA → Sub-centre → PHC → Rural Hospital → District Hospital.

**Example (story):**  
- Din 1: ASHA vitals (BP high)  
- Din 2: PHC doctor video call  
- Din 3: Referral District Hospital  
- Din 4: District doctor Care Graph kholta hai → pehle ke BP, referral reason, meds **already dikhte hain**  

**Bina iske problem:** District doctor poochta hai “pehle kya hua?” — patient bhool jaata hai / papers kho jaate hain.

**Friend ko bolo:** *“Netflix continue watching jaisa — health story continue, reset nahi.”*

---

## B2. AI RED / YELLOW / GREEN + Human Escalation (MUST)

**Kya hai:** AI result ko 3 rang + rule: RED pe AI band, insan doctor zaroori.

| Rang | Matlab | Example |
|------|--------|---------|
| **GREEN** | Simple / ghar pe care | Halka sardi-zukam |
| **YELLOW** | Watch + ASHA follow-up | 3 din bukhar, stable |
| **RED** | Turant doctor / referral | Chest pain, breathlessness, pregnancy bleeding |

**Example:**  
AI RED dikhata hai + message: *“AI cannot handle this → escalate.”*  
Self-care button lock → sirf Call Doctor / Emergency Referral.

**Friend ko bolo:** *“Traffic light — red pe AI ruk jaata hai, doctor aata hai. Safe AI.”*

---

## B3. Follow-up Failure Detection / Care Gaps (MUST)

**Kya hai:** System dekhta hai care **toot** to nahi gayi. Toot gayi to ASHA ko task.

**Examples:**

1. Referral bheja District Hospital → 5 din baad patient gaya hi nahi → **Care Gap**  
2. 7 din ki dawai → 3 din baad alarm ignore → course incomplete → **Care Gap**  
3. Chronic BP patient → 30 din se visit nahi → **Care Gap**  

Phir ASHA phone pe task: *“Ramesh ko call / visit karo.”*

**Friend ko bolo:** *“School attendance jaisa — absent detect, teacher (ASHA) ko bol do.”*

---

## B4. Care Passport — QR + Consent (MUST)

**Kya hai:** Lightweight health card (QR / print). Naye hospital mein scan → **sirf permission ke baad** essential history.

**Example:**  
Ramesh District Hospital pahunchta hai.  
Nurse QR scan → Ramesh phone pe **Allow 1 hour** dabata hai.  
Screen pe: allergy (Penicillin), active meds, last BP, open referral.  
Bina Allow ke data nahi khulta.

**Friend ko bolo:** *“Aadhaar QR jaisa, lekin health — aur consent zaroori (privacy).”*

---

## B5. Smart Referral Router (SHOULD)

**Kya hai:** Blind “kisi bhi hospital bhejo” nahi. System best jagah suggest kare.

**Inputs (example):** symptoms, urgency, distance, specialist available?, hospital capacity, wait time.

**Example:**  
Ramesh ko neuro chahiye.  
- Hospital A: neurologist leave pe, 80% full  
- Hospital B: neurologist available, kal 11am slot, 40 km  
→ App recommend: **Hospital B** + reason dikhe.

**Friend ko bolo:** *“Uber jaisa nearest/best driver — yahan best public hospital suggest.”*

---

## B6. Offline Store → Sync → Conflict (SHOULD)

**Kya hai:** Net nahi to ASHA phone pe data save (encrypt) → net aate hi cloud sync. Conflict ho to smart resolve / review.

**Example:**  
Jungle area — airplane mode.  
Lata 3 patients register + vitals save.  
Shaam ko tower aaya → sync → doctor dashboard pe dikhe.  
Agar do jagah same patient edit → app conflict dikhaye.

**Friend ko bolo:** *“WhatsApp offline queue jaisa — message baad mein bhejta hai.”*

---

## B7. Facility Capacity Dashboard (THIN / LATER)

**Kya hai:** District officer dekhe PHC/hospital kitna busy, medicine stock, pending referrals.

**Example screen:**  
- PHC A — 82% capacity  
- Specialist shortage — 3  
- Medicine stock — 4 days left  
- Pending referrals — 27  
- Lab backlog — 18  
→ Bottleneck badge: “PHC A overloaded”

**Friend ko bolo:** *“Traffic control room — konsa hospital jam hai.”*

---

## B8. Voice-first Rural Mode — ASHA (THIN / LATER)

**Kya hai:** ASHA Marathi/Hindi mein bole → system structured form + triage banaye (typing kam).

**Example:**  
Lata bolti hai: *“Ramesh ko teen din se bukhar hai, BP high.”*  
App: Patient=Ramesh, fever 3 days, BP high → triage YELLOW → visit note save.

**Friend ko bolo:** *“Voice typing for ASHA field work — haath mein BP machine, muh se note.”*

---

# PART C — EXTRA IDEAS (7 ke alawa) — Example ke saath

## E1. Appointment + OPD Queue Token

**Kya hai:** Hospital jaane se pehle online token / time slot — line kam.

**Example:**  
Ramesh PHC ke liye kal 10:30 token #14 book karta hai.  
Hospital pahunch ke 2 ghante khada nahi — screen pe “now serving 12”.

**Kyun chahiye (26133):** Waiting time kam = PS expected outcome.

**Friend ko bolo:** *“Bank token system for OPD.”*

---

## E2. Diagnostic / Lab Order Tracking

**Kya hai:** Doctor blood test / X-ray order kare → status: pending / done / report ready.

**Example:**  
Doctor: CBC + sugar test.  
Status “Pending” → lab complete → “Report ready” → Care Graph pe chipak jaaye → ASHA ko bhi dikhe agar incomplete.

**Kyun:** PS mein “irregular diagnostics / diagnostic coordination”.

**Friend ko bolo:** *“Courier tracking, lekin lab report ke liye.”*

---

## E3. PHC Medicine Stock Visibility

**Kya hai:** PHC pe kaunsi dawai kitni bachi — days of stock.

**Example:**  
Insulin — 4 days left → red warning.  
District officer / ASHA dekh ke indent / patient ko dusri jagah guide.

**Kyun:** Medicine availability visibility (PS outcome).

**Friend ko bolo:** *“Kirana stock register digital for PHC pharmacy.”*

---

## E4. Maternal / Child / NCD Cohort Packs

**Kya hai:** Special follow-up packs — pregnant, newborn, diabetes/BP patients ke liye checklist + reminders.

**Example:**  
Pregnant Sita — ANC visit due in 7 days → ASHA auto task.  
Diabetes Ramesh — sugar check overdue → Care Gap.

**Kyun:** PS explicitly maternal, child, chronic follow-up maangta hai.

**Friend ko bolo:** *“School syllabus jaisa — har group ka alag checklist.”*

---

## E5. Emergency SOS → Nearest Facility + ASHA

**Kya hai:** Ek SOS button → nearest PHC/RH + ASHA + optional doctor alert (location ke saath).

**Example:**  
Accident / severe pain → SOS → map pe nearest PHC + Lata ASHA notify + call option.

**Kyun:** Emergency escalation (PS).

**Friend ko bolo:** *“Power bank pe SOS — yahan health SOS.”*

---

## E6. Quality / Accountability Scorecard

**Kya hai:** Facility score — referral completion %, average wait, follow-up rate, stockouts.

**Example:**  
PHC A score 72 — referral complete 40% (weak).  
Officer training / staffing decision.

**Kyun:** “Quality monitoring / accountability” expected outcome.

**Friend ko bolo:** *“School report card for hospitals.”*

---

## E7. ABHA / ABDM / FHIR Thin Adapter

**Kya hai:** Govt health ID (ABHA) / standard format se data exchange ka **thin** connect (stub pehle, full baad mein).

**Example:**  
Patient ABHA link kare → dusri approved app / hospital standard record share (consent se).

**Kyun:** PS “interoperable health records / approved standards”.

**Friend ko bolo:** *“UPI jaisa standard — health records ke liye government rail.”*  
*(Abhi claim mat karna jab tak build na ho.)*

---

## E8. Low-bandwidth Lite Mode

**Kya hai:** Slow 2G pe bhi chalega — kam images, text pehle, video optional.

**Example:**  
Lite ON → only text consult + vitals sync; video later jab net better.

**Kyun:** Rural connectivity problem.

**Friend ko bolo:** *“YouTube Lite jaisa — health app Lite.”*

---

## E9. ASHA Workload + Incentive Dashboard

**Kya hai:** ASHA ne kitne visits, registers, follow-ups kiye — clear list (incentive / reporting ke liye).

**Example:**  
Is mahine: 40 visits, 12 new patients, 5 care-gap closes → report PDF for PHC.

**Kyun:** Frontline worker support (Maharashtra focus).

**Friend ko bolo:** *“Attendance + performance sheet for ASHA.”*

---

## E10. Village Outbreak / Disease Heatmap

**Kya hai:** Same village mein same disease spike → map pe heat.

**Example:**  
Kaman mein 1 week 8 dengue-like AI flags → heatmap red → PHC alert.

**Kyun:** Public health accountability + early action.

**Friend ko bolo:** *“Weather heatmap, lekin bimari ke liye.”*

---

# PART D — Ek full example (sab jod ke)

**Ramesh, Kaman Village**

1. Lata (ASHA) register + BP/sugar update (**LIVE**)  
2. AI Symptom → **YELLOW/RED** (**LIVE** + RYG **build**)  
3. RED → doctor video / **Smart Referral** to District Hospital  
4. District doctor **Care Graph** kholta hai — pura past  
5. Ramesh **Care Passport QR** se dusri jagah history share (consent)  
6. Appointment miss → **Care Gap** → Lata ko “Call Ramesh” task  
7. Extra: lab pending track + PHC medicine stock check  

**Friend ko last line:**  
*“Yeh sirf video call app nahi — poori care ki chain tootne nahi deti. Isliye Problem 26133 solve hota hai.”*

---

# PART E — 30 second pitch

> Gaon mein doctor door, records aur referral toot jaate hain. VitalReach Patient, ASHA aur Doctor ko jodta hai — AI screening, video consult, referral, medicine reminder. Agey Care Graph aur Care Passport se hospital change pe bhi history saath jaati hai. Hum sarkari system hataate nahi — Continuity of care for the last mile.

---

**Related files:**  
- `docs/PS26133_TEAM_BRIEFING.md` — team + diagrams  
- `docs/VITALREACH_2.0_SIH_2026_REPORT.md` — deep SIH analysis
