BEGIN;

-- CreateTable
CREATE TABLE "handoffs" (
    "handoff_id" UUID NOT NULL,
    "actor_id" UUID NOT NULL,
    "kitchen_ticket_id" UUID NOT NULL,
    "img_urls" VARCHAR(2048)[] NOT NULL DEFAULT ARRAY[]::VARCHAR(2048)[],
    "created_at" TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "handoffs_pkey" PRIMARY KEY ("handoff_id")
);

-- CreateIndex
CREATE INDEX "handoffs_actor_id_idx" ON "handoffs"("actor_id");

-- CreateIndex
CREATE INDEX "handoffs_kitchen_ticket_id_idx" ON "handoffs"("kitchen_ticket_id");

-- AddForeignKey
ALTER TABLE "handoffs" ADD CONSTRAINT "handoffs_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("user_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

-- AddForeignKey
ALTER TABLE "handoffs" ADD CONSTRAINT "handoffs_kitchen_ticket_id_fkey" FOREIGN KEY ("kitchen_ticket_id") REFERENCES "kitchen_tickets"("kitchen_ticket_id") ON DELETE NO ACTION ON UPDATE NO ACTION;

COMMIT;
