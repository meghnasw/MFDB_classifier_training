# MFDB Classifier Training

This documentation explains how to train custom QIIME2 classifiers using the MFDB dataset (OTU/feature table + metadata on Zenodo) by filtering to a subset (e.g., body site/region) and re-training a classifier in QIIME2.

**MFDB database:**  
https://mfdb.irm.uzh.ch/#/

**Zenodo record (OTU table + metadata + trained classifier):**  
10.5281/zenodo.18494561

**Prediction workflow repository (optional):**  
https://github.com/meghnasw/Predict-mock-samples-forensic-BFID.git

---

## Documentation

- **Data + artifacts (Zenodo):** [data](data.md)  
- **Train your own classifier:** [training](training.md)  
- **Visualize training outputs (.qzv):** [visualize](visualize.md)  
- **Use a trained classifier to predict new samples:** [prediction](prediction.md)  
- **Citation + contact:** [citation](citation.md)  

---

## Quick start

1) Download the OTU table + metadata from Zenodo (see [data](data.md)).  
2) Filter the OTU table to your subset (see [training](training.md)).  
3) Train a classifier with `qiime sample-classifier classify-samples` (see [training](training.md)).  
4) Create `.qzv` visualizations (see [visualize](visualize.md)).  
5) (Optional) Use your trained classifier in the prediction workflow (see [prediction](prediction.md)).  
