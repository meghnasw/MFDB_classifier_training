#!/usr/bin/env bash
set -euo pipefail

# Usage example:
# bash scripts/02_filter_table_by_bodysite.sh feature-table.qza sample-metadata.tsv \
#   '[Body_Site_Ed] IN ("left palm","right palm")' filtered-table.qza

IN_TABLE="${1:?Provide input table .qza}"
META="${2:?Provide metadata file}"
WHERE_CLAUSE="${3:?Provide a QIIME2 --p-where clause}"
OUT_TABLE="${4:-filtered-table.qza}"

qiime feature-table filter-samples \
  --i-table "$IN_TABLE" \
  --m-metadata-file "$META" \
  --p-where "$WHERE_CLAUSE" \
  --o-filtered-table "$OUT_TABLE"
