# ============================================================================
# PLANT DISEASE DETECTION - GOOGLE COLAB INFERENCE
# Run your trained YOLOv8 model on new images in Colab
# ============================================================================

# ============================================================================
# STEP 1: INSTALL REQUIRED LIBRARIES
# ============================================================================

print("="*70)
print("📦 INSTALLING LIBRARIES")
print("="*70 + "\n")

!pip install -q ultralytics opencv-python-headless pillow matplotlib

print("✓ Installation complete!\n")

# ============================================================================
# STEP 2: IMPORT LIBRARIES
# ============================================================================

from ultralytics import YOLO
import cv2
import numpy as np
import matplotlib.pyplot as plt
import json
import os
from PIL import Image
from google.colab import files
import io

print("="*70)
print("🌿 PLANT DISEASE DETECTION - GOOGLE COLAB")
print("="*70 + "\n")

# ============================================================================
# STEP 3: UPLOAD YOUR MODEL FILE
# ============================================================================

print("="*70)
print("📤 UPLOAD YOUR MODEL")
print("="*70 + "\n")

print("📋 INSTRUCTIONS:")
print("   1. Click the 'Choose Files' button that will appear")
print("   2. Select your 'best_model.pt' file")
print("   3. Wait for upload to complete\n")

print("⏳ Waiting for file upload...")
uploaded = files.upload()

# Get the model filename
model_filename = list(uploaded.keys())[0]
print(f"\n✓ Uploaded: {model_filename}")
print(f"   File size: {len(uploaded[model_filename]) / (1024*1024):.2f} MB\n")

# ============================================================================
# STEP 4: LOAD THE MODEL
# ============================================================================

print("="*70)
print("🔧 LOADING MODEL")
print("="*70 + "\n")

# Load the model
model = YOLO(model_filename)
print("✓ Model loaded successfully!\n")

# Get class names from the model
class_names = model.names
if isinstance(class_names, dict):
    class_names = list(class_names.values())

print(f"📋 Model trained on {len(class_names)} classes:")
for i, name in enumerate(class_names[:10], 1):
    print(f"   {i}. {name}")
if len(class_names) > 10:
    print(f"   ... and {len(class_names)-10} more")
print()

# ============================================================================
# STEP 5: OPTIONAL - UPLOAD RECOMMENDATIONS FILE
# ============================================================================

print("="*70)
print("📤 UPLOAD RECOMMENDATIONS (OPTIONAL)")
print("="*70 + "\n")

print("Do you have a 'disease_recommendations.json' file?")
print("If yes, upload it now. If no, just skip by clicking 'Cancel'\n")

try:
    recommendations_upload = files.upload()
    if recommendations_upload:
        rec_filename = list(recommendations_upload.keys())[0]
        with open(rec_filename, 'r') as f:
            disease_recommendations = json.load(f)
        print(f"✓ Loaded recommendations for {len(disease_recommendations)} diseases\n")
    else:
        disease_recommendations = {}
        print("⏩ Skipped - No recommendations file\n")
except:
    disease_recommendations = {}
    print("⏩ Skipped - No recommendations file\n")

# ============================================================================
# STEP 6: PREDICTION FUNCTION
# ============================================================================

def predict_plant_disease(image_source, conf_threshold=0.25, show_plot=True):
    """
    Detect plant disease from an image

    Args:
        image_source: Can be:
                     - Path to image file (str)
                     - PIL Image object
                     - Numpy array (BGR format)
        conf_threshold: Confidence threshold (0.0 to 1.0)
        show_plot: Whether to display the result

    Returns:
        disease_name: Detected disease class
        confidence: Confidence score (0-100)
        recommendations: Treatment recommendations (if available)
    """

    # Run prediction
    results = model.predict(
        image_source,
        conf=conf_threshold,
        verbose=False,
        imgsz=512
    )

    # Check if any detection was made
    if len(results[0].boxes) == 0:
        print(f"⚠️  No disease detected with confidence > {conf_threshold*100}%")
        print("   Try lowering the confidence threshold\n")
        return None, 0, None

    # Get prediction results
    boxes = results[0].boxes
    confidences = boxes.conf.cpu().numpy()
    classes_pred = boxes.cls.cpu().numpy()

    # Get the prediction with highest confidence
    top_idx = np.argmax(confidences)
    disease_class_idx = int(classes_pred[top_idx])
    disease_name = class_names[disease_class_idx]
    confidence = float(confidences[top_idx] * 100)

    # Get recommendations
    recommendations = None
    for key in disease_recommendations.keys():
        if key.lower() in disease_name.lower() or disease_name.lower() in key.lower():
            recommendations = disease_recommendations[key]
            break

    # Display results
    print("\n" + "="*70)
    print("🔍 DETECTION RESULTS")
    print("="*70)
    print(f"🌿 Disease Detected: {disease_name}")
    print(f"📊 Confidence: {confidence:.2f}%")
    print("="*70)

    # Show recommendations if available
    if recommendations:
        print("\n💊 TREATMENT RECOMMENDATIONS:")
        print("-" * 70)

        if 'treatments' in recommendations:
            print("\n🔧 Treatments:")
            for i, treatment in enumerate(recommendations['treatments'], 1):
                print(f"   {i}. {treatment}")

        if 'fertilizers' in recommendations:
            print("\n🌱 Recommended Fertilizers:")
            for i, fertilizer in enumerate(recommendations['fertilizers'], 1):
                print(f"   {i}. {fertilizer}")

        if 'prevention' in recommendations:
            print("\n🛡️  Prevention Tips:")
            for i, tip in enumerate(recommendations['prevention'], 1):
                print(f"   {i}. {tip}")

        print("\n" + "="*70)

    # Visualize if requested
    if show_plot:
        # Load image based on input type
        if isinstance(image_source, str):
            img = cv2.imread(image_source)
            img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        elif isinstance(image_source, np.ndarray):
            img = cv2.cvtColor(image_source, cv2.COLOR_BGR2RGB)
        else:  # PIL Image
            img = np.array(image_source)

        # Create figure
        plt.figure(figsize=(12, 8))
        plt.imshow(img)

        # Add title with prediction
        title = f"🌿 {disease_name}\n📊 Confidence: {confidence:.1f}%"
        plt.title(title, fontsize=16, fontweight='bold', pad=20)
        plt.axis('off')
        plt.tight_layout()
        plt.show()

    print()
    return disease_name, confidence, recommendations

