BEGIN;

CREATE UNIQUE INDEX "handoffs_kitchen_ticket_id_key" ON "handoffs"("kitchen_ticket_id");

DROP INDEX "handoffs_kitchen_ticket_id_idx";

COMMIT;
