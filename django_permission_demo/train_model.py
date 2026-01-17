#!/usr/bin/env python
"""
Train a machine learning model to classify APKs as malware or benign.
Reads from apk_permissions_dataset.csv and saves the trained model as model.pkl
"""

import os
import csv
import pickle
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score, precision_score, recall_score, f1_score

def train_model():
    # Path to CSV dataset
    csv_path = os.path.join(os.getcwd(), 'media', 'apk_permissions_dataset.csv')
    
    if not os.path.exists(csv_path):
        print(f"Error: Dataset not found at {csv_path}")
        return False
    
    print(f"Loading dataset from {csv_path}...")
    
    X = []  # Feature vectors
    y = []  # Labels (0=benign, 1=malware)
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                cv_vector = row.get('cv_vector', '')
                apk_type = row.get('apk_type', 'benign')
                
                if cv_vector:
                    # Convert pipe-separated string to list of integers
                    vector = [int(x) for x in cv_vector.split('|') if x.isdigit()]
                    X.append(vector)
                    
                    # Label: 1 for malware, 0 for benign
                    label = 1 if apk_type.lower() == 'malware' else 0
                    y.append(label)
        
        if len(X) == 0:
            print("No valid training data found in CSV.")
            return False
        
        print(f"Loaded {len(X)} samples from CSV")
        print(f"Malware samples: {sum(y)}, Benign samples: {len(y) - sum(y)}")
        
        # Convert to numpy arrays
        X = np.array(X)
        y = np.array(y)
        
        # Split data into train and test sets
        X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
        
        print(f"Training samples: {len(X_train)}, Test samples: {len(X_test)}")
        
        # Train Random Forest Classifier
        print("Training Random Forest Classifier...")
        clf = RandomForestClassifier(n_estimators=100, random_state=42, max_depth=10)
        clf.fit(X_train, y_train)
        
        # Evaluate on test set
        print("Evaluating model on test set...")
        y_pred = clf.predict(X_test)
        
        # Print classification report
        print("\n" + "="*50)
        print("CLASSIFICATION REPORT")
        print("="*50)
        print(classification_report(y_test, y_pred, target_names=['Benign', 'Malware']))
        
        # Additional metrics
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred)
        recall = recall_score(y_test, y_pred)
        f1 = f1_score(y_test, y_pred)
        
        print(f"\nOverall Metrics:")
        print(f"Accuracy:  {accuracy:.4f}")
        print(f"Precision: {precision:.4f}")
        print(f"Recall:    {recall:.4f}")
        print(f"F1-Score:  {f1:.4f}")
        print("="*50)
        
        # Save model
        model_path = os.path.join(os.getcwd(), 'model.pkl')
        with open(model_path, 'wb') as f:
            pickle.dump(clf, f)
        
        print(f"✓ Model saved to {model_path}")
        print(f"✓ Feature count: {clf.n_features_in_}")
        print(f"✓ Classes: {clf.classes_}")
        
        return True
    
    except Exception as e:
        print(f"Error training model: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    success = train_model()
    exit(0 if success else 1)