# ============================================================================
# STEP 7: UPLOAD AND PREDICT FUNCTION
# ============================================================================

def upload_and_predict(conf_threshold=0.25):
    """
    Upload image(s) from your computer and run prediction
    """
    print("="*70)
    print("📤 UPLOAD IMAGE(S) FOR PREDICTION")
    print("="*70 + "\n")

    print("📋 Select one or more plant images from your computer\n")

    uploaded_images = files.upload()

    if not uploaded_images:
        print("⚠️  No images uploaded!")
        return

    print(f"\n✓ Uploaded {len(uploaded_images)} image(s)\n")

    results = []

    for i, (filename, content) in enumerate(uploaded_images.items(), 1):
        print(f"\n{'='*70}")
        print(f"📸 Image {i}/{len(uploaded_images)}: {filename}")
        print('='*70)

        # Save image temporarily
        with open(filename, 'wb') as f:
            f.write(content)

        # Run prediction
        disease, conf, recs = predict_plant_disease(
            filename,
            conf_threshold=conf_threshold,
            show_plot=True
        )

        results.append({
            'image': filename,
            'disease': disease,
            'confidence': conf
        })

        # Clean up
        os.remove(filename)

    return results

# ============================================================================
# STEP 8: PREDICT FROM URL
# ============================================================================

def predict_from_url(image_url, conf_threshold=0.25):
    """
    Predict disease from an image URL

    Args:
        image_url: Direct URL to image
        conf_threshold: Confidence threshold
    """
    import urllib.request

    print(f"📥 Downloading image from URL...")

    try:
        # Download image
        urllib.request.urlretrieve(image_url, 'temp_image.jpg')

        # Run prediction
        disease, conf, recs = predict_plant_disease(
            'temp_image.jpg',
            conf_threshold=conf_threshold,
            show_plot=True
        )

        # Clean up
        os.remove('temp_image.jpg')

        return disease, conf, recs

    except Exception as e:
        print(f"❌ Error: {e}")
        return None, 0, None

# ============================================================================
# STEP 9: BATCH PREDICTION (FOR MULTIPLE IMAGES)
# ============================================================================

def predict_batch(conf_threshold=0.25):
    """
    Upload and process multiple images at once
    """
    results = upload_and_predict(conf_threshold=conf_threshold)

    if results:
        print("\n" + "="*70)
        print("📊 BATCH PREDICTION SUMMARY")
        print("="*70)
        for result in results:
            status = "✓" if result['disease'] else "✗"
            disease_str = result['disease'] if result['disease'] else "No detection"
            conf_str = f"({result['confidence']:.1f}%)" if result['disease'] else ""
            print(f"{status} {result['image']}: {disease_str} {conf_str}")
        print("="*70 + "\n")

    return results

# ============================================================================
# STEP 10: USAGE GUIDE
# ============================================================================

print("\n" + "="*70)
print("✅ SETUP COMPLETE! YOUR MODEL IS READY!")
print("="*70 + "\n")

print("🎯 HOW TO USE:\n")

print("METHOD 1: Upload Images from Your Computer")
print("-" * 70)
print("results = upload_and_predict(conf_threshold=0.25)")
print()

print("METHOD 2: Predict from Image URL")
print("-" * 70)
print("predict_from_url('https://example.com/plant-image.jpg')")
print()

print("METHOD 3: Batch Processing (Multiple Images)")
print("-" * 70)
print("results = predict_batch(conf_threshold=0.25)")
print()

print("METHOD 4: Load from Google Drive")
print("-" * 70)
print("from google.colab import drive")
print("drive.mount('/content/drive')")
print("predict_plant_disease('/content/drive/MyDrive/plant_image.jpg')")
print()

print("="*70)
print("💡 TIPS:")
print("="*70)
print("• Lower conf_threshold (e.g., 0.15) for more detections")
print("• Higher conf_threshold (e.g., 0.5) for stricter predictions")
print("• Default threshold of 0.25 works well for most cases")
print("="*70 + "\n")

print("🚀 Ready to detect plant diseases!")
print("   Run: upload_and_predict()")
print("="*70 + "\n")
