# ============================================================================
# PLANT DISEASE DETECTION SYSTEM - YOLOv8 FOR LIGHTNING.AI
# OPTIMIZED FOR 2-HOUR TRAINING WITH 4GB DATASET
# ============================================================================

# ============================================================================
# STEP 1: INSTALL AND IMPORT LIBRARIES
# ============================================================================

!pip install -q ultralytics pillow matplotlib scikit-learn opencv-python pyyaml gdown

from ultralytics import YOLO
import cv2
import numpy as np
import matplotlib.pyplot as plt
import os
import json
import shutil
from PIL import Image
import zipfile
from pathlib import Path
from sklearn.model_selection import train_test_split
import yaml
import gdown

print("="*70)
print("PLANT DISEASE DETECTION - LIGHTNING.AI (2-HOUR OPTIMIZED)")
print("="*70)
print("Setup Complete!")
print("="*70 + "\n")

# ============================================================================
# STEP 2: DOWNLOAD FROM GOOGLE DRIVE
# ============================================================================

print("="*70)
print("📥 DOWNLOADING FROM GOOGLE DRIVE")
print("="*70 + "\n")

print("📋 INSTRUCTIONS:")
print("   1. Upload your dataset ZIP to Google Drive")
print("   2. Right-click → Get link → Set to 'Anyone with the link'")
print("   3. Copy the sharing link")
print("   4. Paste it below\n")

# ============================================================================
# ENTER YOUR GOOGLE DRIVE LINK HERE
# ============================================================================

DRIVE_LINK = 'https://drive.google.com/file/d/1mSWuXMeOjd5neUQhL4l_RXERFRTWlvLL/view?usp=drive_link'

# ============================================================================

def extract_file_id(drive_link):
    """Extract file ID from Google Drive sharing link"""
    if '/file/d/' in drive_link:
        file_id = drive_link.split('/file/d/')[1].split('/')[0]
    elif 'id=' in drive_link:
        file_id = drive_link.split('id=')[1].split('&')[0]
    else:
        file_id = drive_link
    return file_id

# Extract file ID
file_id = extract_file_id(DRIVE_LINK)
print(f"🔑 Google Drive File ID: {file_id}\n")

# Set up paths
LOCAL_DATASET_ZIP = '/teamspace/studios/this_studio/plant_disease_dataset.zip'
LOCAL_DATASET_PATH = '/teamspace/studios/this_studio/dataset'

# Create directories
os.makedirs(os.path.dirname(LOCAL_DATASET_ZIP), exist_ok=True)
os.makedirs(LOCAL_DATASET_PATH, exist_ok=True)

# Download from Google Drive using gdown
print("📥 Downloading dataset from Google Drive...")
print("This may take several minutes depending on file size...\n")

try:
    download_url = f'https://drive.google.com/uc?id={file_id}'
    gdown.download(download_url, LOCAL_DATASET_ZIP, quiet=False, fuzzy=True)

    if os.path.exists(LOCAL_DATASET_ZIP):
        file_size = os.path.getsize(LOCAL_DATASET_ZIP) / (1024*1024)
        print(f"\n✓ Dataset downloaded successfully!")
        print(f"  File size: {file_size:.2f} MB\n")
    else:
        raise FileNotFoundError("Download failed - file not found after download")

except Exception as e:
    print(f"\n❌ Download failed: {e}\n")
    print("⚠️  TROUBLESHOOTING:")
    print("   1. Make sure the file is shared with 'Anyone with the link'")
    print("   2. Check if the file ID is correct")
    print("   3. Try using a different sharing link format")
    print("   4. Or manually upload the file to Lightning Studio\n")

    import time
    print("⏳ Waiting for manual upload...")
    max_wait = 300
    elapsed = 0

    while not os.path.exists(LOCAL_DATASET_ZIP) and elapsed < max_wait:
        print(f"   Checking... ({elapsed}s)", end='\r')
        time.sleep(5)
        elapsed += 5

    if not os.path.exists(LOCAL_DATASET_ZIP):
        raise FileNotFoundError(f"Dataset not found at: {LOCAL_DATASET_ZIP}")

    file_size = os.path.getsize(LOCAL_DATASET_ZIP) / (1024*1024)
    print(f"\n✓ Dataset found!")
    print(f"  File size: {file_size:.2f} MB\n")

