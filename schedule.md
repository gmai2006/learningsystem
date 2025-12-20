### **Phase 1: Initiation & Discovery (Weeks 1-4)**
*Focus: Environment Setup and Workflow Mapping*

* **Week 1:** Kickoff meeting with University stakeholders (IT, Pharmacy Director, Finance).
* **Week 2:** Infrastructure provisioning (AWS/Azure) and installation of **Wildfly** and **PostgreSQL** containers.
* **Week 3:** Workflow discovery workshops to map current pharmacy queues to the new **React** interface.
* **Week 4:** **Deliverable:** Detailed Project Plan & Architecture Sign-off.

### **Phase 2: Integration & Migration (Weeks 5-10)**
*Focus: Connecting Systems and Moving Data*

* **Week 5:** VPN setup and firewall configuration for secure traffic.
* **Week 6:** **Data Migration Run #1:** Extract patient/inventory data from the legacy system into the staging environment.
* **Week 7:** Build **HL7 interfaces** for **PointNClick** (Patient Demographics/Admit-Discharge-Transfer).
* **Week 8:** Configure **Okta SSO** and Role-Based Access Controls (RBAC).
* **Week 9:** Develop and test **CougarCash** and **TouchNet** payment API integrations.
* **Week 10:** **Deliverable:** Integration User Acceptance Testing (UAT) complete.

### **Phase 3: Validation & Training (Weeks 11-14)**
*Focus: Clinical Safety and Staff Readiness*

* **Week 11:** **Data Migration Run #2:** Delta update of data. Full clinical data verification by pharmacy staff.
* **Week 12:** Configure DSCSA logic and perform extensive testing of clinical alerts (e.g., morphine equivalents, pregnancy).
* **Week 13:** **On-Site Training:** "Train the Trainer" sessions for pharmacists and technicians.
* **Week 14:** **Deliverable:** System "Code Freeze" (No new changes allowed before Go-Live).

### **Phase 4: Go-Live & Support (Weeks 15-16)**
*Focus: Launch and Stabilization*

* **Week 15:** **GO-LIVE WEEKEND.**
    * Final Data Migration (Run #3).
    * Cutover of live HL7 feeds.
    * System activation.
* **Week 16:** Post-Go-Live "Hyper-Care" support. Daily check-ins, performance tuning, and immediate issue resolution.