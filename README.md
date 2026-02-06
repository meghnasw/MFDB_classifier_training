# MFDB Classifier Training

This repository provides instructions to train custom QIIME2 classifiers using the MFDB dataset.

The MFDB database is available here:
https://mfdb.irm.uzh.ch/#/

The full OTU/feature table and metadata used in the associated publication are deposited on Zenodo (see the Zenodo link below). A Random Forest classifier was trained on these Zenodo-hosted inputs. This repository explains how to:

- download and use the Zenodo-hosted OTU/feature table and metadata,

- filter the table (e.g., by body site or region) to define your own training subset, and

- train your own classifier in QIIME2.

Optionally, you can use your trained classifier with the prediction workflow repository:
https://github.com/meghnasw/Predict-mock-samples-forensic-BFID.git

---

## Data + artifacts (Zenodo)

The following files are hosted on Zenodo:

- OTU table for the Database (97%) : otu_Table_allsamples.qza
- Metadata file for the Database: metadata_final_withZIFMsamples.txt
- trained classifier artifact: sample_classifier.qza

Zenodo record:
- DOI / link: 10.5281/zenodo.18494561

---

## What users should set / edit

Before running anything, users should decide or update the following:

### A) Input files (paths)
- Path to the feature/OTU table (`.qza`), e.g.
  - `otu_Table_allsamples.qza` (used for the pre-trained classifier) OR a user-generated table
- Path to the metadata file (e.g. `.tsv` or `.txt`)

### B) Metadata column to predict
- `--m-metadata-column Body_Site_Ed`
  - Change `Body_Site_Ed` to the column you want to predict (must exist in your metadata)

### C) Sample filtering choice (body site / subset)
If training a custom classifier, users should set:
- The metadata column used for filtering (e.g. `Body_Site_Ed`)
- The WHERE clause, e.g.

    '[Body_Site_Ed] IN ("Skin_hand", "Skin_penile")'

### D) Output directory name
- `--output-dir <NAME>`
  - Choose an informative name that encodes your subset/region/seed, e.g. `rf_skin_v4v5_seed123`

### E) Training parameters (optional to change)
- `--p-n-estimators 500` (number of trees)
- `--p-n-jobs 8` (parallel jobs; match your machine)
- `--p-random-state 123` (seed for reproducibility)
- Whether to keep:
  - `--p-optimize-feature-selection`
  - `--p-parameter-tuning`

## Train your own classifier
### Step 1 — Filter the OTU/feature table (example: filter to skin)

Example filter (edit metadata column names and values as appropriate):

    qiime feature-table filter-samples \
      --i-table otu_Table_allsamples.qza \
      --m-metadata-file metadata_final_withZIFMsamples.txt \
      --p-where '[Body_Site_Ed] IN ("skin_hand", "skin_penile")' \
      --o-filtered-table filtered-table.qza

Notes:
- The filtering expression uses QIIME2 metadata query syntax.
- If your metadata column is named differently, replace Body_Site_Ed accordingly.
- You can filter to any body sites you want by changing the values inside IN ("...", "...").

### Step 2 — Train a classifier on the filtered table

This command trains a supervised machine-learning classifier using QIIME2’s `sample-classifier` plugin.
Specifically, it trains a **Random Forest** model to predict the sample label in the metadata column
`Body_Site_Ed` from the input feature table (`otu_Table_allsamples.qza`). It enables **feature selection**
and **parameter tuning**, uses **500 trees**, parallelizes across **8 jobs**, fixes randomness with
`--p-random-state 123`, and writes all outputs (trained estimator, performance, predictions, feature importance, etc.)
to the output directory.


    qiime sample-classifier classify-samples \
      --i-table filtered-table.qza \
      --m-metadata-file sample-metadata.tsv \
      --m-metadata-column Body_Site_Ed \
      --p-optimize-feature-selection \
      --p-estimator RandomForestClassifier \
      --p-parameter-tuning \
      --p-n-jobs 8 \
      --p-n-estimators 500 \
      --p-random-state 123 \
      --output-dir my_custom_rf

---

## Create QIIME2 visualizations for the training outputs (.qzv)

After training (either the published run output directory or your own, e.g. my_custom_rf),
create these visualizations:

Feature importance:

    qiime metadata tabulate \
      --m-input-file my_custom_rf/feature_importance.qza \
      --o-visualization my_custom_rf/feature_importance.qzv

Predictions:

    qiime metadata tabulate \
      --m-input-file my_custom_rf/predictions.qza \
      --o-visualization my_custom_rf/predictions.qzv

Probabilities:

    qiime metadata tabulate \
      --m-input-file my_custom_rf/probabilities.qza \
      --o-visualization my_custom_rf/probabilities.qzv

Test targets + predictions:

    qiime metadata tabulate \
      --m-input-file my_custom_rf/test_targets.qza \
      --m-input-file my_custom_rf/predictions.qza \
      --o-visualization my_custom_rf/test_targets_predictions.qzv

Tip: if you trained to a different output directory, replace my_custom_rf/ in the commands above.

To view .qzv files:
- https://view.qiime2.org
- or locally with: qiime tools view <file.qzv>

---

## Use a trained classifier to predict new samples

Prediction workflow repo:
https://github.com/meghnasw/Predict-mock-samples-forensic-BFID.git

General approach:
1) Train your classifier (output directory contains the estimator artifact; commonly sample_estimator.qza)
2) Copy your trained classifier artifact into the prediction repo (e.g., into Ref_files/)
3) Update any paths in the prediction scripts to point to your classifier artifact, if needed
4) Run the prediction workflow as described in that repository

---

## QIIME2 documentation

For full details and additional options, see QIIME2 docs:
- sample-classifier tutorial: https://docs.qiime2.org/

## Citation

If you use this workflow or dataset as a reference, please cite the original classifier publication and the QIIME2 team:

Swayambhu, M., Gysi, M., Haas, C., Schuh, L., Walser, L., Javanmard, F., ... & Arora, N. (2025). Standardizing a microbiome pipeline for body fluid identification from complex crime scene stains. Applied and Environmental Microbiology, 91(5), e01871-24.

Bolyen, E., Rideout, J. R., Dillon, M. R., Bokulich, N. A., Abnet, C. C., Al-Ghalith, G. A., ... & Caporaso, J. G. (2019). Reproducible, interactive, scalable and extensible microbiome data science using QIIME 2. Nature biotechnology, 37(8), 852-857.

## Author:
Zurich Institute of Forensic Medicine, Forensic Genetics Dept.
Contact: Dr. Natasha Arora [natasha.arora@uzh.ch] Dr. Meghna Swayambhu [meghna.swayambhu@uzh.ch]
