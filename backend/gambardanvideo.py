# Import library yang dibutuhkan
import numpy as np
import time
import cv2
import os

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
    start = time.time()
    layerOutputs = net.forward(ln)
    end = time.time()

    print("[INFO] YOLO membutuhkan waktu {:.6f} detik".format(end - start))

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
            color = [int(c) for c in COLORS[classIDs[i]]]
            cv2.rectangle(image, (x, y), (x + w, y + h), color, 4)
            text = "{}: {:.4f}".format(LABELS[classIDs[i]], confidences[i])
            cv2.putText(image, text, (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 1.0, color, 2)

    # Kembalikan gambar, boxes, confidences, dan classIDs
    return image, boxes, confidences, classIDs

# Pilihan antara file gambar atau video
mode = input("Pilih mode ('image', 'video'): ").strip().lower()

if mode == 'image':
    image_path = r"" #url gambar
    print(f"[INFO] Menggunakan mode file gambar dengan path: {image_path}...")
    image = cv2.imread(image_path)

    if image is None:
        print(f"[ERROR] Gambar tidak ditemukan di path yang diberikan: {image_path}")
    else:
        output_image, boxes, confidences, classIDs = detect_objects(image)
        cv2.namedWindow("Image", cv2.WINDOW_NORMAL)
        cv2.resizeWindow("Image", 720, 720)  # Mengatur ukuran jendela menjadi persegi 720x720
        cv2.imshow("Image", output_image)

        # Print hasil deteksi untuk boxes, confidences, dan classIDs
        print("\n[INFO] Hasil deteksi objek:")
        for i in range(len(boxes)):
            print(f"Box: {boxes[i]}, Confidence: {confidences[i]:.4f}, ClassID: {classIDs[i]}")

        cv2.waitKey(0)
        cv2.destroyAllWindows()

elif mode == 'video':
    video_path = r"" #parh video
    print(f"[INFO] Menggunakan mode file video dengan path: {video_path}...")
    cap = cv2.VideoCapture(video_path)

    cv2.namedWindow("Video", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("Video", 720, 720)  # Mengatur ukuran jendela menjadi persegi 720x720

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        output_frame, boxes, confidences, classIDs = detect_objects(frame)
        cv2.imshow("Video", output_frame)

        # Print hasil deteksi untuk boxes, confidences, dan classIDs
        for i in range(len(boxes)):
            print(f"Box: {boxes[i]}, Confidence: {confidences[i]:.4f}, ClassID: {classIDs[i]}")

        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()

else:
    print("[ERROR] Mode tidak dikenal.")