# ============================================================================
# STEP 3: EXTRACT DATASET
# ============================================================================

print("="*70)
print("📦 EXTRACTING DATASET")
print("="*70 + "\n")

print(f"Extracting from: {LOCAL_DATASET_ZIP}")
print(f"Extracting to: {LOCAL_DATASET_PATH}\n")

try:
    with zipfile.ZipFile(LOCAL_DATASET_ZIP, 'r') as zip_ref:
        total_files = len(zip_ref.namelist())
        print(f"Found {total_files} files in ZIP archive")

        if total_files == 0:
            raise ValueError("ZIP file is empty!")

        print("Extracting files...\n")

        extracted_count = 0
        for file in zip_ref.namelist():
            zip_ref.extract(file, LOCAL_DATASET_PATH)
            extracted_count += 1

            if extracted_count % 500 == 0 or extracted_count == total_files:
                progress = (extracted_count / total_files) * 100
                print(f"\rProgress: {extracted_count}/{total_files} files ({progress:.1f}%)", end='')

        print()

    print("✓ Dataset extracted successfully!\n")

except zipfile.BadZipFile:
    print("ERROR: File is not a valid ZIP file!")
    raise
except Exception as e:
    print(f"ERROR during extraction: {e}")
    raise

# ============================================================================
# STEP 4: LOCATE DATASET FOLDER
# ============================================================================

print("="*70)
print("🔍 LOCATING DATASET FOLDER")
print("="*70 + "\n")

print(f"Searching in: {LOCAL_DATASET_PATH}")

all_items = os.listdir(LOCAL_DATASET_PATH)
dataset_folders = [f for f in all_items if os.path.isdir(os.path.join(LOCAL_DATASET_PATH, f))]

print(f"Found {len(all_items)} items in dataset directory")
print(f"Found {len(dataset_folders)} folders\n")

print("Directory structure:")
for item in all_items[:10]:
    item_path = os.path.join(LOCAL_DATASET_PATH, item)
    if os.path.isdir(item_path):
        print(f"  📁 {item}/")
    else:
        print(f"  📄 {item}")

if len(all_items) > 10:
    print(f"  ... and {len(all_items) - 10} more items\n")

if len(dataset_folders) == 1:
    dataset_path = os.path.join(LOCAL_DATASET_PATH, dataset_folders[0])
    print(f"\n✓ Using nested folder: {dataset_folders[0]}")
elif len(dataset_folders) > 1:
    dataset_path = LOCAL_DATASET_PATH
    print(f"\n✓ Using root folder with {len(dataset_folders)} class folders")
else:
    print("\n⚠️  WARNING: No folders found!")
    dataset_path = LOCAL_DATASET_PATH

print(f"\nFinal dataset location: {dataset_path}\n")

# ============================================================================
# STEP 5: FLATTEN NESTED STRUCTURE (IF NEEDED)
# ============================================================================

nested_structure = False
plant_folders = [f for f in os.listdir(dataset_path)
                 if os.path.isdir(os.path.join(dataset_path, f))]

if plant_folders:
    first_plant_path = os.path.join(dataset_path, plant_folders[0])
    subfolders = [f for f in os.listdir(first_plant_path)
                  if os.path.isdir(os.path.join(first_plant_path, f))]
    if subfolders:
        nested_structure = True

