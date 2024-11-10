from flask import Flask, request, jsonify
import numpy as np
import cv2
import os
import tempfile
from datetime import datetime

app = Flask(__name__)

# Path to YOLO directory
yolo_directory = r"D:\Politeknik\Semester 5\PRAK PENGOLAHAN CITRA DIGITAL (PAK ABDI)\smarteye\backend\darknet"

# Load COCO labels
labels_path = os.path.join(yolo_directory, "data", "coco.names")
with open(labels_path, "r") as f:
    LABELS = f.read().strip().split("\n")

# Initialize colors for each label class
np.random.seed(42)
COLORS = np.random.randint(0, 255, size=(len(LABELS), 3), dtype="uint8")

# Load YOLO model weights and config
weights_path = os.path.join(yolo_directory, "cfg", "yolov3-tiny.weights")
config_path = os.path.join(yolo_directory, "cfg", "yolov3-tiny.cfg")

print("[INFO] Loading YOLO model...")
net = cv2.dnn.readNetFromDarknet(config_path, weights_path)

# Object detection function
def detect_objects(image):
    (H, W) = image.shape[:2]
    layer_names = net.getLayerNames()
    output_layers = net.getUnconnectedOutLayers()
    ln = [layer_names[i - 1] for i in output_layers.flatten()]

    blob = cv2.dnn.blobFromImage(image, 1 / 255.0, (416, 416), swapRB=True, crop=False)
    net.setInput(blob)
    layer_outputs = net.forward(ln)

    boxes, confidences, classIDs = [], [], []
    for output in layer_outputs:
        for detection in output:
            scores = detection[5:]
            classID = np.argmax(scores)
            confidence = scores[classID]
            if confidence > 0.5:
                box = detection[0:4] * np.array([W, H, W, H])
                (centerX, centerY, width, height) = box.astype("int")
                x = int(centerX - (width / 2))
                y = int(centerY - (height / 2))

                boxes.append([x, y, int(width), int(height)])
                confidences.append(float(confidence))
                classIDs.append(classID)

    idxs = cv2.dnn.NMSBoxes(boxes, confidences, 0.5, 0.3)
    detections = []
    if len(idxs) > 0:
        for i in idxs.flatten():
            detection = {
                "label": LABELS[classIDs[i]],
                "confidence": confidences[i],
                "box": boxes[i],
                "timestamp": datetime.now().isoformat()
            }
            detections.append(detection)
    return detections

# Video processing function
def process_video(video_path):
    cap = cv2.VideoCapture(video_path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    all_detections = []
    current_frame = 0
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        if current_frame % 5 == 0:
            timestamp = current_frame / fps
            detections = detect_objects(frame)
            for detection in detections:
                detection["timestamp"] = timestamp
                detection["frame_number"] = current_frame
                all_detections.append(detection)
        current_frame += 1
        if current_frame % 30 == 0:
            print(f"Processed {current_frame}/{frame_count} frames")

    cap.release()
    return all_detections

@app.route('/api/detect_video', methods=['POST'])
def detect_video():
    if 'video' not in request.files:
        return jsonify({"error": "No video file provided"}), 400

    video_file = request.files['video']
    temp_dir = tempfile.mkdtemp()
    temp_path = os.path.join(temp_dir, 'temp_video.mp4')
    video_file.save(temp_path)

    try:
        detections = process_video(temp_path)
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
        return jsonify({"total_frames_processed": len(detection_results), "detections": detection_results})
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
    detected_objects = detect_objects(image)
    return jsonify(detected_objects)

@app.route('/api/detect_realtime', methods=['POST'])
def detect_realtime():
    if 'image' not in request.files:
        return jsonify({"error": "No image file in request"}), 400

    file = request.files["image"]
    image = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)
    detections = detect_objects(image)
    return jsonify({"detections": detections})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
