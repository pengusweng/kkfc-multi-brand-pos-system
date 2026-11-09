-- DropForeignKey
ALTER TABLE "modifiers" DROP CONSTRAINT "modifiers_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "goods_receipts" DROP CONSTRAINT "goods_receipts_created_by_id_fkey";

-- DropForeignKey
ALTER TABLE "goods_receipts" DROP CONSTRAINT "goods_receipts_accepted_by_id_fkey";

-- DropForeignKey
ALTER TABLE "goods_receipt_items" DROP CONSTRAINT "goods_receipt_items_goods_receipt_id_fkey";

-- DropForeignKey
ALTER TABLE "goods_receipt_items" DROP CONSTRAINT "goods_receipt_items_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_counts" DROP CONSTRAINT "stock_counts_created_by_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_counts" DROP CONSTRAINT "stock_counts_reviewed_by_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_count_items" DROP CONSTRAINT "stock_count_items_stock_count_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_count_items" DROP CONSTRAINT "stock_count_items_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_count_items" DROP CONSTRAINT "stock_count_items_counted_by_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_adjustments" DROP CONSTRAINT "stock_adjustments_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_adjustments" DROP CONSTRAINT "stock_adjustments_stock_count_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_adjustments" DROP CONSTRAINT "stock_adjustments_requested_by_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_adjustments" DROP CONSTRAINT "stock_adjustments_reviewed_by_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_reverses_movement_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_goods_receipt_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_stock_adjustment_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_order_item_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_production_batch_id_fkey";

-- DropForeignKey
ALTER TABLE "stock_movements" DROP CONSTRAINT "stock_movements_created_by_id_fkey";

-- DropForeignKey
ALTER TABLE "recipes" DROP CONSTRAINT "recipes_output_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "recipe_components" DROP CONSTRAINT "recipe_components_recipe_id_fkey";

-- DropForeignKey
ALTER TABLE "recipe_components" DROP CONSTRAINT "recipe_components_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batches" DROP CONSTRAINT "production_batches_recipe_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batches" DROP CONSTRAINT "production_batches_created_by_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batches" DROP CONSTRAINT "production_batches_preparer_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batches" DROP CONSTRAINT "production_batches_checker_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batches" DROP CONSTRAINT "production_batches_approved_by_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batch_inputs" DROP CONSTRAINT "production_batch_inputs_production_batch_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batch_inputs" DROP CONSTRAINT "production_batch_inputs_inventory_item_id_fkey";

-- DropForeignKey
ALTER TABLE "production_batch_inputs" DROP CONSTRAINT "production_batch_inputs_issued_by_id_fkey";

-- AlterTable
ALTER TABLE "modifiers" DROP COLUMN "inventory_item_id",
DROP COLUMN "quantity";

-- AlterTable
ALTER TABLE "recipes" DROP COLUMN "expected_output_quantity",
DROP COLUMN "output_inventory_item_id",
DROP COLUMN "type";

-- DropTable
DROP TABLE "inventory_items";

-- DropTable
DROP TABLE "goods_receipts";

-- DropTable
DROP TABLE "goods_receipt_items";

-- DropTable
DROP TABLE "stock_counts";

-- DropTable
DROP TABLE "stock_count_items";

-- DropTable
DROP TABLE "stock_adjustments";

-- DropTable
DROP TABLE "stock_movements";

-- DropTable
DROP TABLE "recipe_components";

-- DropTable
DROP TABLE "production_batches";

-- DropTable
DROP TABLE "production_batch_inputs";

-- DropEnum
DROP TYPE "recipe_types";

-- DropEnum
DROP TYPE "inventory_types";

-- DropEnum
DROP TYPE "receipt_statuses";

-- DropEnum
DROP TYPE "count_statuses";

-- DropEnum
DROP TYPE "adjustment_statuses";

-- DropEnum
DROP TYPE "stock_movement_types";

-- DropEnum
DROP TYPE "production_statuses";

