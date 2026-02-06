# Use a trained classifier to predict new samples

Prediction workflow repository:
<https://github.com/meghnasw/Predict-mock-samples-forensic-BFID.git>

General approach:
1) Train your classifier (output directory contains the estimator artifact; commonly `sample_estimator.qza` or similar)

2) Copy your trained classifier artifact into the prediction repo (e.g., into `Reference_files/` or the folder expected by that repo)

3) Update paths in the prediction scripts to point to your classifier artifact, if needed

4) Run the prediction workflow as described in that repository
