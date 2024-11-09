from flask import Flask, request, jsonify
import numpy as np
import cv2
import os
import tempfile

# Path to the YOLO directory
yolo_directory = r"D:\Politeknik\Semester 5\PRAK PENGOLAHAN CITRA DIGITAL (PAK ABDI)\smarteye\backend\darknet"

# Load labels from COCO dataset
labelsPath = os.path.join(yolo_directory, "data", "coco.names")
LABELS = open(labelsPath).read().strip().split("\n")

# Load YOLO model
weightsPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.weights")
configPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.cfg")
net = cv2.dnn.readNetFromDarknet(configPath, weightsPath)

def detect_objects_in_frame(frame):
    (H, W) = frame.shape[:2]
    ln = net.getLayerNames()
    out_layers = net.getUnconnectedOutLayers()
    ln = [ln[i - 1] for i in out_layers.flatten()]

    blob = cv2.dnn.blobFromImage(frame, 1 / 255.0, (416, 416), swapRB=True, crop=False)
    net.setInput(blob)
    layerOutputs = net.forward(ln)

    boxes, confidences, classIDs = [], [], []

    for output in layerOutputs:
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

    results = []
    if len(idxs) > 0:
        for i in idxs.flatten():
            results.append({
                "label": LABELS[classIDs[i]],
                "confidence": confidences[i],
                "bounding_box": boxes[i]
            })

    return results

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

        # Process every 5th frame to improve performance
        if current_frame % 5 == 0:
            timestamp = current_frame / fps
            detections = detect_objects_in_frame(frame)
            
            for detection in detections:
                detection["timestamp"] = timestamp
                detection["frame_number"] = current_frame
                all_detections.append(detection)

        current_frame += 1
        
        # Optional: Add progress logging
        if current_frame % 30 == 0:
            print(f"Processed {current_frame}/{frame_count} frames")

    cap.release()
    return all_detections

app = Flask(__name__)

@app.route('/api/detect_video', methods=['POST'])
def detect_video():
    if 'video' not in request.files:
        return jsonify({"error": "No video file provided"}), 400

    video_file = request.files['video']
    
    # Save video to temporary file
    temp_dir = tempfile.mkdtemp()
    temp_path = os.path.join(temp_dir, 'temp_video.mp4')
    video_file.save(temp_path)

    try:
        # Process video and get detections
        detections = process_video(temp_path)
        
        # Group detections by timestamp
        detection_results = {}
        for detection in detections:
            timestamp = detection["timestamp"]
            if timestamp not in detection_results:
                detection_results[timestamp] = []
            detection_results[timestamp].append({
                "label": detection["label"],
                "confidence": detection["confidence"],
                "bounding_box": detection["bounding_box"],
                "frame_number": detection["frame_number"]
            })

        return jsonify({
            "total_frames_processed": len(detection_results),
            "detections": detection_results
        })

    finally:
        # Cleanup temporary files
        if os.path.exists(temp_path):
            os.remove(temp_path)
        os.rmdir(temp_dir)

@app.route('/api/detect', methods=['POST'])
def detect_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files['image']
    image = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)

    # Check if the image is vertical
    if image.shape[0] < image.shape[1]:  # If height < width
        image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)  # Rotate 90 degrees clockwise

    detected_objects = detect_objects_in_frame(image)

    return jsonify(detected_objects)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
