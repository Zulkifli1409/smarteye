from flask import Flask, request, jsonify
import numpy as np
import cv2
import os

app = Flask(__name__)

# Path ke direktori YOLO
yolo_directory = r"D:\Politeknik\Semester 5\PRAK PENGOLAHAN CITRA DIGITAL (PAK ABDI)\smarteye\backend\darknet"
labelsPath = os.path.join(yolo_directory, "data", "coco.names")
LABELS = open(labelsPath).read().strip().split("\n")
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
            if confidence > 0.5:  # Ambang batas kepercayaan
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
            (x, y) = (boxes[i][0], boxes[i][1])
            (w, h) = (boxes[i][2], boxes[i][3])
            class_id = classIDs[i]
            label = LABELS[class_id]
            confidence = confidences[i]
            results.append({"box": [x, y, w, h], "label": label, "confidence": confidence})

    return results

@app.route('/detect', methods=['POST'])
def detect():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Baca file gambar dari request
    file_bytes = np.frombuffer(file.read(), np.uint8)
    image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)

    if image is None:
        return jsonify({'error': 'Failed to decode image'}), 400

    # Deteksi objek pada gambar
    results = detect_objects(image)

    return jsonify(results)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)  # Pastikan server dapat diakses
