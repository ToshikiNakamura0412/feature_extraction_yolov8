#!/usr/bin/env python3

import os

import cv2
import numpy as np
from ultralytics import YOLO


def main():
    home_dir = os.environ["HOME"]
    img_path = f"{home_dir}/ultralytics/ultralytics/assets/bus.jpg"

    # YOLO
    model = YOLO(home_dir + "/yolov8s.pt")
    results = model.predict(source=img_path, save=True)

    # mask
    img = cv2.imread(img_path)
    mask = np.full(img.shape[:2], 255, dtype=np.uint8)
    for box in results[0].boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        mask[y1:y2, x1:x2] = 0

    # extraction
    detector = cv2.AKAZE_create()
    keypoints, descriptors = detector.detectAndCompute(img, mask)

    # Viz
    img = cv2.drawKeypoints(img, keypoints, None, color=(0, 255, 0), flags=0)
    for box in results[0].boxes:
        x1, y1, x2, y2 = map(int, box.xyxy[0])
        img = cv2.drawContours(
            img,
            [np.array([[x1, y1], [x2, y1], [x2, y2], [x1, y2]])],
            -1,
            (255, 0, 0),
            2,
        )
    img = cv2.resize(img, (img.shape[1] // 2, img.shape[0] // 2))
    cv2.imshow("img", img)
    while True:
        if cv2.getWindowProperty("img", cv2.WND_PROP_VISIBLE) < 1:
            break
        key = cv2.waitKey(1)
        if key == ord("q") or key == 27:
            break
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
    os.system("if [ -d 'runs' ]; then rm -rf runs; fi")
