# Orders and kitchen E2E

Start the API against your seeded test environment with S3 storage configured.
Install the server dependencies, Bash, curl and Node.js. The script uses the
seeded `test_order_staff`, `test_chef`, `test_kitchen`, and `test_owner` users.

From `server/`:

```bash
bash src/scripts/e2e/orders-kitchen.sh
```

On Windows, if WSL Bash cannot find Node but Windows Node and Git Bash are
installed, the script automatically continues in Git Bash.

To check seeded logins and menu availability without creating orders, run
`bash src/scripts/e2e/orders-kitchen.sh --check`.

Optional environment variables:

- `E2E_API_URL`: API base URL, default `http://127.0.0.1:3000/api`.
- `REJECTION_ROUNDS`: failed QC attempts before passing, default `1`.
- `REJECTIONS_PER_ROUND`: rejected portions in each attempt, default `2`.
- `AWS_REGION`: test bucket region, default `ap-southeast-1`.
- `E2E_PASSWORD`: seeded account password, default from the test seed.
- `E2E_MENU_ITEM_CODE`: seeded menu item code, default `GC-KIMCHI-FRIED-RICE`.

The script logs out its sessions, but the uniquely identified test orders and
uploaded delivery image remain in the connected environment. It never deletes
the seeded users or their existing assets. Run it only against a test environment.
