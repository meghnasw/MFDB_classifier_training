# MFDB Classifier Training (QIIME2)

This repository documents how the MFDB Random Forest classifier was trained and provides scripts to filter a feature/OTU table and train custom classifiers.

Large inputs and trained artifacts are hosted on Zenodo (see docs/data-on-zenodo.md).

## Published training command

    qiime sample-classifier classify-samples \
      --i-table otu_Table_allsamples.qza \
      --m-metadata-file metadata_final_withZIFMsamples.txt \
      --m-metadata-column Body_Site_Ed \
      --p-optimize-feature-selection \
      --p-estimator RandomForestClassifier \
      --p-parameter-tuning \
      --p-n-jobs 8 \
      --p-n-estimators 500 \
      --p-random-state 123 \
      --output-dir rf_opt_classifier_tuning_seed123_n500

## Train your own classifier (example: skin)

1) Filter samples by body site:

    bash scripts/02_filter_table_by_bodysite.sh feature-table.qza sample-metadata.tsv \
      '[Body_Site_Ed] IN ("left palm","right palm")' filtered-table.qza

2) Train classifier:

    bash scripts/04_train_classifier_rf.sh filtered-table.qza sample-metadata.tsv Body_Site_Ed my_custom_rf

3) Create visualizations (.qzv):

    bash scripts/06_summarize_training_outputs.sh my_custom_rf

Open .qzv files using QIIME2 View: https://view.qiime2.org

## Use your classifier for prediction

Prediction workflow repository:
https://github.com/meghnasw/Predict-mock-samples-forensic-BFID.git

See docs/how-to-use-with-prediction-repo.md.