if nested_structure:
    print("📁 Detected nested folder structure (Plant → Disease)")
    print("Flattening structure...\n")

    flattened_path = '/teamspace/studios/this_studio/dataset_flattened'
    if os.path.exists(flattened_path):
        shutil.rmtree(flattened_path)
    os.makedirs(flattened_path)

    total_images = 0
    for plant_folder in plant_folders:
        plant_path = os.path.join(dataset_path, plant_folder)
        disease_folders = [f for f in os.listdir(plant_path)
                          if os.path.isdir(os.path.join(plant_path, f))]

        for disease_folder in disease_folders:
            disease_path = os.path.join(plant_path, disease_folder)
            new_folder_name = f"{plant_folder}_{disease_folder}"
            new_folder_path = os.path.join(flattened_path, new_folder_name)
            os.makedirs(new_folder_path, exist_ok=True)

            image_files = [f for f in os.listdir(disease_path)
                          if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))]

            for img_file in image_files:
                src = os.path.join(disease_path, img_file)
                dst = os.path.join(new_folder_path, img_file)
                shutil.copy2(src, dst)
                total_images += 1

            print(f"✓ Created class: {new_folder_name} ({len(image_files)} images)")

    dataset_path = flattened_path
    print(f"\n✓ Flattened {total_images} images\n")

# ============================================================================
# STEP 6: CONVERT TO YOLO FORMAT (OPTIMIZED - REDUCED VAL/TEST SIZE)
# ============================================================================

print("="*70)
print("🔄 CONVERTING TO YOLO FORMAT (OPTIMIZED)")
print("="*70 + "\n")

yolo_dataset_path = '/teamspace/studios/this_studio/yolo_dataset'
os.makedirs(yolo_dataset_path, exist_ok=True)

for split in ['train', 'val', 'test']:
    os.makedirs(f'{yolo_dataset_path}/{split}/images', exist_ok=True)
    os.makedirs(f'{yolo_dataset_path}/{split}/labels', exist_ok=True)

classes = sorted([d for d in os.listdir(dataset_path)
                  if os.path.isdir(os.path.join(dataset_path, d))])
num_classes = len(classes)

print(f"Found {num_classes} classes:")
for i, cls in enumerate(classes, 1):
    print(f"  {i}. {cls}")
print()

class_to_idx = {cls: idx for idx, cls in enumerate(classes)}

all_image_paths = []
all_labels = []

