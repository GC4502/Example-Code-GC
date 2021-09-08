# Title: Predicting COVID-19 Hospitalization Using Machine Learning for Early Treatment Intervention
## Authors: *José J. Casado Garrido, Gabriel Crúz López, Zhiyi Dong*

The problem and solution for this problem are described in our accepted abstract [BHI_Abstract_Submission.pdf] (https://github.com/GC4502/Example-Code-GC/blob/main/COVID-19%20Risk%20Prediction/BHI_Abstract_Submission.pdf)

## Languages and tools used
Python v3.x
Pandas v1.0.5
Numpy v1.18.5
sklearn v0.23.1
tensorflow v2.4.3
jupyter notebooks for collaboration

## I/O for each file
This part of the document should be considered as a guide on the functionalities of the code for COVID-19 risk prediction.

### splitDataset.ipnyb
This code is meant to serve as a first examination of the original dataset.
 
- Input: unprocessed dataset
- Includes the removal of features with more than 50% values
- Stratified split of dataset into training and testing set in 80:20 ratio
- Output: unprocessed training + testing set

### Preprocessing.ipnyb
This code mainly processess the dataset for further analysis.

- Input: unprocessed training + testing sets
- Imputation of missing values with KNN for continous variables
- Imputation of missing values with simple imputer ('most frequent value') for the categorical values
- Standardization of features by z-score
- Output: processed training and testing set

### FeatureInspection+PCA.ipnyb
This code is dedicated in visualizing different set of feature distributions, correlations and principal component analysis.

- Input: Processed training+ testing sets
- Includes inspection of relevant features by F-ANOVA scores
- Principal component analysis
- Output: Training + testing Principal component sets

### NeuralNetwork_OGFeatures.ipnyb
This code is dedicated for classification with all original features.

- Input: Processed training+ testing sets
- Implements two layer neural network
- Gridsearch of hyperparameter with cross-validation
- Upsampling of minority class for imbalanced dataset
- Testing of model with testing set
- Output: Performance evaluation with multiple metrics (confusion matrix, f-1 score, sensitivity, specificity, accuracy)

### NeuralNetwork_PCA.ipnyb
This code is identical to "NeuralNetwork_OGFeatures.ipnyb" but the code is adapted to the reduced number of features 
given by the principal component analysis.

- Input: Processed training+ testing PC sets
- Output: Performance evaluation with multiple metrics (confusion matrix, f-1 score, sensitivity, specificity, accuracy)

