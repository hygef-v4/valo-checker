# Requirements Clarification Questions

Please answer the following questions to help define the scope, goals, and architectural constraints for this AI-DLC cycle.

---

## Question 1: Development Objective
Mục tiêu chính mà bạn muốn thực hiện cho dự án ValoCheck trong chu kỳ AI-DLC này là gì? (What is the primary objective you want to achieve for ValoCheck in this AI-DLC cycle?)

A) Phát triển tính năng mới (New Feature) — Thêm tính năng mới (ví dụ: Video preview mượt hơn, 3D model skin viewer, Home screen widget, Live MMR tracking, v.v.)

B) Cải tiến / Tái cấu trúc (Enhancement & Refactoring) — Nâng cấp kiến trúc, tối ưu state management (Riverpod/Bloc), cải thiện UI/UX và animation

C) Sửa lỗi & Nâng cao độ ổn định (Bug Fix & Maintenance) — Tăng tính ổn định phiên đăng nhập Riot SSO, xử lý retry API, tối ưu cache

D) Hoàn thiện bộ tài liệu AI-DLC chuẩn hóa cho toàn bộ dự án hiện tại (Baseline AI-DLC Setup) — Thiết lập đầy đủ quy chuẩn và tài liệu mẫu cho dự án

E) Other (please describe after [Answer]: tag below)

[Answer]: D

---

## Question 2: Scope & Architecture Impact
Phạm vi và mức độ tác động dự kiến của công việc này? (What is the intended scope of this work?)

A) Thay đổi phạm vi cục bộ / Single Component (Chỉ tác động đến 1-2 file hoặc một màn hình/widget cụ thể)

B) Thay đổi đa thành phần / Multi-Component (Tác động nhiều widget, models, hoặc services trong app)

C) Nâng cấp toàn diện hệ thống / System-wide (Kiến trúc, testing, build pipeline)

D) Other (please describe after [Answer]: tag below)

[Answer]: A

---

## Question 3: Extension — Resiliency Baseline
Should the resiliency baseline be applied to this project?

**What this extension is:** Enabling it applies a set of **directional, design-time best practices** for building resilient systems, derived from the **AWS Well-Architected Framework (Reliability Pillar)** and resilience-review guidance. It steers requirements, design, and code toward fault tolerance, high availability, observability, and recoverability — covering 15 practice areas across business goals, change management, observability, high availability, disaster recovery, and continuous improvement.

**What this extension is NOT:** Enabling it does **not** make your workload production-ready, nor does it certify or guarantee any availability, RTO, or RPO target. It is a **starting point** that scaffolds good resiliency decisions early — it is not a substitute for a formal **AWS Well-Architected Review** of the built system.

A) Yes — apply the resiliency baseline as directional best practices and design-time guidance (recommended for business-critical workloads)

B) No — skip the resiliency baseline (suitable for PoCs, prototypes, and experimental projects where rapid iteration matters more than reliability)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 4: Extension — Security Baseline
Should security extension rules be enforced for this project?

A) Yes — enforce all SECURITY rules as blocking constraints (recommended for production-grade applications)

B) No — skip all SECURITY rules (suitable for PoCs, prototypes, and experimental projects)

X) Other (please describe after [Answer]: tag below)

[Answer]: B

---

## Question 5: Extension — Property-Based Testing
Should property-based testing (PBT) rules be enforced for this project?

A) Yes — enforce all PBT rules as blocking constraints (recommended for projects with business logic, data transformations, serialization, or stateful components)

B) Partial — enforce PBT rules only for pure functions and serialization round-trips (suitable for projects with limited algorithmic complexity)

C) No — skip all PBT rules (suitable for simple CRUD applications, UI-only projects, or thin integration layers with no significant business logic)

X) Other (please describe after [Answer]: tag below)

[Answer]: C
