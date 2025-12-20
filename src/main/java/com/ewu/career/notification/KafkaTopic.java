/**
 * %% Copyright (C) 2025 DataScience 9 LLC %% Licensed under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance with the License. You may obtain a
 * copy of the License at
 *
 * <p>http://www.apache.org/licenses/LICENSE-2.0
 *
 * <p>Unless required by applicable law or agreed to in writing, software distributed under the
 * License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing permissions and
 * limitations under the License. #L%
 */
package com.ewu.career.notification;

public enum KafkaTopic {
    Roles,
    Users,
    UserSso,
    UserPermissions,
    Patients,
    PatientAliases,
    Pharmacists,
    Wholesalers,
    InventoryItems,
    InventoryBatches,
    DscsaSerials,
    ReorderRules,
    PurchaseOrders,
    Prescriptions,
    PrescriptionItems,
    PrescriptionTransfers,
    PrescriptionAudit,
    Workflows,
    WorkflowSteps,
    Queues,
    Tasks,
    TaskRouting,
    BarcodeLabels,
    PosTransactions,
    PosSignatures,
    Payments,
    Claims,
    DirFees,
    AwpReclaims,
    ProfitAuditWarnings,
    AlertRules,
    AlertLogs,
    Integrations,
    IntegrationEvents,
    Reports,
    AuditLogs,
    ConsentRecords,
    EncryptionKeysMeta,
    PdmpQueries,
    AccessLogs,
    EfaxRecipients,
    EfaxJobs,
    EfaxAttachments,
    EfaxStatusLogs,
    EfaxIncoming
}