for class_name in classes:
    class_path = os.path.join(dataset_path, class_name)
    image_files = [f for f in os.listdir(class_path)
                   if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp'))]

    for img_file in image_files:
        all_image_paths.append(os.path.join(class_path, img_file))
        all_labels.append(class_to_idx[class_name])

# OPTIMIZED SPLIT: 85% train, 10% val, 5% test (more training data)
train_imgs, temp_imgs, train_labels, temp_labels = train_test_split(
    all_image_paths, all_labels, test_size=0.15, random_state=42, stratify=all_labels
)

val_imgs, test_imgs, val_labels, test_labels = train_test_split(
    temp_imgs, temp_labels, test_size=0.33, random_state=42, stratify=temp_labels
)

print(f"Dataset split (OPTIMIZED):")
print(f"  Train: {len(train_imgs)} images ({len(train_imgs)/len(all_image_paths)*100:.1f}%)")
print(f"  Val:   {len(val_imgs)} images ({len(val_imgs)/len(all_image_paths)*100:.1f}%)")
print(f"  Test:  {len(test_imgs)} images ({len(test_imgs)/len(all_image_paths)*100:.1f}%)\n")

def process_images(image_paths, labels, split):
    print(f"Processing {split} set...")
    for idx, (img_path, label) in enumerate(zip(image_paths, labels)):
        try:
            img = cv2.imread(img_path)
            if img is None:
                continue

            img_name = f"{split}_{idx}_{os.path.basename(img_path)}"
            dst_img_path = f'{yolo_dataset_path}/{split}/images/{img_name}'
            shutil.copy(img_path, dst_img_path)

            label_name = os.path.splitext(img_name)[0] + '.txt'
            label_path = f'{yolo_dataset_path}/{split}/labels/{label_name}'

            with open(label_path, 'w') as f:
                f.write(f"{label} 0.5 0.5 1.0 1.0\n")

        except Exception as e:
            continue

        if (idx + 1) % 1000 == 0:
            print(f"  Processed {idx + 1}/{len(image_paths)} images")

process_images(train_imgs, train_labels, 'train')
process_images(val_imgs, val_labels, 'val')
process_images(test_imgs, test_labels, 'test')
print("✓ All images processed!\n")

# ============================================================================
# STEP 7: CREATE YOLO CONFIG
# ============================================================================

data_yaml = {
    'path': yolo_dataset_path,
    'train': 'train/images',
    'val': 'val/images',
    'test': 'test/images',
    'nc': num_classes,
    'names': classes
}

yaml_path = f'{yolo_dataset_path}/data.yaml'
with open(yaml_path, 'w') as f:
    yaml.dump(data_yaml, f, sort_keys=False)

with open('/teamspace/studios/this_studio/class_names.json', 'w') as f:
    json.dump(classes, f, indent=2)

print("✓ YOLO config created\n")

# ============================================================================
# STEP 8: DISEASE RECOMMENDATIONS
# ============================================================================

disease_recommendations = {
    "Healthy": {
        "fertilizers": ["Balanced NPK (10-10-10)", "Organic compost", "Seaweed fertilizer"],
        "treatments": ["Maintain regular watering", "Continue current care", "Monitor regularly"],
        "prevention": ["Ensure 6-8 hours sunlight", "Maintain soil drainage", "Keep area clean"]
    },
    "Early_Blight": {
        "fertilizers": ["Potassium-rich (0-0-60)", "Copper fungicide", "Calcium nitrate"],
        "treatments": ["Remove infected leaves", "Apply fungicide every 7-10 days", "Improve air circulation"],
        "prevention": ["Crop rotation", "Disease-resistant varieties", "Proper spacing"]
    },
    "Late_Blight": {
        "fertilizers": ["Calcium-rich fertilizer", "Mancozeb fungicide"],
        "treatments": ["Apply fungicide immediately", "Remove infected plants", "Reduce humidity"],
        "prevention": ["Plant resistant varieties", "Ensure proper spacing", "Monitor weather"]
    }
}

with open('/teamspace/studios/this_studio/disease_recommendations.json', 'w') as f:
    json.dump(disease_recommendations, f, indent=2)

print(f"✓ Loaded recommendations for {len(disease_recommendations)} conditions\n")

# ============================================================================
# STEP 9: VISUALIZE SAMPLES (SKIP TO SAVE TIME)
# ============================================================================

# Skipping visualization to save time - uncomment if needed
# sample_imgs = train_imgs[:9] if len(train_imgs) >= 9 else train_imgs
# sample_labels = train_labels[:9] if len(train_labels) >= 9 else train_labels
#
# plt.figure(figsize=(15, 8))
# for i, (img_path, label) in enumerate(zip(sample_imgs, sample_labels)):
#     img = cv2.imread(img_path)
#     if img is not None:
#         img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
#
#         plt.subplot(3, 3, i + 1)
#         plt.imshow(img)
#         plt.title(classes[label], fontsize=10, fontweight='bold')
#         plt.axis('off')
#
# plt.tight_layout()
# plt.savefig('/teamspace/studios/this_studio/sample_images.png', dpi=100, bbox_inches='tight')
# plt.show()

print("⏩ Skipped visualization to save time\n")

# ============================================================================
# STEP 10: CHECK GPU
# ============================================================================

import torch

print("="*70)
print("💻 GPU INFORMATION")
print("="*70)
print(f"PyTorch: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU: {torch.cuda.get_device_name(0)}")
    print(f"Memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
print("="*70 + "\n")

# ============================================================================
# STEP 11: TRAIN MODEL (2-HOUR OPTIMIZED)
# ============================================================================

print("="*70)
print("🚀 STARTING TRAINING - 2-HOUR OPTIMIZED")
print("="*70 + "\n")

print("⚙️  OPTIMIZATION SETTINGS:")
print("   • Model: YOLOv8m (Medium - balanced speed/accuracy)")
print("   • Epochs: 30 (reduced from 100)")
print("   • Batch size: 32 (optimized for speed)")
print("   • Image size: 512 (reduced from 640)")
print("   • Early stopping patience: 8")
print("   • Mixed precision training: Enabled")
print("   • Caching: Enabled for faster data loading\n")

# Use YOLOv8m instead of YOLOv8l for faster training
MODEL_SIZE = 'yolov8m.pt'
model = YOLO(MODEL_SIZE)

print(f"Training with {MODEL_SIZE}...\n")

results = model.train(
    data=yaml_path,
    epochs=30,              # Reduced from 100
    imgsz=512,              # Reduced from 640 for faster training
    batch=32,               # Reduced from 64 to fit memory better
    patience=8,             # Reduced from 15 for faster early stopping
    save=True,
    device=0,
    workers=8,
    pretrained=True,
    optimizer='AdamW',
    verbose=True,
    seed=42,
    cos_lr=True,
    amp=True,               # Mixed precision for speed
    cache=True,             # Cache images in RAM for faster loading
    project='/teamspace/studios/this_studio/plant_disease_yolo',
    name='train',
    plots=True,
    save_period=10,
    close_mosaic=5,         # Disable mosaic augmentation in last 5 epochs
    val=True,
    rect=False,             # Disable rectangular training for speed
    single_cls=False
)

print("\n✓ Training complete!\n")

# ============================================================================
# STEP 12: EVALUATE
# ============================================================================

print("="*70)
print("📊 EVALUATION")
print("="*70 + "\n")

metrics = model.val()

print(f"Results:")
print(f"  mAP@50:    {metrics.box.map50:.4f}")
print(f"  mAP@50-95: {metrics.box.map:.4f}")
print(f"  Precision: {metrics.box.mp:.4f}")
print(f"  Recall:    {metrics.box.mr:.4f}")
print("="*70 + "\n")

# ============================================================================
# STEP 13: SAVE OUTPUTS
# ============================================================================

print("💾 Saving outputs...")

output_folder = '/teamspace/studios/this_studio/outputs'
os.makedirs(output_folder, exist_ok=True)

results_path = '/teamspace/studios/this_studio/plant_disease_yolo/train'

files_to_save = {
    f'{results_path}/weights/best.pt': 'best_model.pt',
    f'{results_path}/weights/last.pt': 'last_model.pt',
    '/teamspace/studios/this_studio/class_names.json': 'class_names.json',
    '/teamspace/studios/this_studio/disease_recommendations.json': 'disease_recommendations.json',
    f'{results_path}/results.png': 'training_results.png',
    yaml_path: 'data.yaml'
}

for src, dst_name in files_to_save.items():
    if os.path.exists(src):
        shutil.copy(src, os.path.join(output_folder, dst_name))
        print(f"✓ {dst_name}")

print(f"\n✓ Files saved to: {output_folder}\n")

# ============================================================================
# STEP 14: PREDICTION FUNCTION
# ============================================================================

def predict_disease(image_path, model, class_names):
    results = model.predict(image_path, conf=0.25, verbose=False)

    if len(results[0].boxes) > 0:
        probs = results[0].boxes.conf.cpu().numpy()
        classes_pred = results[0].boxes.cls.cpu().numpy()

        top_idx = np.argmax(probs)
        disease_name = class_names[int(classes_pred[top_idx])]
        confidence = float(probs[top_idx] * 100)

        img = cv2.imread(image_path)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        plt.figure(figsize=(10, 6))
        plt.imshow(img)
        plt.title(f"{disease_name} ({confidence:.1f}%)", fontsize=14, fontweight='bold')
        plt.axis('off')
        plt.tight_layout()
        plt.show()

        print(f"\n🌿 Detected: {disease_name}")
        print(f"📊 Confidence: {confidence:.2f}%\n")

        return disease_name, confidence

    return None, 0

# Test
if len(test_imgs) > 0:
    print("Testing model...")
    predict_disease(test_imgs[0], model, classes)

print("\n" + "="*70)
print("🎉 COMPLETE!")
print("="*70)
print("\n📁 Download your model from:")
print(f"   {output_folder}")
print("\n⏱️  Total training time optimized for ~2 hours")
print("="*70 + "\n")
