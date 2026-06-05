# Hybrid Clade DB Run Commands

Use these commands from project root:

## 1) Build progressive Dinosauria detail DB (target ~40 rows)

```bash
./scripts/build_clade_hybrid_data.py \
  --stage progressive \
  --max-entries 40 \
  --root-id dinosauria \
  --fetch-opentree \
  --expand-from-opentree \
  --db data/clades_detail.ready.sqlite \
  --report docs/dinosauria_hybrid_stage1_report.md
```

## 2) Verify row count

```bash
sqlite3 data/clades_detail.ready.sqlite "select count(*) from clades_detail;"
```

## 3) After restarting/closing Android Studio (to release lock), swap DB in

```bash
mv data/clades_detail.ready.sqlite data/clades_detail.sqlite
```

## 4) Optional quick check of currently open lock holders

```bash
lsof data/clades_detail.sqlite
```

## 5) Optional inspect first rows

```bash
sqlite3 data/clades_detail.sqlite "select id,parent_id,ott_id from clades_detail order by id limit 30;"
```
