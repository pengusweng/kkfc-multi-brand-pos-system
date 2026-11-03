BEGIN;

ALTER TABLE "handoffs" RENAME COLUMN "img_urls" TO "img_keys";

COMMIT;
