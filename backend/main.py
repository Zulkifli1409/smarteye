from flask import Flask, request, jsonify
import numpy as np
import cv2
import os
import torch
from datetime import datetime
import tempfile
from collections import Counter

app = Flask(__name__)

# Load YOLOv5 model (nano version for speed)
print("[INFO] Loading YOLOv5 model...")
model = torch.hub.load('ultralytics/yolov5', 'yolov5n', pretrained=True)
model.conf = 0.5  # Confidence threshold
model.iou = 0.3   # IoU threshold
model.img_size = 320  # Set lower resolution for speed

# Object detection function with count feature
def detect_objects(image):
    # Convert the image to RGB format as YOLOv5 expects RGB images
    rgb_image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = model(rgb_image)
    
    detections = []
    label_counts = Counter()  # Counter for each detected object label

    for *box, confidence, class_id in results.xyxy[0].cpu().numpy():
        label = model.names[int(class_id)]
        detection = {
            "label": label,
            "confidence": float(confidence),
            "box": [int(coord) for coord in box],
            "timestamp": datetime.now().isoformat()
        }
        detections.append(detection)
        label_counts[label] += 1  # Increment count for this label

    return detections, label_counts  # Return both detections and counts

# Video processing function
def process_video(video_path):
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    all_detections = []
    label_counts = Counter()  # Counter for object counts in video
    current_frame = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if current_frame % 5 == 0:
            timestamp = current_frame / fps
            detections, frame_label_counts = detect_objects(frame)
            for detection in detections:
                detection["timestamp"] = timestamp
                detection["frame_number"] = current_frame
                all_detections.append(detection)
            label_counts.update(frame_label_counts)  # Update total count
        current_frame += 1
        if current_frame % 30 == 0:
            print(f"Processed {current_frame}/{frame_count} frames")

    cap.release()
    return all_detections, label_counts

@app.route('/api/detect_video', methods=['POST'])
def detect_video():
    if 'video' not in request.files:
        return jsonify({"error": "No video file provided"}), 400

    video_file = request.files['video']
    temp_dir = tempfile.mkdtemp()
    temp_path = os.path.join(temp_dir, 'temp_video.mp4')
    video_file.save(temp_path)

    try:
        detections, label_counts = process_video(temp_path)
        detection_results = {}
        for detection in detections:
            timestamp = detection["timestamp"]
            if timestamp not in detection_results:
                detection_results[timestamp] = []
            detection_results[timestamp].append({
                "label": detection["label"],
                "confidence": detection["confidence"],
                "bounding_box": detection["box"],
                "frame_number": detection["frame_number"]
            })
        return jsonify({
            "total_frames_processed": len(detection_results),
            "detections": detection_results,
            "label_counts": dict(label_counts)  # Total counts per object label
        })
    finally:
        os.remove(temp_path)
        os.rmdir(temp_dir)

@app.route('/api/detect_image', methods=['POST'])
def detect_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files['image']
    image = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)
    detected_objects, label_counts = detect_objects(image)
    return jsonify({
        "detected_objects": detected_objects,
        "label_counts": dict(label_counts)  # Add object counts per label
    })

@app.route('/api/detect_realtime', methods=['POST'])
def detect_realtime():
    if 'image' not in request.files:
        return jsonify({"error": "No image file in request"}), 400

    file = request.files["image"]
    image = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)
    detections, label_counts = detect_objects(image)
    return jsonify({
        "detections": detections,
        "label_counts": dict(label_counts)  # Add object counts per label
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
