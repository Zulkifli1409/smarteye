import numpy as np
import cv2
import os
from datetime import datetime

# Path ke direktori YOLO
yolo_directory = r"D:\Politeknik\Semester 5\PRAK PENGOLAHAN CITRA DIGITAL (PAK ABDI)\smarteye\backend\darknet"

# Muat label kelas dari COCO dataset
labelsPath = os.path.join(yolo_directory, "data", "coco.names")
LABELS = open(labelsPath).read().strip().split("\n")

# Inisialisasi warna untuk setiap label kelas
np.random.seed(42)
COLORS = np.random.randint(0, 255, size=(len(LABELS), 3), dtype="uint8")

# Path ke bobot dan konfigurasi YOLO
weightsPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.weights")
configPath = os.path.join(yolo_directory, "cfg", "yolov3-tiny.cfg")

# Muat YOLO model
print("[INFO] Memuat YOLO dari disk...")
net = cv2.dnn.readNetFromDarknet(configPath, weightsPath)

# Fungsi untuk menjalankan deteksi objek pada gambar
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

    if len(idxs) > 0:
        for i in idxs.flatten():
            (x, y) = (boxes[i][0], boxes[i][1])
            (w, h) = (boxes[i][2], boxes[i][3])
            class_id = classIDs[i]

            # Cek apakah class_id dalam rentang warna
            if class_id < len(COLORS):
                color = [int(c) for c in COLORS[class_id]]
            else:
                color = [255, 255, 255]  # Warna default jika index tidak valid

            cv2.rectangle(image, (x, y), (x + w, y + h), color, 2)
            text = "{}: {:.4f}".format(LABELS[class_id], confidences[i])
            cv2.putText(image, text, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

    return image

# Mode live camera
print("[INFO] Menggunakan mode live camera...")
cap = cv2.VideoCapture(2)  # index cam

while True:
    ret, frame = cap.read()
    if not ret:
        print("[ERROR] Gagal mendapatkan frame dari kamera")
        break

    output_frame = detect_objects(frame)
    cv2.imshow("Live Camera", output_frame)

    # Print hasil deteksi dengan timestamp ke command line
    current_time = datetime.now().strftime("%H:%M:%S")
    print(f"{current_time} - Deteksi objek ditampilkan.")

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
