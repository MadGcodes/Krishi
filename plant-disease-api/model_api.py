import os
from pathlib import Path
from flask import Flask, request, jsonify
from ultralytics import YOLO
from PIL import Image
import io
from flask_cors import CORS

# --- SAFE CACHE DIRECTORY CONFIGURATION ---
data_path = Path("/data")
if data_path.exists() and os.access(data_path, os.W_OK):
    cache_dir = data_path
else:
    cache_dir = Path("/tmp/ultralytics-cache")
    cache_dir.mkdir(parents=True, exist_ok=True)
    print("⚠️  /data not writable, using /tmp/ultralytics-cache instead")

print(f"Using cache directory: {cache_dir}")

# Set environment variables
os.environ['YOLO_CONFIG_DIR'] = str(cache_dir)
os.environ['HF_HOME'] = str(cache_dir)
os.environ['HUGGINGFACE_HUB_CACHE'] = str(cache_dir / "hub")
# --- END CONFIGURATION ---

app = Flask(__name__)
CORS(app)

model = YOLO('best_model.pt')

@app.route('/')
def health():
    return jsonify({"status": "running", "cache_dir": str(cache_dir)})

@app.route('/predict', methods=['POST'])
def predict():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    img_bytes = file.read()
    img = Image.open(io.BytesIO(img_bytes))

    results = model.predict(img, conf=0.25, verbose=False)
    
    if len(results[0].boxes) == 0:
        return jsonify({
            'disease_name': 'No Detection',
            'confidence': 0.0,
            'is_healthy': False
        })
    
    top_prediction = results[0].boxes[0]
    disease_class = int(top_prediction.cls)
    disease_name = model.names[disease_class]
    confidence = float(top_prediction.conf)
    is_healthy = 'healthy' in disease_name.lower()
    
    return jsonify({
        'disease_name': disease_name,
        'confidence': confidence,
        'is_healthy': is_healthy
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7860)
