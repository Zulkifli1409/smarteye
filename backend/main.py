from flask import Flask, request, jsonify
import numpy as np
import cv2
import os

# Path to the YOLO directory
yolo_directory = r"D:\Politeknik\Semester 5\PRAK PENGOLAHAN CITRA DIGITAL (PAK ABDI)\smarteye\backend\darknet"

# Load labels from COCO dataset
labelsPath = os.path.join(yolo_directory, "data", "coco.names")
LABELS = open(labelsPath).read().strip().split("\n")

# Load YOLO model
weightsPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.weights")
configPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.cfg")
net = cv2.dnn.readNetFromDarknet(configPath, weightsPath)

def detect_objects(image):
    (H, W) = image.shape[:2]
    ln = net.getLayerNames()
    out_layers = net.getUnconnectedOutLayers()
    ln = [ln[i - 1] for i in out_layers.flatten()]

    blob = cv2.dnn.blobFromImage(image, 1 / 255.0, (416, 416), swapRB=True, crop=False)
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

app = Flask(__name__)

@app.route('/api/detect', methods=['POST'])
def detect():
    if 'image' not in request.files:
        return jsonify({"error": "No image file provided"}), 400

    file = request.files['image']
    image = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(image, cv2.IMREAD_COLOR)

    # Check if the image is vertical
    if image.shape[0] < image.shape[1]:  # If height < width
        image = cv2.rotate(image, cv2.ROTATE_90_CLOCKWISE)  # Rotate 90 degrees clockwise

    detected_objects = detect_objects(image)

    return jsonify(detected_objects)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
