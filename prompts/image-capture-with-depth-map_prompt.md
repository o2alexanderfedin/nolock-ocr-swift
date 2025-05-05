You're a senior iOS developer. Implement a Swift-based camera module that:

1. **Forces the use of the rear camera with LiDAR** (if available), or dual-camera depth if not.
2. **Captures both a high-resolution photo and a depth map** using `AVCapturePhotoOutput` with `isDepthDataDeliveryEnabled = true`.
3. **Creates a complete AVCaptureSession pipeline**:
   - Uses `AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)` if available, otherwise `.builtInDualCamera`.
   - Adds proper session preset and device input.
   - Adds `AVCapturePhotoOutput` and configures it correctly for depth and high-res image.
   - Starts the session cleanly and handles stopping as well.

4. **Implements `AVCapturePhotoCaptureDelegate` to receive the image and depth**:
   - Returns the RGB image as `CGImage`
   - Extracts the `AVDepthData` and stores its `depthDataMap`
   - Returns both in a function callback or struct

5. **Implements a method to process the image + depth:**
   - Constructs a 3D point cloud from the depth map using camera intrinsics
   - Computes a best-fit plane using PCA (principal component analysis)
   - Projects all pixels onto that plane (de-wrinkling the receipt)
   - Warps the RGB image accordingly (either with Accelerate or Metal)
   - Returns the resulting de-wrinkled `CGImage`

6. The output should be a single function call like:
   ```swift
   captureReceiptWithDepth { flattenedImage in
       // Use for OCR
   }
   ```

7. You may use any of these libraries:
   - AVFoundation
   - CoreImage
   - Accelerate
   - simd
   - Metal (optional)
   - Swift concurrency or delegation for callback

💡 Bonus if:
- You can visualize the depth map in grayscale in a preview
- You can export the final image to disk as PNG
- You support fallback behavior if the device doesn’t support depth capture

The goal is to scan receipts with curved surfaces using iPhone's camera and LiDAR, and flatten them for better OCR. The solution should work on iPhone 12 Pro or later, and should fail gracefully on unsupported devices.
